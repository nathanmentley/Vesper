/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://gnu.org>.
 */

using GLib;
using Gee;
using Soup;
using Json;

using Vesper.Core.Models;

namespace Vesper.Plugins.Jellyfin {

    public sealed class JellyfinClient : GLib.Object {
        private string base_url;
        private string username;
        private string password;

        private Soup.Session session;

        private string? access_token = null;
        private string? user_id = null;

        private const string CLIENT_NAME = "Vesper";
        private const string DEVICE_NAME = "Vesper Desktop";
        private const string DEVICE_ID = "vesper-desktop";
        private const string CLIENT_VERSION = "1.0.0";

        public JellyfinClient (
            string base_url,
            string username,
            string password
        ) {
            this.base_url = base_url.has_suffix ("/")
                ? base_url.substring (0, base_url.length - 1)
                : base_url;

            this.username = username;
            this.password = password;
            this.session = new Soup.Session ();
        }

        public async bool authenticate () {
            var builder = new Json.Builder ();

            builder.begin_object ();
            builder.set_member_name ("Username");
            builder.add_string_value (username);
            builder.set_member_name ("Pw");
            builder.add_string_value (password);
            builder.end_object ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());

            string? body = generator.to_data (null);

            if (body == null) {
                return false;
            }

            var message = new Soup.Message (
                "POST",
                base_url + "/Users/AuthenticateByName"
            );

            message.get_request_headers ().append (
                "X-Emby-Authorization",
                build_authorization_header ()
            );

            message.set_request_body_from_bytes (
                "application/json",
                new Bytes ((uint8[]) body.data)
            );

            try {
                Bytes response = yield session.send_and_read_async (
                    message,
                    GLib.Priority.DEFAULT,
                    null
                );

                if (message.status_code != 200) {
                    warning (
                        "Jellyfin authentication failed: HTTP %u",
                        message.status_code
                    );
                    return false;
                }

                Json.Node? root = parse_json (response);

                if (root == null || root.get_node_type () != Json.NodeType.OBJECT) {
                    warning ("Jellyfin returned invalid authentication JSON");
                    return false;
                }

                Json.Object obj = root.get_object ();

                access_token = string_member (obj, "AccessToken");

                Json.Object? user = object_member (obj, "User");

                if (user != null) {
                    user_id = string_member (user, "Id");
                }

                if (
                    access_token == null ||
                    access_token == "" ||
                    user_id == null ||
                    user_id == ""
                ) {
                    warning ("Jellyfin authentication response is incomplete");
                    access_token = null;
                    user_id = null;
                    return false;
                }

                return true;
            } catch (GLib.Error e) {
                warning (
                    "Jellyfin authentication request failed: %s",
                    e.message
                );
                return false;
            }
        }

        public async Json.Node? get_json (
            string path,
            string query = ""
        ) {
            if (access_token == null || user_id == null) {
                if (!(yield authenticate ())) {
                    return null;
                }
            }

            string url = base_url + path;

            if (query != "") {
                url += "?" + query;
            }

            var message = new Soup.Message ("GET", url);

            message.get_request_headers ().append (
                "X-Emby-Authorization",
                build_authorization_header ()
            );

            message.get_request_headers ().append (
                "X-Emby-Token",
                access_token
            );

            try {
                Bytes response = yield session.send_and_read_async (
                    message,
                    GLib.Priority.DEFAULT,
                    null
                );

                if (message.status_code != 200) {
                    warning (
                        "Jellyfin GET %s failed: HTTP %u",
                        path,
                        message.status_code
                    );
                    return null;
                }

                return parse_json (response);
            } catch (GLib.Error e) {
                warning (
                    "Jellyfin request failed for %s: %s",
                    path,
                    e.message
                );
                return null;
            }
        }

        public async Bytes? get_bytes (string path) {
            if (access_token == null || user_id == null) {
                if (!(yield authenticate ())) {
                    return null;
                }
            }

            var message = new Soup.Message (
                "GET",
                base_url + path
            );

            message.get_request_headers ().append (
                "X-Emby-Authorization",
                build_authorization_header ()
            );

            message.get_request_headers ().append (
                "X-Emby-Token",
                access_token
            );

            try {
                Bytes response = yield session.send_and_read_async (
                    message,
                    GLib.Priority.DEFAULT,
                    null
                );

                if (message.status_code != 200) {
                    warning (
                        "Jellyfin resource request failed: HTTP %u",
                        message.status_code
                    );
                    return null;
                }

                return response;
            } catch (GLib.Error e) {
                warning (
                    "Jellyfin resource request failed: %s",
                    e.message
                );
                return null;
            }
        }

        public string get_user_id () {
            return user_id ?? "";
        }

        public string get_stream_url (string item_id) {
            return base_url + "/Audio/" +
                Uri.escape_string (item_id) +
                "/stream?static=true&api_key=" +
                Uri.escape_string (access_token ?? "");
        }

        public string get_artwork_path (string item_id) {
            return "/Items/" +
                Uri.escape_string (item_id) +
                "/Images/Primary?api_key=" +
                Uri.escape_string (access_token ?? "");
        }

        public static string query_value (string value) {
            return Uri.escape_string (value, null, true);
        }

        private string build_authorization_header () {
            return "MediaBrowser " +
                "Client=\"" + CLIENT_NAME + "\", " +
                "Device=\"" + DEVICE_NAME + "\", " +
                "DeviceId=\"" + DEVICE_ID + "\", " +
                "Version=\"" + CLIENT_VERSION + "\"";
        }

        private static Json.Node? parse_json (Bytes bytes) {
            unowned uint8[] data = bytes.get_data ();

            var parser = new Json.Parser ();

            try {
                parser.load_from_data (
                    (string) data,
                    (ssize_t) data.length
                );

                Json.Node? root = parser.get_root ();

                if (root == null) {
                    return null;
                }

                return root.copy ();
            } catch (GLib.Error e) {
                warning ("Failed to parse Jellyfin JSON: %s", e.message);
                return null;
            }
        }

        public static string? string_member (
            Json.Object obj,
            string name
        ) {
            if (!obj.has_member (name)) {
                return null;
            }

            Json.Node node = obj.get_member (name);

            if (node.get_node_type () != Json.NodeType.VALUE) {
                return null;
            }

            if (node.get_value_type () != typeof (string)) {
                return null;
            }

            return node.get_string ();
        }

        public static int? int_member (
            Json.Object obj,
            string name
        ) {
            if (!obj.has_member (name)) {
                return null;
            }

            Json.Node node = obj.get_member (name);

            if (node.get_node_type () != Json.NodeType.VALUE) {
                return null;
            }

            if (node.get_value_type () != typeof (int64) &&
                node.get_value_type () != typeof (int) &&
                node.get_value_type () != typeof (double)) {
                return null;
            }

            return (int) node.get_int ();
        }

        public static int64? int64_member (
            Json.Object obj,
            string name
        ) {
            if (!obj.has_member (name)) {
                return null;
            }

            Json.Node node = obj.get_member (name);

            if (node.get_node_type () != Json.NodeType.VALUE) {
                return null;
            }

            return node.get_int ();
        }

        public static Json.Object? object_member (
            Json.Object obj,
            string name
        ) {
            if (!obj.has_member (name)) {
                return null;
            }

            Json.Node node = obj.get_member (name);

            if (node.get_node_type () != Json.NodeType.OBJECT) {
                return null;
            }

            return node.get_object ();
        }

        public static Gee.List<Genre> genres_member (
            Json.Object obj
        ) {
            var genres = new Gee.ArrayList<Genre> ();

            if (!obj.has_member ("Genres")) {
                return genres;
            }

            Json.Node node = obj.get_member ("Genres");

            if (node.get_node_type () != Json.NodeType.ARRAY) {
                return genres;
            }

            Json.Array array = node.get_array ();

            for (uint i = 0; i < array.get_length (); i++) {
                Json.Node genre_node = array.get_element (i);

                if (genre_node.get_node_type () != Json.NodeType.VALUE) {
                    continue;
                }

                string? name = genre_node.get_string ();

                if (name != null && name.strip () != "") {
                    genres.add (new Genre (name));
                }
            }

            return genres;
        }

        public static Json.Array? items_array (
            Json.Node? root
        ) {
            if (
                root == null ||
                root.get_node_type () != Json.NodeType.OBJECT
            ) {
                return null;
            }

            Json.Object obj = root.get_object ();

            if (!obj.has_member ("Items")) {
                return null;
            }

            Json.Node items = obj.get_member ("Items");

            if (items.get_node_type () != Json.NodeType.ARRAY) {
                return null;
            }

            return items.get_array ();
        }
    }
}
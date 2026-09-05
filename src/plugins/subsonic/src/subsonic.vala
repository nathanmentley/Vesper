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
using Xml;

using Vesper.Core;
using Vesper.Core.Models;
using Vesper.Core.Plugins;

namespace Vesper.Plugins.Subsonic {
    public interface IConfig : Object {
        public abstract string? base_url { owned get; }
        public abstract string? user { owned get; }
        public abstract string? pass { owned get; }
    }

    public interface ISubsonicClient : Object {
        public abstract async Gee.List<Artist> get_artists ();

        public abstract async Gee.List<Album> get_albums (
            string artist_id
        );

        public abstract async Gee.List<Song> get_songs (
            string album_id
        );
        
        public abstract async Bytes? get_cover_bytes (
            string cover_id
        );

        public static ISubsonicClient create (PluginKey key, IConfig config) {
            return new SubsonicClient (key, config);
        }

        private sealed class SubsonicClient : Object, ISubsonicClient {
            private IConfig config;
            private string client_id;
            private Soup.Session session;
            private PluginKey key;

            public SubsonicClient (
                PluginKey key,
                IConfig config,
                string client_id = "ValaApp"
            ) {
                this.key = key;
                this.config = config;
                this.client_id = client_id;
                this.session = new Soup.Session ();
            }

            /**
             * Interface Target: get_artists
             */
            public async Gee.List<Artist> get_artists () {
                var results = new ArrayList<Artist> ();

                string url = build_url ("getArtists");

                Xml.Doc* doc = yield fetch_xml_async (url);

                if (doc == null) {
                    return results;
                }

                try {
                    Xml.Node* root = doc->get_root_element ();

                    if (root == null) {
                        return results;
                    }

                    for (
                        Xml.Node* artists = root->children;
                        artists != null;
                        artists = artists->next
                    ) {
                        if (
                            artists->type == Xml.ElementType.ELEMENT_NODE &&
                            artists->name == "artists"
                        ) {
                            for (
                                Xml.Node* index = artists->children;
                                index != null;
                                index = index->next
                            ) {
                                for (
                                    Xml.Node* artist = index->children;
                                    artist != null;
                                    artist = artist->next
                                ) {
                                    if (
                                        artist->type == Xml.ElementType.ELEMENT_NODE &&
                                        artist->name == "artist"
                                    ) {
                                        string id =
                                            artist->get_prop ("id") ?? "";

                                        string name =
                                            artist->get_prop ("name") ?? "";

                                        results.add (
                                            new Artist (id, name, key.id)
                                        );
                                    }
                                }
                            }
                        }
                    }
                } finally {
                    delete doc;
                }

                return results;
            }

            /**
             * Interface Target: get_albums
             */
            public async Gee.List<Album> get_albums (
                string artist_id
            ) {
                var results = new ArrayList<Album> ();

                string url = build_url (
                    "getArtist",
                    "id=" + Uri.escape_string (artist_id)
                );

                Xml.Doc* doc = yield fetch_xml_async (url);

                if (doc == null) {
                    return results;
                }

                try {
                    Xml.Node* root = doc->get_root_element ();

                    if (root == null) {
                        return results;
                    }

                    for (
                        Xml.Node* artist = root->children;
                        artist != null;
                        artist = artist->next
                    ) {
                        if (
                            artist->type == Xml.ElementType.ELEMENT_NODE &&
                            artist->name == "artist"
                        ) {
                            for (
                                Xml.Node* album = artist->children;
                                album != null;
                                album = album->next
                            ) {
                                if (
                                    album->type == Xml.ElementType.ELEMENT_NODE &&
                                    album->name == "album"
                                ) {
                                    string id =
                                        album->get_prop ("id") ?? "";

                                    string name =
                                        album->get_prop ("name") ?? "";

                                    string? cover_art =
                                        album->get_prop ("coverArt");

                                    string? year =
                                        album->get_prop ("year");

                                    results.add (
                                        new Album (
                                            id,
                                            name,
                                            cover_art,
                                            year
                                        )
                                    );
                                }
                            }
                        }
                    }
                } finally {
                    delete doc;
                }

                return results;
            }
            
            /**
             * Interface Target: get_songs
             */
            public async Gee.List<Song> get_songs (
                string album_id
            ) {
                var results = new ArrayList<Song> ();

                string url = build_url (
                    "getAlbum",
                    "id=" + Uri.escape_string (album_id)
                );

                Xml.Doc* doc = yield fetch_xml_async (url);

                if (doc == null) {
                    return results;
                }

                try {
                    Xml.Node* root = doc->get_root_element ();

                    if (root == null) {
                        return results;
                    }

                    for (
                        Xml.Node* album_xml = root->children;
                        album_xml != null;
                        album_xml = album_xml->next
                    ) {
                        if (
                            album_xml->type == Xml.ElementType.ELEMENT_NODE &&
                            album_xml->name == "album"
                        ) {
                            string id =
                                album_xml->get_prop ("id") ?? album_id;

                            string name =
                                album_xml->get_prop ("name") ?? "";

                            string? cover_art =
                                album_xml->get_prop ("coverArt");

                            string? year =
                                album_xml->get_prop ("year");

                            var album = new Album (
                                id,
                                name,
                                cover_art,
                                year
                            );

                            for (
                                Xml.Node* song = album_xml->children;
                                song != null;
                                song = song->next
                            ) {
                                if (
                                    song->type == Xml.ElementType.ELEMENT_NODE &&
                                    song->name == "song"
                                ) {
                                    string song_id =
                                        song->get_prop ("id") ?? "";

                                    string title =
                                        song->get_prop ("title") ?? "";

                                    string? track_number_str =
                                        song->get_prop ("track");

                                    results.add (
                                        new Song (
                                            song_id,
                                            title,
                                            build_stream_url (song_id),
                                            int.parse (track_number_str ?? "0"),
                                            album
                                        )
                                    );
                                }
                            }
                        }
                    }
                } finally {
                    delete doc;
                }

                return results;
            }

            /**
             * Interface Target: get_cover_bytes
             */
            public async Bytes? get_cover_bytes (
                string cover_id
            ) {
                string url = build_url (
                    "getCoverArt",
                    "id=" + Uri.escape_string (cover_id)
                );

                var msg = new Soup.Message ("GET", url);

                try {
                    Bytes bytes = yield this.session.send_and_read_async (
                        msg,
                        GLib.Priority.DEFAULT,
                        null
                    );

                    if (msg.status_code == 200) {
                        return bytes;
                    }

                    warning (
                        "Cover fetch failed with HTTP status %u",
                        msg.status_code
                    );

                    return null;
                } catch (GLib.Error e) {
                    warning (
                        "Cover fetch fault: %s",
                        e.message
                    );

                    return null;
                }
            }

            private string build_stream_url (string id) {
                return build_url (
                    "stream",
                    "id=" + Uri.escape_string (id)
                );
            }

            private string build_url (
                string endpoint,
                string extra_params = ""
            ) {
                string base_url = get_base_url ();

                string url =
                    @"$(base_url)rest/$(endpoint)?u=$(this.config.user)&p=$(this.config.pass)&v=1.16.0&c=$(this.client_id)";

                if (extra_params != "") {
                    url += "&" + extra_params;
                }

                return url;
            }

            private string get_base_url () {
                return config.base_url.has_suffix ("/")
                    ? config.base_url
                    : config.base_url + "/";
            }

            /**
             * Shared async helper to pull an XML document from the
             * Subsonic server.
             */
            private async Xml.Doc* fetch_xml_async (
                string url
            ) {
                var msg = new Soup.Message ("GET", url);

                try {
                    Bytes bytes = yield this.session.send_and_read_async (
                        msg,
                        GLib.Priority.DEFAULT,
                        null
                    );

                    if (
                        msg.status_code != 200 ||
                        bytes == null
                    ) {
                        warning (
                            "HTTP error: %u",
                            msg.status_code
                        );

                        return null;
                    }

                    unowned uint8[] data = bytes.get_data ();

                    Xml.Doc* doc = Xml.Parser.parse_memory (
                        (string) data,
                        (int) data.length
                    );

                    return doc;
                } catch (GLib.Error e) {
                    warning (
                        "Network or decoding exception: %s",
                        e.message
                    );

                    return null;
                }
            }
        }
    }
}
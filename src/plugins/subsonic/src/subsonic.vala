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

                                        var genres = read_genres (artist);
                                        string? musicbrainz_id =
                                            artist->get_prop ("musicBrainzId");

                                        results.add (
                                            new Artist (
                                                id,
                                                name,
                                                key.id,
                                                genres,
                                                musicbrainz_id
                                            )
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

                                    var genres = read_genres (album);
                                    string? release_id = album->get_prop (
                                        "musicBrainzReleaseId"
                                    );
                                    string? release_group_id = album->get_prop (
                                        "musicBrainzReleaseGroupId"
                                    );

                                    results.add (
                                        new Album (
                                            id,
                                            name,
                                            cover_art,
                                            year,
                                            genres,
                                            release_id,
                                            release_group_id
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

                            var album_genres = read_genres (album_xml);
                            string? release_id = album_xml->get_prop (
                                "musicBrainzReleaseId"
                            );
                            string? release_group_id = album_xml->get_prop (
                                "musicBrainzReleaseGroupId"
                            );

                            var album = new Album (
                                id,
                                name,
                                cover_art,
                                year,
                                album_genres,
                                release_id,
                                release_group_id
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

                                    var song_genres = read_genres (song);

                                    results.add (
                                        new Song (
                                            song_id,
                                            title,
                                            build_stream_url (song_id),
                                            int.parse (track_number_str ?? "0"),
                                            album,
                                            parse_int (song->get_prop ("duration")),
                                            parse_int (song->get_prop ("discNumber")),
                                            parse_int (song->get_prop ("year")),
                                            parse_int (song->get_prop ("bitRate")),
                                            parse_int (song->get_prop ("bitDepth")),
                                            parse_int (song->get_prop ("sampleRate")),
                                            parse_int (song->get_prop ("channelCount")),
                                            parse_int64 (song->get_prop ("size")),
                                            song->get_prop ("contentType"),
                                            song->get_prop ("suffix"),
                                            parse_int (song->get_prop ("bpm")),
                                            song->get_prop ("musicBrainzId"),
                                            song_genres
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

            private static int? parse_int (string? value) {
                if (value == null || value.strip () == "") {
                    return null;
                }
                return int.parse (value);
            }

            private static int64? parse_int64 (string? value) {
                if (value == null || value.strip () == "") {
                    return null;
                }
                return int64.parse (value);
            }

            private static Gee.List<Genre> read_genres (Xml.Node* node) {
                var genres = new Gee.ArrayList<Genre> ();
                var names = new Gee.HashSet<string> ();
                string? genre = node->get_prop ("genre");

                if (genre != null && genre.strip () != "") {
                    names.add (genre);
                }

                for (Xml.Node* child = node->children; child != null; child = child->next) {
                    if (child->type == Xml.ElementType.ELEMENT_NODE && child->name == "genre") {
                        string? name = child->get_prop ("name");
                        if (name != null && name.strip () != "") {
                            names.add (name);
                        }
                    }
                }

                foreach (string name in names) {
                    genres.add (new Genre (name));
                }
                return genres;
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
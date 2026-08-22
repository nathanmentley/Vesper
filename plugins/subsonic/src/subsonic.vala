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

using PiPod.Core;
using PiPod.Core.Models;

namespace PiPod.Plugins.Subsonic {
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

        public abstract async Gee.List<Playlist> get_playlists ();

        public abstract async Gee.List<Song> get_playlist_songs (
            string playlist_id
        );

        public abstract async bool create_playlist (
            string name
        );

        public abstract async bool update_playlist (
            string playlist_id,
            string? name
        );

        public abstract async bool delete_playlist (
            string playlist_id
        );

        public static ISubsonicClient create (IConfig config) {
            return new SubsonicClient (config);
        }

        private sealed class SubsonicClient : Object, ISubsonicClient {
            private IConfig config;
            private string client_id;
            private Soup.Session session;

            public SubsonicClient (
                IConfig config,
                string client_id = "ValaApp"
            ) {
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
                                            new Artist (id, name)
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

                                    results.add (
                                        new Song (
                                            song_id,
                                            title,
                                            build_stream_url (song_id),
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

            public async Gee.List<Playlist> get_playlists () {
                var playlists = new Gee.ArrayList<Playlist> ();

                string url = build_url ("getPlaylists");

                Xml.Doc* doc = yield this.fetch_xml_async (url);

                if (doc == null) {
                    return playlists;
                }

                try {
                    Xml.Node* root = doc->get_root_element ();

                    if (root == null) {
                        return playlists;
                    }

                    for (
                        Xml.Node* node = root->children;
                        node != null;
                        node = node->next
                    ) {
                        if (
                            node->type == Xml.ElementType.ELEMENT_NODE &&
                            node->name == "playlists"
                        ) {
                            for (
                                Xml.Node* playlist = node->children;
                                playlist != null;
                                playlist = playlist->next
                            ) {
                                if (
                                    playlist->type == Xml.ElementType.ELEMENT_NODE &&
                                    playlist->name == "playlist"
                                ) {
                                    string id =
                                        playlist->get_prop ("id") ?? "";

                                    string name =
                                        playlist->get_prop ("name") ?? "";

                                    int song_count = int.parse (
                                        playlist->get_prop ("songCount") ?? "0"
                                    );

                                    int duration = int.parse (
                                        playlist->get_prop ("duration") ?? "0"
                                    );

                                    string? cover_art =
                                        playlist->get_prop ("coverArt");

                                    Playlist result = new Playlist (
                                        id,
                                        name,
                                        song_count,
                                        duration,
                                        cover_art
                                    );

                                    playlists.add (result);
                                }
                            }
                        }
                    }
                } finally {
                    delete doc;
                }

                return playlists;
            }

            public async Gee.List<Song> get_playlist_songs (
                string playlist_id
            ) {
                var songs = new Gee.ArrayList<Song> ();

                string url = build_url (
                    "getPlaylist",
                    "id=" + Uri.escape_string (playlist_id)
                );

                Xml.Doc* doc = yield this.fetch_xml_async (url);

                if (doc == null) {
                    return songs;
                }

                try {
                    Xml.Node* root = doc->get_root_element ();

                    if (root == null) {
                        return songs;
                    }

                    for (
                        Xml.Node* playlist = root->children;
                        playlist != null;
                        playlist = playlist->next
                    ) {
                        if (
                            playlist->type == Xml.ElementType.ELEMENT_NODE &&
                            playlist->name == "playlist"
                        ) {
                            for (
                                Xml.Node* song = playlist->children;
                                song != null;
                                song = song->next
                            ) {
                                if (
                                    song->type == Xml.ElementType.ELEMENT_NODE &&
                                    song->name == "entry"
                                ) {
                                    string id =
                                        song->get_prop ("id") ?? "";

                                    string title =
                                        song->get_prop ("title") ?? "";

                                    string album_id =
                                        song->get_prop ("albumId") ?? "";

                                    string album_title =
                                        song->get_prop ("album") ?? "";

                                    string album_cover =
                                        song->get_prop ("albumCover") ?? "";

                                    string year =
                                        song->get_prop ("year") ?? "";

                                    Album album = new Album (
                                        album_id,
                                        album_title,
                                        album_cover,
                                        year
                                    );

                                    Song result = new Song (
                                        id,
                                        title,
                                        build_stream_url (id),
                                        album
                                    );

                                    songs.add (result);
                                }
                            }
                        }
                    }
                } finally {
                    delete doc;
                }

                return songs;
            }

            public async bool create_playlist (
                string name
            ) {
                string url = build_url (
                    "createPlaylist",
                    "name=" + Uri.escape_string (name)
                );

                return yield this.execute_mutation_async (url);
            }

            public async bool update_playlist (
                string playlist_id,
                string? name
            ) {
                string params =
                    "playlistId=" + Uri.escape_string (playlist_id);

                if (name != null) {
                    params += "&name=" + Uri.escape_string (name);
                }

                string url = build_url (
                    "updatePlaylist",
                    params
                );

                return yield this.execute_mutation_async (url);
            }

            public async bool delete_playlist (
                string playlist_id
            ) {
                string url = build_url (
                    "deletePlaylist",
                    "id=" + Uri.escape_string (playlist_id)
                );

                return yield this.execute_mutation_async (url);
            }

            private async bool execute_mutation_async (
                string url
            ) {
                var msg = new Soup.Message ("GET", url);

                try {
                    var bytes = yield this.session.send_and_read_async (
                        msg,
                        GLib.Priority.DEFAULT,
                        null
                    );

                    if (msg.status_code != 200 || bytes == null) {
                        warning (
                            "Playlist mutation HTTP error: %u",
                            msg.status_code
                        );

                        return false;
                    }

                    return true;
                } catch (GLib.Error e) {
                    warning (
                        "Playlist mutation fault: %s",
                        e.message
                    );

                    return false;
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
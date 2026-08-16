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
using Soup;
using Xml;

using PiPod.Models;

namespace PiPod.Clients {
    public delegate void ArtistCallback (Artist artist);
    public delegate void AlbumCallback (Album album);
    public delegate void SongCallback (Song song);
    public delegate void CoverCallback (Bytes? bytes);

    public interface INavidromeClient : Object {
        public abstract void get_artists (ArtistCallback cb);
        public abstract void get_albums (string artist_id, AlbumCallback cb);
        public abstract void get_songs (Album album, SongCallback cb);
        public abstract void get_cover_bytes_async (string cover_id, CoverCallback cb);

        public static INavidromeClient create (IConfig config) {
            return new NavidromeClient (config);
        }

        private sealed class NavidromeClient : Object, INavidromeClient {
            private IConfig config;
            private string client_id;
            private Soup.Session session;

            public NavidromeClient (IConfig config, string client_id = "ValaApp") {
                this.config = config;
                this.client_id = client_id;
                this.session = new Soup.Session ();
            }

            /**
             * Interface Target: get_artists
             */
            public void get_artists (ArtistCallback cb) {
                string url = build_url ("getArtists");

                // Execute modern Vala Async block internally to fulfill sync signature callback
                this.fetch_xml_async.begin (url, (obj, res) => {
                    Xml.Doc* doc = this.fetch_xml_async.end (res);

                    if (doc == null) return;

                    try {
                        Xml.Node* root = doc->get_root_element ();
                        if (root == null) return;

                        // Drill down to locate child nodes safely using deep loops
                        for (Xml.Node* artists = root->children; artists != null; artists = artists->next) {
                            if (artists->type == Xml.ElementType.ELEMENT_NODE && artists->name == "artists") {
                                for (Xml.Node* index = artists->children; index != null; index = index->next) {
                                    for (Xml.Node* artist = index->children; artist != null; artist = artist->next) {
                                        if (artist->type == Xml.ElementType.ELEMENT_NODE && artist->name == "artist") {
                                            string id = artist->get_prop ("id") ?? "";
                                            string name = artist->get_prop ("name") ?? "";

                                            Artist result = new Artist (id, name);

                                            cb (result);
                                        }
                                    }
                                }
                            }
                        }
                    } finally {
                        delete doc; // Guaranteed low-level cleanup
                    }
                });
            }

            /**
             * Interface Target: get_albums
             */
            public void get_albums (string artist_id, AlbumCallback cb) {
                string url = build_url ("getArtist", "id=" + Uri.escape_string (artist_id));

                this.fetch_xml_async.begin (url, (obj, res) => {
                    Xml.Doc* doc = this.fetch_xml_async.end (res);
                    if (doc == null) return;

                    try {
                        Xml.Node* root = doc->get_root_element ();
                        if (root == null) return;

                        for (Xml.Node* artist = root->children; artist != null; artist = artist->next) {
                            if (artist->type == Xml.ElementType.ELEMENT_NODE && artist->name == "artist") {
                                for (Xml.Node* album = artist->children; album != null; album = album->next) {
                                    if (album->type == Xml.ElementType.ELEMENT_NODE && album->name == "album") {
                                        string id = album->get_prop ("id") ?? "";
                                        string name = album->get_prop ("name") ?? "";
                                        string? cover_art = album->get_prop ("coverArt");
                                        string? year = album->get_prop ("year");

                                        Album result = new Album (
                                            id,
                                            name,
                                            cover_art,
                                            year
                                        );

                                        cb (result);
                                    }
                                }
                            }
                        }
                    } finally {
                        delete doc;
                    }
                });
            }

            /**
             * Interface Target: get_songs
             */
            public void get_songs (Album album, SongCallback cb) {
                string url = build_url ("getAlbum", "id=" + Uri.escape_string (album.id));

                this.fetch_xml_async.begin (url, (obj, res) => {
                    Xml.Doc* doc = this.fetch_xml_async.end (res);
                    if (doc == null) return;

                    try {
                        Xml.Node* root = doc->get_root_element ();
                        if (root == null) return;

                        for (Xml.Node* album_xml = root->children; album_xml != null; album_xml = album_xml->next) {
                            if (album_xml->type == Xml.ElementType.ELEMENT_NODE && album_xml->name == "album") {
                                for (Xml.Node* song = album_xml->children; song != null; song = song->next) {
                                    if (song->type == Xml.ElementType.ELEMENT_NODE && song->name == "song") {
                                        string id = song->get_prop ("id") ?? "";
                                        string title = song->get_prop ("title") ?? "";

                                        Song result = new Song (
                                            id,
                                            title,
                                            build_stream_url (id),
                                            album
                                        );

                                        cb (result);
                                    }
                                }
                            }
                        }
                    } finally {
                        delete doc;
                    }
                });
            }

            /**
             * Interface Target: get_cover_bytes_async
             */
            public void get_cover_bytes_async (string cover_id, CoverCallback cb) {
                string url = build_url ("getCoverArt", "id=" + Uri.escape_string (cover_id));
                var msg = new Soup.Message ("GET", url);

                this.session.send_and_read_async.begin (msg, GLib.Priority.DEFAULT, null, (obj, res) => {
                    try {
                        var bytes = this.session.send_and_read_async.end (res);
                        if (msg.status_code == 200 && bytes != null) {
                            cb (bytes);
                        } else {
                            cb (null);
                        }
                    } catch (GLib.Error e) {
                        warning ("Cover fetch fault: %s", e.message);
                        cb (null);
                    }
                });
            }

            private string build_stream_url (string id) {
                return build_url ("stream", "id=" + Uri.escape_string (id));
            }

            /**
             * Helper to append Subsonic standard REST parameters to queries
             */
            private string build_url (string endpoint, string extra_params = "") {
                string base_url = get_base_url ();

                string url = @"$(base_url)rest/$(endpoint)?u=$(this.config.user)&p=$(this.config.pass)&v=1.16.0&c=$(this.client_id)";

                if (extra_params != "") {
                    url += "&" + extra_params;
                }

                return url;
            }

            private string get_base_url () {
                return config.base_url.has_suffix("/") ? config.base_url : config.base_url + "/";
            }

            /**
             * Shared underlying async helper to pull an XML stream from the Subsonic server
             */
            private async Xml.Doc* fetch_xml_async (string url) {
                var msg = new Soup.Message ("GET", url);
                try {
                    var bytes = yield this.session.send_and_read_async (msg, GLib.Priority.DEFAULT, null);
                    if (msg.status_code != 200 || bytes == null) {
                        warning ("HTTP error: %u", msg.status_code);
                        return null;
                    }

                    // Safely hand off raw memory bytes directly to libxml2
                    unowned uint8[] data = bytes.get_data ();
                    Xml.Doc* doc = Xml.Parser.parse_memory ((string) data, (int) data.length);
                    return doc;
                } catch (GLib.Error e) {
                    critical ("Network or decoding exception: %s", e.message);
                    return null;
                }
            }
        }
    }
}
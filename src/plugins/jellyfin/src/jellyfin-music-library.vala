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
using Json;

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

namespace Vesper.Plugins.Jellyfin {

    public sealed class JellyfinConfig : GLib.Object {
        private SettingsEngine settings;
        private SettingDefinition url_definition;
        private SettingDefinition username_definition;
        private SettingDefinition password_definition;

        public JellyfinConfig (
            SettingsEngine settings,
            SettingDefinition url_definition,
            SettingDefinition username_definition,
            SettingDefinition password_definition
        ) {
            this.settings = settings;
            this.url_definition = url_definition;
            this.username_definition = username_definition;
            this.password_definition = password_definition;
        }

        public string? server_url {
            owned get {
                return settings.get_string (url_definition);
            }
        }

        public string? username {
            owned get {
                return settings.get_string (username_definition);
            }
        }

        public string? password {
            owned get {
                return settings.get_string (password_definition);
            }
        }
    }

    public sealed class JellyfinMusicLibrary :
        GLib.Object,
        Plugin,
        ConfigurablePlugin,
        MusicLibrary,
        SettingsProvider {

        private SettingDefinition? url_definition;
        private SettingDefinition? username_definition;
        private SettingDefinition? password_definition;

        private JellyfinConfig? config;
        private JellyfinClient? client;

        public PluginKey key {
            owned get {
                return new PluginKey ("jellyfin-1", "Jellyfin");
            }
        }

        public JellyfinMusicLibrary () {
        }

        public void configure (SettingsEngine settings) {
            url_definition = new SettingDefinition (
                key.id,
                "server-url",
                "Server URL",
                "Jellyfin server URL, for example https://jellyfin.example.com",
                SettingType.STRING
            );

            username_definition = new SettingDefinition (
                key.id,
                "username",
                "Username",
                "Jellyfin username",
                SettingType.STRING
            );

            password_definition = new SettingDefinition (
                key.id,
                "password",
                "Password",
                "Jellyfin password",
                SettingType.PASSWORD
            );

            config = new JellyfinConfig (
                settings,
                url_definition,
                username_definition,
                password_definition
            );

            refresh_client ();
        }

        public Gee.List<SettingDefinition> get_setting_definitions () {
            var definitions = new Gee.ArrayList<SettingDefinition> ();

            if (url_definition != null) {
                definitions.add (url_definition);
            }

            if (username_definition != null) {
                definitions.add (username_definition);
            }

            if (password_definition != null) {
                definitions.add (password_definition);
            }

            return definitions;
        }

        public string get_id () {
            return key.id;
        }

        private void refresh_client () {
            client = null;

            if (config == null) {
                return;
            }

            string? url = config.server_url;
            string? username = config.username;
            string? password = config.password;

            if (
                url == null || url.strip () == "" ||
                username == null || username.strip () == "" ||
                password == null || password == ""
            ) {
                return;
            }

            client = new JellyfinClient (
                url.strip (),
                username,
                password
            );
        }

        private JellyfinClient? get_client () {
            if (client == null) {
                refresh_client ();
            }

            return client;
        }

        public async Gee.List<Artist> get_artists () {
            var results = new Gee.ArrayList<Artist> ();

            JellyfinClient? api = get_client ();

            if (api == null) {
                warning ("Jellyfin is not configured");
                return results;
            }

            Json.Node? response = yield api.get_json (
                "/Items",
                "UserId=" + JellyfinClient.query_value (
                    api.get_user_id ()
                ) +
                "&IncludeItemTypes=MusicArtist" +
                "&Recursive=true" +
                "&Fields=Genres,ProviderIds,DateCreated"
            );

            Json.Array? items = JellyfinClient.items_array (response);

            if (items == null) {
                return results;
            }

            for (uint i = 0; i < items.get_length (); i++) {
                Json.Node node = items.get_element (i);

                if (node.get_node_type () != Json.NodeType.OBJECT) {
                    continue;
                }

                Json.Object obj = node.get_object ();

                string id =
                    JellyfinClient.string_member (obj, "Id") ?? "";

                string name =
                    JellyfinClient.string_member (obj, "Name") ?? "";

                if (id == "" || name == "") {
                    continue;
                }

                string? musicbrainz_id = null;
                Json.Object? providers =
                    JellyfinClient.object_member (obj, "ProviderIds");

                if (providers != null) {
                    musicbrainz_id =
                        JellyfinClient.string_member (
                            providers,
                            "MusicBrainzArtist"
                        );
                }

                results.add (
                    new Artist (
                        id,
                        name,
                        key.id,
                        JellyfinClient.genres_member (obj),
                        musicbrainz_id
                    )
                );
            }

            return results;
        }

        public async Gee.List<Album> get_albums (
            string artist_id
        ) {
            var results = new Gee.ArrayList<Album> ();

            JellyfinClient? api = get_client ();

            if (api == null) {
                warning ("Jellyfin is not configured");
                return results;
            }

            Json.Node? response = yield api.get_json (
                "/Items",
                "UserId=" + JellyfinClient.query_value (
                    api.get_user_id ()
                ) +
                "&ArtistIds=" + JellyfinClient.query_value (artist_id) +
                "&IncludeItemTypes=MusicAlbum" +
                "&Recursive=true" +
                "&Fields=Genres,ProviderIds,DateCreated,ProductionYear"
            );

            Json.Array? items = JellyfinClient.items_array (response);

            if (items == null) {
                return results;
            }

            for (uint i = 0; i < items.get_length (); i++) {
                Json.Node node = items.get_element (i);

                if (node.get_node_type () != Json.NodeType.OBJECT) {
                    continue;
                }

                Json.Object obj = node.get_object ();

                string id =
                    JellyfinClient.string_member (obj, "Id") ?? "";

                string name =
                    JellyfinClient.string_member (obj, "Name") ?? "";

                if (id == "" || name == "") {
                    continue;
                }

                int? year =
                    JellyfinClient.int_member (obj, "ProductionYear");

                string? release_id = null;
                string? release_group_id = null;

                Json.Object? providers =
                    JellyfinClient.object_member (obj, "ProviderIds");

                if (providers != null) {
                    release_id =
                        JellyfinClient.string_member (
                            providers,
                            "MusicBrainzAlbum"
                        );

                    release_group_id =
                        JellyfinClient.string_member (
                            providers,
                            "MusicBrainzReleaseGroup"
                        );
                }

                results.add (
                    new Album (
                        id,
                        name,
                        id,
                        year != null ? year.to_string () : null,
                        JellyfinClient.genres_member (obj),
                        release_id,
                        release_group_id
                    )
                );
            }

            return results;
        }

        public async Gee.List<Song> get_tracks (
            string album_id
        ) {
            var results = new Gee.ArrayList<Song> ();

            JellyfinClient? api = get_client ();

            if (api == null) {
                warning ("Jellyfin is not configured");
                return results;
            }

            Json.Node? response = yield api.get_json (
                "/Items",
                "UserId=" + JellyfinClient.query_value (
                    api.get_user_id ()
                ) +
                "&ParentId=" + JellyfinClient.query_value (album_id) +
                "&IncludeItemTypes=Audio" +
                "&Recursive=true" +
                "&Fields=Genres,ProviderIds,DateCreated,MediaSources"
            );

            Json.Array? items = JellyfinClient.items_array (response);

            if (items == null) {
                return results;
            }

            for (uint i = 0; i < items.get_length (); i++) {
                Json.Node node = items.get_element (i);

                if (node.get_node_type () != Json.NodeType.OBJECT) {
                    continue;
                }

                Json.Object obj = node.get_object ();

                string id =
                    JellyfinClient.string_member (obj, "Id") ?? "";

                string title =
                    JellyfinClient.string_member (obj, "Name") ?? "";

                if (id == "" || title == "") {
                    continue;
                }

                string album_name =
                    JellyfinClient.string_member (obj, "Album") ?? "";

                string actual_album_id =
                    JellyfinClient.string_member (obj, "AlbumId") ?? album_id;

                int? album_year =
                    JellyfinClient.int_member (obj, "ProductionYear");

                var album = new Album (
                    actual_album_id,
                    album_name,
                    actual_album_id,
                    album_year != null ? album_year.to_string () : null
                );

                string artist_name =
                    JellyfinClient.string_member (obj, "AlbumArtist") ??
                    JellyfinClient.string_member (obj, "Artist") ??
                    "";

                var artist = new Artist (
                    "",
                    artist_name,
                    key.id
                );

                int64? runtime_ticks =
                    JellyfinClient.int64_member (obj, "RunTimeTicks");

                int? duration = null;

                if (runtime_ticks > 0) {
                    duration = (int) (runtime_ticks / 10000000);
                }

                int? track_number =
                    JellyfinClient.int_member (obj, "IndexNumber");

                int? disc_number =
                    JellyfinClient.int_member (obj, "ParentIndexNumber");

                int? bitrate = null;
                int? sample_rate = null;
                int? channels = null;

                Json.Array? sources = null;

                if (obj.has_member ("MediaSources")) {
                    Json.Node sources_node = obj.get_member ("MediaSources");

                    if (sources_node.get_node_type () == Json.NodeType.ARRAY) {
                        sources = sources_node.get_array ();
                    }
                }

                if (sources != null && sources.get_length () > 0) {
                    Json.Node source_node = sources.get_element (0);

                    if (source_node.get_node_type () == Json.NodeType.OBJECT) {
                        Json.Object source = source_node.get_object ();

                        bitrate = JellyfinClient.int_member (
                            source,
                            "Bitrate"
                        );

                        Json.Array? media_streams = null;

                        if (source.has_member ("MediaStreams")) {
                            Json.Node streams_node =
                                source.get_member ("MediaStreams");

                            if (streams_node.get_node_type () == Json.NodeType.ARRAY) {
                                media_streams = streams_node.get_array ();
                            }
                        }

                        if (media_streams != null) {
                            for (
                                uint j = 0;
                                j < media_streams.get_length ();
                                j++
                            ) {
                                Json.Node stream_node =
                                    media_streams.get_element (j);

                                if (
                                    stream_node.get_node_type () !=
                                    Json.NodeType.OBJECT
                                ) {
                                    continue;
                                }

                                Json.Object stream = stream_node.get_object ();

                                if (
                                    JellyfinClient.string_member (
                                        stream,
                                        "Type"
                                    ) != "Audio"
                                ) {
                                    continue;
                                }

                                sample_rate = JellyfinClient.int_member (
                                    stream,
                                    "SampleRate"
                                );

                                channels = JellyfinClient.int_member (
                                    stream,
                                    "Channels"
                                );

                                break;
                            }
                        }
                    }
                }

                string? musicbrainz_recording_id = null;

                Json.Object? providers =
                    JellyfinClient.object_member (obj, "ProviderIds");

                if (providers != null) {
                    musicbrainz_recording_id =
                        JellyfinClient.string_member (
                            providers,
                            "MusicBrainzTrack"
                        );
                }

                results.add (
                    new Song (
                        id,
                        title,
                        api.get_stream_url (id),
                        track_number ?? 0,
                        album,
                        artist,
                        duration,
                        disc_number,
                        album_year,
                        bitrate,
                        null,
                        sample_rate,
                        channels,
                        null,
                        JellyfinClient.string_member (obj, "Container"),
                        JellyfinClient.string_member (obj, "Container"),
                        null,
                        musicbrainz_recording_id,
                        JellyfinClient.genres_member (obj)
                    )
                );
            }

            return results;
        }

        public async Bytes? get_artwork (Song song) {
            JellyfinClient? api = get_client ();

            if (api == null) {
                return null;
            }

            return yield api.get_bytes (
                api.get_artwork_path (song.album.id)
            );
        }
        
        public PlayableStream? get_stream (Song song) {
            return new PlayableStream(song.stream_url);
        }
    }
}
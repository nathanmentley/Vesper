/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Core.Settings;

using PiPod.Plugins.Subsonic;

namespace PiPod.Plugins.Subsonic {
    public sealed class SubsonicConfig : IConfig, Object {
        private SettingsEngine settings_engine;

        private SettingDefinition base_url_settings_def;
        private SettingDefinition user_settings_def;
        private SettingDefinition pass_settings_def;

        public string? base_url {
            owned get {
                return settings_engine.get_string(base_url_settings_def);
            }
        }
        public string? user {
            owned get {
                return settings_engine.get_string(user_settings_def);
            }
        }
        public string? pass {
            owned get {
                return settings_engine.get_string(pass_settings_def);
            }
        }

        public SubsonicConfig(
            SettingsEngine settings_engine,
            SettingDefinition base_url_settings_def,
            SettingDefinition user_settings_def,
            SettingDefinition pass_settings_def
        ) {
            this.settings_engine = settings_engine;

            this.base_url_settings_def = base_url_settings_def;
            this.user_settings_def = user_settings_def;
            this.pass_settings_def = pass_settings_def;
        }
    }

    public sealed class SubsonicMusicLibrary :
        PiPod.Core.Plugins.Plugin,
        ConfigurablePlugin,
        MusicLibrary,
        PlaylistProvider,
        SettingsProvider,
        Object
    {
        public string id { get { return "subsonic-1"; } }

        public string source { get { return "Subsonic"; } }

        private sealed ISubsonicClient client;

        private SettingDefinition base_url_settings_def;
        private SettingDefinition user_settings_def;
        private SettingDefinition pass_settings_def;

        public SubsonicMusicLibrary () {
            Object ();
        }

        public void configure (SettingsEngine settings) {
            base_url_settings_def =
                new SettingDefinition (
                    id,
                    "server-url",
                    "Server URL",
                    "Subsonic server URL",
                    SettingType.STRING
                );

            user_settings_def = 
                new SettingDefinition (
                    id,
                    "username",
                    "Username",
                    "Subsonic username",
                    SettingType.STRING
                );

            pass_settings_def = 
                new SettingDefinition (
                    id,
                    "password",
                    "Password",
                    "Subsonic password",
                    SettingType.PASSWORD
                );

            IConfig config = new SubsonicConfig(
                settings,
                base_url_settings_def,
                user_settings_def,
                pass_settings_def
            );

            this.client = ISubsonicClient.create (config);
        }

        public Gee.List<SettingDefinition> get_setting_definitions () {
            var settings =
                new Gee.ArrayList<SettingDefinition> ();

            settings.add (base_url_settings_def);

            settings.add (user_settings_def);

            settings.add (pass_settings_def);

            return settings;
        }

        public async Gee.List<Artist> get_artists () {
            return yield client.get_artists ();
        }

        public async Gee.List<Album> get_albums (string artist_id) {
            return yield client.get_albums (artist_id);
        }

        public async Gee.List<Song> get_tracks (string album_id) {
            return yield client.get_songs (album_id);
        }

        public async GLib.Bytes? get_artwork (Song song) {
            return yield client.get_cover_bytes (song.album.cover);
        }

        public async Gee.List<Playlist> get_playlists () {
            return yield client.get_playlists ();
        }

        public async Gee.List<Song> get_playlist_songs (string playlist_id) {
            return yield client.get_playlist_songs (playlist_id);
        }

        public async void create_playlist (string name) {
            yield client.create_playlist (name);
        }

        public async void update_playlist (string playlist_id, string? name) {
            yield client.update_playlist (playlist_id, name);
        }

        public async void delete_playlist (string playlist_id) {
            yield client.delete_playlist (playlist_id);
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    Peas.ObjectModule object_module = module as Peas.ObjectModule;

    object_module.register_extension_type (typeof (MusicLibrary), typeof (SubsonicMusicLibrary));
    object_module.register_extension_type (typeof (PlaylistProvider), typeof (SubsonicMusicLibrary));
    object_module.register_extension_type (typeof (SettingsProvider), typeof (SubsonicMusicLibrary));
}
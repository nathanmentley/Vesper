/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using PiPod.Core;
using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Core.Plugins;

using PiPod.Plugins.Subsonic;

namespace PiPod.Plugins.Subsonic {
    public sealed class SubsonicMusicLibrary : MusicLibrary, PlaylistProvider, ConfigurablePlugin, SettingsProvider, Object {
        private sealed ISubsonicClient client;

        public string id { get; default = "id"; }

        public string source { get; default = "Subsonic"; }

        public SubsonicMusicLibrary () {
            Object ();
        }

        public void configure (IConfig config) {
            this.client = ISubsonicClient.create (config);
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

        public async GLib.Bytes? get_artwork (string artwork_id) {
            return yield client.get_cover_bytes (artwork_id);
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
}
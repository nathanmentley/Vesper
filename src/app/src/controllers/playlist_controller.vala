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

using Gee;
using Vesper.Core.Models;
using Vesper.Service.Mixes;
using Vesper.Service.Playlists;

using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class PlaylistController : BaseController<PlaylistView> {
        public signal void play_requested (Gee.List<Song> songs);
        public signal void shuffle_requested (Gee.List<Song> songs);

        private PlaylistService playlist_service;
        private MixService mix_service;

        public PlaylistController (
            PlaylistService playlist_service,
            MixService mix_service,
            Gtk.Window parent_window
        ) {
            base (new PlaylistView (parent_window));
            this.playlist_service = playlist_service;
            this.mix_service = mix_service;

            connect_view ();
        }

        private void connect_view () {
            view.mix_selected.connect (type => load_mix.begin (type));
            view.playlist_selected.connect (playlist => load_playlist.begin (playlist));
            view.play_requested.connect (songs => play_requested (songs));
            view.shuffle_requested.connect (songs => shuffle_requested (songs));
            view.create_playlist_request.connect (name => create_playlist.begin (name));
            view.rename_playlist_request.connect ((playlist, name) => rename_playlist.begin (playlist, name));
            view.delete_playlist_request.connect (playlist => delete_playlist.begin (playlist));
            view.playlist_songs_changed.connect ((playlist, songs) => save_songs.begin (playlist, songs));
        }

        public async void load_playlists () {
            try {
                var playlists = yield playlist_service.get_playlists ();
                view.show_landing (playlists);
            } catch (Error e) {
                view.show_error ("Failed to load playlists: " + e.message);
            }
        }

        private async void load_mix (MixType type) {
            try {
                var songs = yield mix_service.get_mix_songs (type);
                view.show_detail (mix_name (type), songs, false, null);
            } catch (Error e) {
                view.show_error ("Failed to load mix: " + e.message);
            }
        }

        private async void load_playlist (Playlist playlist) {
            try {
                var songs = yield playlist_service.get_playlist_songs (playlist.id);
                view.show_detail (playlist.name, songs, true, playlist);
            } catch (Error e) {
                view.show_error ("Failed to load playlist: " + e.message);
            }
        }

        private async void create_playlist (string name) {
            yield playlist_service.create_playlist (name);
            yield load_playlists ();
        }

        private async void rename_playlist (Playlist playlist, string name) {
            var songs = yield playlist_service.get_playlist_songs (playlist.id);
            yield playlist_service.update_playlist (playlist.id, name, songs);
            yield load_playlist (
                new Playlist (
                    playlist.id,
                    name,
                    songs.size,
                    playlist.duration,
                    playlist.cover_art
                )
            );
        }

        private async void save_songs (Playlist playlist, Gee.List<Song> songs) {
            yield playlist_service.update_playlist (playlist.id, playlist.name, songs);
        }

        private async void delete_playlist (Playlist playlist) {
            yield playlist_service.delete_playlist (playlist.id);
            yield load_playlists ();
        }

        private string mix_name (MixType type) {
            switch (type) {
                case MixType.FAVORITES: return "Favorites";
                case MixType.RECENTLY_PLAYED: return "Recently Played";
                case MixType.RECENTLY_ADDED: return "Recently Added";
                case MixType.MOST_PLAYED: return "Most Played";
                case MixType.NEVER_PLAYED: return "Never Played";
                default: return "Mix";
            }
        }
    }
}

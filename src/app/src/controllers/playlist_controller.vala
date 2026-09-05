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

using Vesper.Core.Models;

using Vesper.Service.Playlists;

using Vesper.App.Models;
using Vesper.App.Utils;
using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class PlaylistController : BaseController<PlaylistView> {
        public signal void selected ();

        private PlaylistService playlist_service;
        private PlayQueue queue;

        public PlaylistController (
            PlayQueue queue,
            PlaylistService playlist_service,
            Gtk.Window parent_window
        ) {
            base (new PlaylistView (queue, parent_window));

            this.playlist_service = playlist_service;
            this.queue = queue;
        }

        protected override void connect_view () {
            view.selected.connect (() => selected ());

            view.change_playlist_request.connect (
                playlist => load_playlist.begin (playlist)
            );

            view.create_playlist_request.connect (
                name => create_playlist.begin (name)
            );

            view.rename_playlist_request.connect (
                (playlist, name) => save_playlist.begin (playlist, name)
            );

            view.delete_playlist_request.connect (
                playlist => delete_playlist.begin (playlist)
            );
        }

        private AtomicFlag _is_loading_playlists = new AtomicFlag ();

        public async void load_playlists () {
            if (!_is_loading_playlists.compare_and_exchange (false, true)) {
                return;
            }

            view.clear_playlist_dropdown ();

            // The local working queue is always available.
            view.add_playlist_to_dropdown (
                new Playlist (
                    "-1",
                    "(Current Queue)",
                    0,
                    0,
                    null
                )
            );

            var playlists = yield playlist_service.get_playlists ();

            foreach (var playlist in playlists) {
                view.add_playlist_to_dropdown (playlist);
            }

            _is_loading_playlists.flag = false;
        }

        public void rebuild () {
            view.rebuild ();
        }

        private async void load_playlist (
            Playlist playlist
        ) {
            queue.clear ();

            if (playlist.id == "-1") {
                view.rebuild ();
                return;
            }

            var songs =
                yield playlist_service.get_playlist_songs (
                    playlist.id
                );

            foreach (var song in songs) {
                queue.add_song (song);
            }

            view.rebuild ();
        }

        private async void create_playlist (
            string name
        ) {
            yield playlist_service.create_playlist (name);
            yield load_playlists ();
        }

        private async void save_playlist (
            Playlist playlist,
            string name
        ) {
            yield playlist_service.update_playlist (
                playlist.id,
                name,
                queue.get_songs ()
            );

            yield load_playlists ();
        }

        private async void delete_playlist (
            Playlist playlist
        ) {
            // The current queue isn't a real playlist.
            if (playlist.id == "-1") {
                return;
            }

            yield playlist_service.delete_playlist (
                playlist.id
            );

            yield load_playlists ();
        }
    }
}
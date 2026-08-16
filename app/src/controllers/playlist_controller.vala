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

using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Models;
using PiPod.Views;

namespace PiPod.Controllers {
    public class PlaylistController : BaseController<PlaylistView> {
        public signal void selected ();

        private PlaylistProvider playlist_provider;
        private PlayQueue queue;

        public PlaylistController (
            PlayQueue playlist,
            PlaylistProvider playlist_provider
        ) {
            base (
                new PlaylistView (playlist)
            );

            this.playlist_provider = playlist_provider;
            this.queue = playlist;
        }

        protected override void connect_view () {
            /*
             * ---------------------------------------------------------
             * Local queue selection
             * ---------------------------------------------------------
             */

            view.selected.connect (() => {
                selected ();
            });

            /*
             * ---------------------------------------------------------
             * Playlist selection
             * ---------------------------------------------------------
             */

            view.change_playlist_request.connect (playlist => { load_playlist.begin(playlist); });

            /*
             * ---------------------------------------------------------
             * Playlist CRUD
             * ---------------------------------------------------------
             */

            view.create_playlist_request.connect (
                name => {
                    create_playlist (name);
                }
            );

            view.rename_playlist_request.connect (
                (playlist, name) => {
                    save_playlist (playlist, name);
                }
            );

            view.delete_playlist_request.connect (
                playlist => {
                    delete_playlist (playlist);
                }
            );
        }

        /*
         * =============================================================
         * Loading playlists
         * =============================================================
         */

        public async void load_playlists () {
            view.clear_playlist_dropdown ();

            /*
             * The local working queue is always available.
             */

            view.add_playlist_to_dropdown (
                new Playlist (
                    "-1",
                    "(Current Queue)",
                    0,
                    0,
                    null
                )
            );

            var playlists = yield playlist_provider.get_playlists ();

            foreach (var playlist in playlists) {
                view.add_playlist_to_dropdown (playlist);
            }
        }

        /*
         * =============================================================
         * Rebuild local queue
         * =============================================================
         */

        public void rebuild () {
            view.rebuild ();
        }

        /*
         * =============================================================
         * Load a playlist
         * =============================================================
         */

        private async void load_playlist (
            Playlist playlist
        ) {
            queue.clear ();

            if (playlist.id == "-1") {
                view.rebuild ();

                return;
            }

            var songs = yield playlist_provider.get_playlist_songs (playlist.id);

            foreach (var song in songs) {
                queue.add_song (song);
            }
            
            view.rebuild ();
        }

        /*
         * =============================================================
         * Create playlist
         * =============================================================
         */

        private void create_playlist (
            string name
        ) {
            stdout.printf (
                "[PlaylistController] CREATE playlist\n"
            );

            stdout.printf (
                "  Name: %s\n",
                name
            );

            stdout.printf (
                "  Songs: %d\n",
                queue.get_songs ().size
            );

            foreach (Song song in queue.get_songs ()) {
                stdout.printf (
                    "  - %s (%s)\n",
                    song.title,
                    song.id
                );
            }
        }

        /*
         * =============================================================
         * Rename/update playlist
         * =============================================================
         */

        private void save_playlist (
            Playlist playlist,
            string name
        ) {
            stdout.printf (
                "[PlaylistController] UPDATE playlist\n"
            );

            stdout.printf (
                "  ID: %s\n",
                playlist.id
            );

            stdout.printf (
                "  Name: %s\n",
                name
            );

            stdout.printf (
                "  Songs: %d\n",
                queue.get_songs ().size
            );

            foreach (Song song in queue.get_songs ()) {
                stdout.printf (
                    "  - %s (%s)\n",
                    song.title,
                    song.id
                );
            }
        }

        /*
         * =============================================================
         * Delete playlist
         * =============================================================
         */

        private void delete_playlist (
            Playlist playlist
        ) {
            stdout.printf (
                "[PlaylistController] DELETE playlist\n"
            );

            stdout.printf (
                "  ID: %s\n",
                playlist.id
            );

            stdout.printf (
                "  Name: %s\n",
                playlist.name
            );
        }
    }
}
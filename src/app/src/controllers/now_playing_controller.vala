/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://gnu.org/licenses/>.
 */

using GLib;

using Vesper.Core.Models;

using Vesper.Service.Libraries;

using Vesper.App.Models;
using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class NowPlayingController : BaseController<NowPlayingView> {
        private LibraryService library_service;
        private PlayQueue queue;

        public signal void play_requested (Song song);

        public NowPlayingController (
            LibraryService library_service,
            PlayQueue queue,
            Gtk.Window parent_window
        ) {
            base (
                new NowPlayingView (
                    parent_window
                )
            );

            this.library_service = library_service;
            this.queue = queue;

            connect_view ();
        }

        private void connect_view () {
            view.queue_song_selected.connect (
                index => {
                    select_queue_song (index);
                }
            );

            view.queue_song_move_request.connect (
                (from_index, to_index) => {
                    queue.move_song (
                        from_index,
                        to_index
                    );
                }
            );

            view.queue_song_delete_request.connect (
                index => {
                    queue.delete_song (
                        index
                    );
                }
            );

            view.queue_clear_request.connect (
                () => {
                    queue.clear ();
                }
            );

            queue.changed.connect (() => {
                stdout.printf (
                    "QUEUE CHANGED: %d songs, current=%d\n",
                    queue.get_songs ().size,
                    queue.get_current_index ()
                );

                view.set_queue (
                    queue.get_songs (),
                    queue.get_current_index ()
                );
            });

            queue.current_changed.connect (() => {
                view.set_queue_current_index (
                    queue.get_current_index ()
                );
            });

            view.set_queue (
                queue.get_songs (),
                queue.get_current_index ()
            );
        }

        public void set_song (Song song) {
            view.set_song (song);
            view.set_album (song.album);

            set_cover_art.begin (song);
        }

        private void select_queue_song (
            int index
        ) {
            queue.set_current_index (
                index
            );

            Song? song =
                queue.get_current_song ();

            if (song != null) {
                play_requested (song);
            }
        }

        private async void set_cover_art (
            Song song
        ) {
            if (song.album.cover == null) {
                view.set_album_art (null);
                return;
            }

            try {
                GLib.Bytes? bytes =
                    yield library_service.get_artwork (
                        song
                    );

                if (bytes == null) {
                    view.set_album_art (null);
                    return;
                }

                view.set_album_art (
                    bytes
                );
            } catch (GLib.Error e) {
                view.set_album_art (null);
            }
        }
    }
}
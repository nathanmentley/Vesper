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
using Gtk;
using PiPod.Components;
using PiPod.Models;
using PiPod.Utils;

namespace PiPod.Views {
    public class PlaylistView : BaseView {
        public signal void selected ();

        private Playlist playlist;
        private ListBox song_list;

        public PlaylistView (Playlist playlist) {
            Object (orientation: Orientation.VERTICAL, spacing: 6);

            this.playlist = playlist;
            build_ui ();
            connect_signals ();
        }

        public void rebuild() {
            clear_list (song_list);

            Collection<Song> songs = playlist.get_songs ();

            int current_index = playlist.get_current_index ();

            int counter = 0;

            foreach (Song song in songs) {
                PlaylistEntry entry = new PlaylistEntry (song, counter, counter == current_index);

                entry.selected.connect (index => {
                    playlist.set_current_index (index);

                    selected ();

                    rebuild ();
                });

                entry.move_up_request.connect (index => {
                    playlist.move_song (index, index - 1);

                    rebuild ();
                });

                entry.move_down_request.connect (index => {
                    playlist.move_song (index, index + 1);

                    rebuild ();
                });

                entry.delete_request.connect (index => {
                    playlist.delete_song (index);

                    rebuild ();
                });

                song_list.append (entry);
                counter++;
            }
        }

        private void clear_list (ListBox list) {
            Widget? child = list.get_first_child ();

            while (child != null) {
                Widget? next = child.get_next_sibling ();

                list.remove (child);

                child = next;
            }
        }

        private void build_ui () {
            Box box = new Box (Orientation.HORIZONTAL, 6);

            append (box);

            song_list = new ListBox ();

            box.append (song_list);
        }

        private void connect_signals () {
        }
    }
}
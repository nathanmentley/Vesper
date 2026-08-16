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
using GLib;

using PiPod.Core.Models;

namespace PiPod.Models {
    public class PlayQueue : Object {
        private ArrayList<Song> _songs = new ArrayList<Song> ();
        private int _current_index = -1;

        public PlayQueue () {
            Object ();
        }

        public void add_song (Song song) {
            if (_songs.size == 0) {
                _current_index = 0;
            }

            _songs.add (song);
        }

        public Song? get_next_song () {
            if (_current_index + 1 < _songs.size) {
                _current_index++;

                return _songs.get (_current_index);
            }

            _current_index = _songs.size > 0 ? 0 : -1;

            return null;
        }

        public Song? get_current_song () {
            if (_current_index >= 0 && _current_index < _songs.size) {
                return _songs.get (_current_index);
            }

            return null;
        }

        public Song? get_previous_song () {
            if (_current_index - 1 >= 0 && !_songs.is_empty) {
                _current_index--;

                return _songs.get (_current_index);
            }

            _current_index = _songs.size > 0 ? _songs.size - 1 : -1;

            return null;
        }

        public Song? get_random_song () {
            if (_songs.is_empty) {
                _current_index = -1;

                return null;
            }

            int random_index =
                Random.int_range (
                    0,
                    _songs.size
                );

            _current_index =
                random_index;

            return _songs.get (
                _current_index
            );
        }

        public Collection<Song> get_songs () {
            return _songs.read_only_view;
        }

        public void move_song (int from_index, int to_index) {
            if (from_index >= 0 && from_index < _songs.size && to_index >= 0 && to_index < _songs.size) {
                Song song = _songs.get (from_index);

                _songs.remove_at (from_index);
                _songs.insert (to_index, song);

                if (_current_index == from_index) {
                    _current_index = to_index;
                } else if (_current_index > from_index && _current_index <= to_index) {
                    _current_index--;
                } else if (_current_index < from_index && _current_index >= to_index) {
                    _current_index++;
                }
            }
        }

        public void clear () {
            _songs.clear ();
            _current_index = -1;
        }

        public int get_current_index () {
            return _current_index;
        }

        public void set_current_index (int index) {
            if (index >= 0 && index < _songs.size) {
                _current_index = index;
            }
        }

        public void delete_song (int index) {
            if (index >= 0 && index < _songs.size) {
                _songs.remove_at (index);

                if (_current_index == index) {
                    _current_index = -1;
                } else if (_current_index > index) {
                    _current_index--;
                }
            }
        }
    }
}
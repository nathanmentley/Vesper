/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
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

using Vesper.Core.Models;

namespace Vesper.App.Models {
    public class PlayQueue : Object {
        public signal void changed ();
        public signal void current_changed ();

        private Gee.List<Song> _songs =
            new ArrayList<Song> ();

        private int _current_index = -1;

        public PlayQueue () {
            Object ();
        }

        /*
         * Adds a song to the end of the queue.
         *
         * Backwards compatible with the previous implementation.
         */
        public void add_song (Song song) {
            bool current_changed = false;

            if (_songs.size == 0) {
                _current_index = 0;
                current_changed = true;
            }

            _songs.add (song);

            changed ();

            if (current_changed) {
                this.current_changed ();
            }
        }

        /*
         * Adds multiple songs to the end of the queue.
         */
        public void add_songs (Collection<Song> songs) {
            if (songs.is_empty) {
                return;
            }

            bool current_changed = false;

            if (_songs.size == 0) {
                _current_index = 0;
                current_changed = true;
            }

            foreach (Song song in songs) {
                _songs.add (song);
            }

            changed ();

            if (current_changed) {
                this.current_changed ();
            }
        }

        /*
         * Replaces the entire queue.
         *
         * The first song becomes the current song.
         */
        public void set_songs (Collection<Song> songs) {
            _songs.clear ();

            foreach (Song song in songs) {
                _songs.add (song);
            }

            int old_index = _current_index;

            _current_index =
                _songs.is_empty ? -1 : 0;

            changed ();

            if (old_index != _current_index) {
                current_changed ();
            } else if (_current_index >= 0) {
                /*
                 * Even when the numeric index happens to remain
                 * the same, the song at that index may have changed.
                 */
                current_changed ();
            }
        }

        /*
         * Advances to the next song and returns it.
         *
         * This preserves the existing get_next_song() behavior.
         */
        public Song? get_next_song () {
            return advance_next ();
        }

        /*
         * Advances to the next song and returns it.
         */
        public Song? advance_next () {
            if (_current_index + 1 < _songs.size) {
                _current_index++;

                current_changed ();

                return _songs.get (
                    _current_index
                );
            }

            _current_index =
                _songs.size > 0 ? 0 : -1;

            current_changed ();

            return null;
        }

        /*
         * Returns the next song without changing the current position.
         */
        public Song? peek_next_song () {
            if (_current_index + 1 < _songs.size) {
                return _songs.get (
                    _current_index + 1
                );
            }

            return null;
        }

        /*
         * Returns the current song without changing queue state.
         */
        public Song? get_current_song () {
            if (_current_index >= 0 &&
                _current_index < _songs.size) {
                return _songs.get (
                    _current_index
                );
            }

            return null;
        }

        /*
         * Moves to the previous song and returns it.
         *
         * This preserves the existing get_previous_song() behavior.
         */
        public Song? get_previous_song () {
            return advance_previous ();
        }

        /*
         * Moves to the previous song and returns it.
         */
        public Song? advance_previous () {
            if (_current_index - 1 >= 0 &&
                !_songs.is_empty) {
                _current_index--;

                current_changed ();

                return _songs.get (
                    _current_index
                );
            }

            _current_index =
                _songs.size > 0
                    ? _songs.size - 1
                    : -1;

            current_changed ();

            return null;
        }

        /*
         * Returns the previous song without changing queue state.
         */
        public Song? peek_previous_song () {
            if (_current_index - 1 >= 0 &&
                _current_index - 1 < _songs.size) {
                return _songs.get (
                    _current_index - 1
                );
            }

            return null;
        }

        /*
         * Selects a random song and makes it current.
         *
         * Backwards compatible with the previous implementation.
         */
        public Song? get_random_song () {
            if (_songs.is_empty) {
                _current_index = -1;

                current_changed ();

                return null;
            }

            int random_index =
                Random.int_range (
                    0,
                    _songs.size
                );

            _current_index =
                random_index;

            current_changed ();

            return _songs.get (
                _current_index
            );
        }

        /*
         * Returns a read-only view of the queue.
         */
        public Collection<Song> get_songs () {
            return _songs.read_only_view;
        }

        /*
         * Moves a song from one queue position to another.
         */
        public void move_song (
            int from_index,
            int to_index
        ) {
            if (from_index < 0 ||
                from_index >= _songs.size ||
                to_index < 0 ||
                to_index >= _songs.size ||
                from_index == to_index) {
                return;
            }

            Song song =
                _songs.get (from_index);

            _songs.remove_at (
                from_index
            );

            _songs.insert (
                to_index,
                song
            );

            if (_current_index == from_index) {
                _current_index = to_index;
            } else if (
                _current_index > from_index &&
                _current_index <= to_index
            ) {
                _current_index--;
            } else if (
                _current_index < from_index &&
                _current_index >= to_index
            ) {
                _current_index++;
            }

            changed ();
        }

        /*
         * Removes all songs from the queue.
         */
        public void clear () {
            if (_songs.is_empty &&
                _current_index == -1) {
                return;
            }

            _songs.clear ();

            _current_index = -1;

            changed ();
            current_changed ();
        }

        public int get_current_index () {
            return _current_index;
        }

        /*
         * Changes the current queue position.
         */
        public void set_current_index (
            int index
        ) {
            if (index < 0 ||
                index >= _songs.size ||
                index == _current_index) {
                return;
            }

            _current_index = index;

            current_changed ();
        }

        /*
         * Removes a song from the queue.
         */
        public void delete_song (
            int index
        ) {
            if (index < 0 ||
                index >= _songs.size) {
                return;
            }

            bool current_changed = false;

            _songs.remove_at (index);

            if (_songs.is_empty) {
                if (_current_index != -1) {
                    _current_index = -1;
                    current_changed = true;
                }
            } else if (_current_index == index) {
                /*
                 * Keep playback pointing at a valid queue entry.
                 *
                 * Prefer the song that shifted into this position,
                 * or the final song if the current song was last.
                 */
                if (index < _songs.size) {
                    _current_index = index;
                } else {
                    _current_index =
                        _songs.size - 1;
                }

                current_changed = true;
            } else if (_current_index > index) {
                _current_index--;
            }

            changed ();

            if (current_changed) {
                this.current_changed ();
            }
        }
    }
}
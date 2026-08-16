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

using Gst;

namespace PiPod.Clients {
    public delegate bool BusWatchCallback (Gst.Bus bus, Gst.Message msg);

    public interface IMusicEngine : GLib.Object {
        public abstract void set_source (string uri, BusWatchCallback callback);

        public abstract bool has_player ();

        public abstract int64 get_position ();
        public abstract int64 get_duration ();

        public abstract void stop_player ();
        public abstract bool start_player ();
        public abstract void pause_player ();

        public abstract void seek (int64 ns);

        public static IMusicEngine create (string[] args) {
            return new MusicEngine (args);
        }

        private sealed class MusicEngine : IMusicEngine, GLib.Object {
            private Element? player = null;

            public MusicEngine (string[] args) {
                Gst.init (ref args);
            }

            public void set_source (string uri, BusWatchCallback callback) {
                stop_player ();

                string esc = uri.replace ("\"", "\\\"");

                player = Gst.parse_launch ("playbin uri=\"" + uri + "\"");

                Gst.Bus bus = player.get_bus ();

                if (bus != null) {
                    bus.add_watch (0, (b, m) => callback(b, m));
                }
            }

            public bool has_player () {
                return player != null;
            }

            public int64 get_position () {
                if (player == null) {
                    return 0;
                }

                int64 pos = 0;

                player.query_position (Gst.Format.TIME, out pos);

                return pos;
            }

            public int64 get_duration () {
                if (player == null) {
                    return 0;
                }

                int64 dur = 0;

                player.query_duration (Gst.Format.TIME, out dur);

                return dur;
            }

            public void stop_player () {
                if (player == null) {
                    return;
                }

                player.set_state (State.NULL);

                player = null;
            }

            public bool start_player () {
                if (player == null) {
                    return false;
                }

                return player.set_state (State.PLAYING) != StateChangeReturn.FAILURE;
            }

            public void pause_player () {
                if (player == null) {
                    return;
                }

                player.set_state (State.PAUSED);
            }

            public void seek (int64 ns) {
                if (player == null) {
                    return;
                }

                player.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, ns);
            }
        }
    }
}
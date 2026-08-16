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

using Gtk;
using Gst;
using GLib;

using PiPod.Clients;
using PiPod.Models;
using PiPod.Views;

namespace PiPod.Controllers {
    public class PlayerController : BaseController<PlayerView> {
        public signal void song_finished ();
        public signal void previous_requested ();
        public signal void next_requested ();

        private IMusicEngine music;
        private uint position_timer_id = 0;

        public PlayerController (IMusicEngine music) {
            base(new PlayerView());

            this.music = music;
        }
        
        protected override void connect_view () {
            view.play_requested.connect (resume);

            view.pause_requested.connect (pause);

            view.stop_requested.connect (stop);

            view.previous_requested.connect (() => previous_requested ());

            view.next_requested.connect (() => next_requested ());

            view.seek_requested.connect (seek);
        }

        public void set_status (string status) {
            view.set_status (status);
        }

        public void set_error (string status) {
            view.set_status (status);
        }

        public bool is_playing () {
            return music.has_player ();
        }

        public void play (Song song) {
            string uri = song.stream_url;

            if (uri.length == 0) {
                set_status ("Please enter a stream URL");

                return;
            }

            stop ();

            try {
                music.set_source (uri, handle_bus_message);
            } catch (GLib.Error e) {
                set_error ("Failed to create player: " + e.message);

                return;
            }

            bool started = music.start_player ();

            if (!started) {
                set_error ("Failed to start playback");

                stop ();

                return;
            }

            set_status ("Playing");

            start_position_timer ();
        }

        public void stop () {
            music.stop_player ();

            stop_position_timer ();

            view.set_position (0, 0);

            set_status ("Stopped");
        }

        private void resume () {
            music.start_player ();

            set_status ("Playing");

            start_position_timer ();
        }

        private void pause () {
            music.pause_player ();

            set_status ("Paused");
        }

        private void seek (int64 position_ns) {
            try {
                music.seek (position_ns);
            } catch (GLib.Error e) {
                // Seek failures are non-fatal.
            }
        }

        private void start_position_timer () {
            stop_position_timer ();

            position_timer_id = Timeout.add (500, update_position);
        }

        private void stop_position_timer () {
            if (position_timer_id != 0) {
                Source.remove (position_timer_id);

                position_timer_id = 0;
            }
        }

        private bool update_position () {
            if (!music.has_player ()) {
                return false;
            }

            int64 position = music.get_position ();

            int64 duration = music.get_duration ();

            view.set_position (position, duration);

            return true;
        }

        private bool handle_bus_message (Gst.Bus bus, Gst.Message message) {
            switch (message.type) {
                case Gst.MessageType.EOS:
                    stop_position_timer ();

                    set_status ("Finished");

                    song_finished ();

                    return true;

                case Gst.MessageType.ERROR:
                    GLib.Error? error = null;
                    string debug = "";

                    message.parse_error (out error, out debug);

                    string message_text = error != null ? error.message : "Unknown GStreamer error";

                    stop_position_timer ();

                    set_error ("Error: " + message_text);

                    return true;

                default:
                    return true;
            }
        }
    }
}
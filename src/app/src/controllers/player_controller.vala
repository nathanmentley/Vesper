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

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Service.Media;
using Vesper.Service.UserState;

using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class PlayerController : BaseController<PlayerView> {
        public signal void song_finished ();
        public signal void previous_requested ();
        public signal void next_requested ();

        public signal void shuffle_requested (bool enabled);
        public signal void repeat_requested (bool enabled);

        private MediaService music;
        private UserStateService user_state;
        private Song? current_song;
        private bool current_song_recorded = false;
        private uint position_timer_id = 0;

        private bool shuffle_enabled = false;
        private bool repeat_enabled = false;

        public PlayerController (
            MediaService music,
            UserStateService user_state,
            Gtk.Window parent_window
        ) {
            base(new PlayerView(parent_window));

            this.view.set_shuffle_active (shuffle_enabled);
            this.view.set_repeat_active (repeat_enabled);
            this.view.set_volume (1.0);

            this.music = music;
            this.user_state = user_state;

            music.state_changed.connect (status => {
                if (status == PlaybackState.FINISHED) {
                    record_finished_play ();
                    stop_position_timer ();
                    set_status ("Finished");
                    song_finished ();
                }
            });
        }
        
        protected override void connect_view () {
            view.play_requested.connect (resume);

            view.pause_requested.connect (pause);

            view.stop_requested.connect (stop);

            view.previous_requested.connect (() => previous_requested ());

            view.next_requested.connect (() => next_requested ());

            view.seek_requested.connect (seek);

            view.shuffle_requested.connect (toggle_shuffle);

            view.repeat_requested.connect (toggle_repeat);

            view.volume_changed.connect (volume => music.set_volume (volume));
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

            current_song = song;
            current_song_recorded = false;

            try {
                music.set_source (uri);
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

        private void record_finished_play () {
            if (current_song == null || current_song_recorded) {
                return;
            }

            int64 duration_ns = music.get_position ();
            int duration = (int) (duration_ns / Gst.SECOND);

            if (duration < 0) {
                duration = 0;
            }

            try {
                user_state.record_play (
                    current_song.id,
                    new GLib.DateTime.now_utc ().to_unix (),
                    duration,
                    true
                );
                current_song_recorded = true;
            } catch (Error e) {
                warning (
                    "Failed to record completed play for '%s': %s",
                    current_song.id,
                    e.message
                );
            }
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
        
        private void toggle_shuffle () {
            shuffle_enabled = !shuffle_enabled;

            view.set_shuffle_active (shuffle_enabled);

            shuffle_requested (shuffle_enabled);
        }

        private void toggle_repeat () {
            repeat_enabled = !repeat_enabled;

            view.set_repeat_active (repeat_enabled);

            repeat_requested (repeat_enabled);
        }
    }
}
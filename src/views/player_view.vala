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
using PiPod.Models;
using PiPod.Utils;

namespace PiPod.Views {
    public class PlayerView : BaseView {
        public signal void play_requested ();
        public signal void pause_requested ();
        public signal void stop_requested ();
        public signal void previous_requested ();
        public signal void next_requested ();
        public signal void seek_requested (int64 position_ns);

        private Button previous_button;
        private Button play_button;
        private Button pause_button;
        private Button stop_button;
        private Button next_button;

        private Scale position_scale;

        private Label position_label;
        private Label status_label;

        private bool updating_position = false;

        public PlayerView () {
            Object (orientation: Orientation.VERTICAL, spacing: 6);

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            Box controls = new Box (Orientation.HORIZONTAL, 6);

            controls.get_style_context ().add_class ("ctrl-box");

            previous_button = new Button.with_label ("Prev");
            play_button = new Button.with_label ("Play");
            pause_button = new Button.with_label ("Pause");
            stop_button = new Button.with_label ("Stop");
            next_button = new Button.with_label ("Next");

            controls.append (previous_button);
            controls.append (play_button);
            controls.append (pause_button);
            controls.append (stop_button);
            controls.append (next_button);

            append (controls);

            Adjustment adjustment = new Adjustment (0, 0, 1, 1, 10, 0);

            position_scale = new Scale (Orientation.HORIZONTAL, adjustment);

            position_scale.hexpand = true;
            position_scale.get_style_context ().add_class ("position");

            append (position_scale);

            position_label = new Label ("0:00 / 0:00");
            append (position_label);

            status_label = new Label ("Stopped");
            append (status_label);
        }

        private void connect_signals () {
            play_button.clicked.connect (() => play_requested());

            pause_button.clicked.connect (() => pause_requested());

            stop_button.clicked.connect (() => stop_requested());

            previous_button.clicked.connect (() => previous_requested());

            next_button.clicked.connect (() => next_requested());

            position_scale.value_changed.connect (() => seek_change());
        }

        public void set_status (string text) {
            status_label.set_text (text);
        }

        public void set_position (int64 position_ns, int64 duration_ns) {
            double position = (double) position_ns / 1e9;
            double duration = (double) duration_ns / 1e9;

            updating_position = true;

            Adjustment adjustment = position_scale.get_adjustment ();

            if (adjustment.get_upper () != duration) {
                Adjustment new_adjustment = new Adjustment (0, 0, duration, 1, 10, 0);

                position_scale.set_adjustment (new_adjustment);
            }

            position_scale.set_value (position);

            position_label.set_text (StringUtils.format_time (position) + " / " + StringUtils.format_time (duration));

            updating_position = false;
        }

        public void reset_position () {
            updating_position = true;

            position_scale.set_value (0);

            position_label.set_text ("0:00 / 0:00");

            updating_position = false;
        }

        private void seek_change() {
            if (updating_position) {
                return;
            }

            double seconds = position_scale.get_value ();

            int64 position_ns = (int64) (seconds * 1000000000.0);

            seek_requested (position_ns);
        }
    }
}
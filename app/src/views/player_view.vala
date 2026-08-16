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

using PiPod.Core.Utils;
using PiPod.Core.Models;

namespace PiPod.Views {
    public class PlayerView : BaseView {
        /*
         * -------------------------------------------------------------
         * Playback signals
         * -------------------------------------------------------------
         */

        public signal void play_requested ();
        public signal void pause_requested ();
        public signal void stop_requested ();

        public signal void previous_requested ();
        public signal void next_requested ();

        public signal void seek_requested (
            int64 position_ns
        );

        /*
         * -------------------------------------------------------------
         * Playback mode signals
         * -------------------------------------------------------------
         */

        public signal void shuffle_requested ();
        public signal void repeat_requested ();

        /*
         * -------------------------------------------------------------
         * Volume
         * -------------------------------------------------------------
         */

        public signal void volume_changed (
            double volume
        );

        /*
         * -------------------------------------------------------------
         * Main playback controls
         * -------------------------------------------------------------
         */

        private Button shuffle_button;
        private Button repeat_button;

        private Button previous_button;
        private Button play_button;
        private Button pause_button;
        private Button stop_button;
        private Button next_button;

        private Button volume_button;

        /*
         * -------------------------------------------------------------
         * Volume popover
         * -------------------------------------------------------------
         */

        private Popover volume_popover;
        private Scale volume_scale;

        /*
         * -------------------------------------------------------------
         * Position controls
         * -------------------------------------------------------------
         */

        private Scale position_scale;

        private Label position_label;
        private Label duration_label;

        /*
         * -------------------------------------------------------------
         * State
         * -------------------------------------------------------------
         */

        private bool updating_position = false;
        private bool updating_volume = false;

        public PlayerView () {
            Object (
                orientation: Orientation.VERTICAL,
                spacing: 6
            );

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Playback controls
             * ---------------------------------------------------------
             *
             *   Shuffle Repeat Previous Play Pause Stop Next Volume
             *
             * Everything lives on one horizontal control row.
             * ---------------------------------------------------------
             */

            var controls =
                new Box (
                    Orientation.HORIZONTAL,
                    6
                );

            controls.halign =
                Align.CENTER;

            /*
             * ---------------------------------------------------------
             * Shuffle
             * ---------------------------------------------------------
             */

            shuffle_button =
                create_icon_button (
                    "media-playlist-shuffle-symbolic",
                    "Shuffle"
                );

            shuffle_button.add_css_class (
                "flat"
            );

            shuffle_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Repeat
             * ---------------------------------------------------------
             */

            repeat_button =
                create_icon_button (
                    "media-playlist-repeat-symbolic",
                    "Repeat"
                );

            repeat_button.add_css_class (
                "flat"
            );

            repeat_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Previous
             * ---------------------------------------------------------
             */

            previous_button =
                create_icon_button (
                    "media-skip-backward-symbolic",
                    "Previous song"
                );

            previous_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Play
             * ---------------------------------------------------------
             */

            play_button =
                create_icon_button (
                    "media-playback-start-symbolic",
                    "Play"
                );

            play_button.add_css_class (
                "suggested-action"
            );

            play_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Pause
             * ---------------------------------------------------------
             */

            pause_button =
                create_icon_button (
                    "media-playback-pause-symbolic",
                    "Pause"
                );

            pause_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Stop
             * ---------------------------------------------------------
             */

            stop_button =
                create_icon_button (
                    "media-playback-stop-symbolic",
                    "Stop"
                );

            stop_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Next
             * ---------------------------------------------------------
             */

            next_button =
                create_icon_button (
                    "media-skip-forward-symbolic",
                    "Next song"
                );

            next_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Volume
             * ---------------------------------------------------------
             */

            volume_button =
                create_icon_button (
                    "audio-volume-high-symbolic",
                    "Volume"
                );

            volume_button.add_css_class (
                "flat"
            );

            volume_button.add_css_class (
                "circular"
            );

            /*
             * ---------------------------------------------------------
             * Add controls to the row
             * ---------------------------------------------------------
             */

            controls.append (
                shuffle_button
            );

            controls.append (
                repeat_button
            );

            controls.append (
                previous_button
            );

            controls.append (
                play_button
            );

            controls.append (
                pause_button
            );

            controls.append (
                stop_button
            );

            controls.append (
                next_button
            );

            controls.append (
                volume_button
            );

            append (
                controls
            );

            /*
             * ---------------------------------------------------------
             * Position / scrubber
             * ---------------------------------------------------------
             *
             *       0:42 ─────────●───────── 3:27
             * ---------------------------------------------------------
             */

            var position_box =
                new Box (
                    Orientation.HORIZONTAL,
                    8
                );

            position_box.hexpand =
                true;

            position_box.margin_start =
                12;

            position_box.margin_end =
                12;

            position_box.margin_top =
                4;

            position_box.margin_bottom =
                4;

            /*
             * Elapsed time
             */

            position_label =
                new Label (
                    "0:00"
                );

            position_label.width_chars =
                5;

            position_label.xalign =
                1.0f;

            position_label.add_css_class (
                "dim-label"
            );

            /*
             * Seek bar
             */

            Adjustment adjustment =
                new Adjustment (
                    0,
                    0,
                    1,
                    1,
                    10,
                    0
                );

            position_scale =
                new Scale (
                    Orientation.HORIZONTAL,
                    adjustment
                );

            position_scale.hexpand =
                true;

            position_scale.draw_value =
                false;

            /*
             * Duration
             */

            duration_label =
                new Label (
                    "0:00"
                );

            duration_label.width_chars =
                5;

            duration_label.xalign =
                0.0f;

            duration_label.add_css_class (
                "dim-label"
            );

            position_box.append (
                position_label
            );

            position_box.append (
                position_scale
            );

            position_box.append (
                duration_label
            );

            append (
                position_box
            );

            /*
             * ---------------------------------------------------------
             * Volume popover
             * ---------------------------------------------------------
             */

            build_volume_popover ();
        }

        private void build_volume_popover () {
            /*
             * ---------------------------------------------------------
             * Popover
             * ---------------------------------------------------------
             */

            volume_popover =
                new Popover ();

            volume_popover.has_arrow =
                true;

            volume_popover.position =
                PositionType.TOP;

            /*
             * ---------------------------------------------------------
             * Volume container
             * ---------------------------------------------------------
             */

            var volume_box =
                new Box (
                    Orientation.VERTICAL,
                    6
                );

            volume_box.margin_top =
                12;

            volume_box.margin_bottom =
                12;

            volume_box.margin_start =
                12;

            volume_box.margin_end =
                12;

            /*
             * ---------------------------------------------------------
             * Volume label
             * ---------------------------------------------------------
             */

            var volume_label =
                new Label (
                    "Volume"
                );

            volume_label.halign =
                Align.START;

            volume_label.add_css_class (
                "heading"
            );

            volume_box.append (
                volume_label
            );

            /*
             * ---------------------------------------------------------
             * Volume slider
             * ---------------------------------------------------------
             */

            volume_scale =
                new Scale (
                    Orientation.HORIZONTAL,
                    new Adjustment (
                        1.0,
                        0.0,
                        1.0,
                        0.01,
                        0.1,
                        0
                    )
                );

            volume_scale.width_request =
                180;

            volume_scale.draw_value =
                true;

            volume_box.append (
                volume_scale
            );

            volume_popover.set_child (
                volume_box
            );

            /*
             * Attach the popover to the volume button.
             */

            volume_popover.set_parent (
                volume_button
            );
        }

        /*
         * -------------------------------------------------------------
         * Button helper
         * -------------------------------------------------------------
         */

        private Button create_icon_button (string icon_name, string tooltip) {
            var button =
                new Button ();

            button.icon_name =
                icon_name;

            button.tooltip_text =
                tooltip;

            return button;
        }

        /*
         * -------------------------------------------------------------
         * Signal connections
         * -------------------------------------------------------------
         */

        private void connect_signals () {
            /*
             * ---------------------------------------------------------
             * Playback
             * ---------------------------------------------------------
             */

            play_button.clicked.connect (() => {
                play_requested ();
            });

            pause_button.clicked.connect (() => {
                pause_requested ();
            });

            stop_button.clicked.connect (() => {
                stop_requested ();
            });

            previous_button.clicked.connect (() => {
                previous_requested ();
            });

            next_button.clicked.connect (() => {
                next_requested ();
            });

            /*
             * ---------------------------------------------------------
             * Shuffle
             * ---------------------------------------------------------
             */

            shuffle_button.clicked.connect (() => {
                shuffle_requested ();
            });

            /*
             * ---------------------------------------------------------
             * Repeat
             * ---------------------------------------------------------
             */

            repeat_button.clicked.connect (() => {
                repeat_requested ();
            });

            /*
             * ---------------------------------------------------------
             * Volume
             * ---------------------------------------------------------
             */

            volume_button.clicked.connect (() => {
                volume_popover.popup ();
            });

            volume_scale.value_changed.connect (() => {
                if (updating_volume) {
                    return;
                }

                volume_changed (
                    volume_scale.get_value ()
                );
            });

            /*
             * ---------------------------------------------------------
             * Seeking
             * ---------------------------------------------------------
             */

            position_scale.value_changed.connect (() => {
                seek_change ();
            });
        }

        /*
         * -------------------------------------------------------------
         * Compatibility
         * -------------------------------------------------------------
         */

        public void set_status (
            string text
        ) {
            /*
             * Intentionally empty.
             *
             * Kept for compatibility with the existing controller.
             */
        }

        /*
         * -------------------------------------------------------------
         * Position
         * -------------------------------------------------------------
         */

        public void set_position (
            int64 position_ns,
            int64 duration_ns
        ) {
            double position =
                (double) position_ns / 1e9;

            double duration =
                (double) duration_ns / 1e9;

            updating_position =
                true;

            /*
             * Update the seek bar range when the duration changes.
             */

            Adjustment adjustment =
                position_scale.get_adjustment ();

            if (
                adjustment.get_upper () !=
                duration
            ) {
                Adjustment new_adjustment =
                    new Adjustment (
                        0,
                        0,
                        duration,
                        1,
                        10,
                        0
                    );

                position_scale.set_adjustment (
                    new_adjustment
                );
            }

            position_scale.set_value (
                position
            );

            /*
             * Update elapsed time.
             */

            position_label.set_text (
                StringUtils.format_time (
                    position
                )
            );

            /*
             * Update duration.
             */

            duration_label.set_text (
                StringUtils.format_time (
                    duration
                )
            );

            updating_position =
                false;
        }

        /*
         * -------------------------------------------------------------
         * Reset position
         * -------------------------------------------------------------
         */

        public void reset_position () {
            updating_position =
                true;

            position_scale.set_value (
                0
            );

            position_label.set_text (
                "0:00"
            );

            duration_label.set_text (
                "0:00"
            );

            updating_position =
                false;
        }

        /*
         * -------------------------------------------------------------
         * Volume
         * -------------------------------------------------------------
         *
         * Allows the controller to synchronize the volume without
         * causing volume_changed() to fire.
         * -------------------------------------------------------------
         */

        public void set_volume (
            double volume
        ) {
            updating_volume =
                true;

            volume_scale.set_value (
                volume
            );

            updating_volume =
                false;
        }

        public void set_shuffle_active (
            bool active
        ) {
            if (active) {
                shuffle_button.add_css_class (
                    "accent"
                );
            } else {
                shuffle_button.remove_css_class (
                    "accent"
                );
            }

            shuffle_button.tooltip_text =
                active
                    ? "Shuffle: On"
                    : "Shuffle: Off";
        }

        public void set_repeat_active (
            bool active
        ) {
            if (active) {
                repeat_button.add_css_class (
                    "accent"
                );
            } else {
                repeat_button.remove_css_class (
                    "accent"
                );
            }
        
            repeat_button.tooltip_text =
                active
                    ? "Repeat: On"
                    : "Repeat: Off";
        }

        /*
         * -------------------------------------------------------------
         * Seeking
         * -------------------------------------------------------------
         */

        private void seek_change () {
            if (updating_position) {
                return;
            }

            double seconds =
                position_scale.get_value ();

            int64 position_ns =
                (int64) (
                    seconds *
                    1000000000.0
                );

            seek_requested (
                position_ns
            );
        }
    }
}
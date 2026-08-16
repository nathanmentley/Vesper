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

namespace PiPod.Components {
    public class PlaylistEntry : Box {
        public signal void selected (int index);
        public signal void move_up_request (int index);
        public signal void move_down_request (int index);
        public signal void delete_request (int index);

        private Song song;
        private int index;

        private Label title_label;
        private Button select_button;
        private Button up_button;
        private Button down_button;
        private Button delete_button;

        public PlaylistEntry (Song song, int index, bool is_current) {
            Object (orientation: Orientation.HORIZONTAL, spacing: 8);

            this.song = song;

            select_button = new Button.with_label ("Select");
            up_button = new Button.with_label ("Up");
            down_button = new Button.with_label ("Down");
            delete_button = new Button.with_label ("Delete");

            title_label = new Label (song.title);

            if (is_current) {
                title_label.add_css_class ("current-song");
            }

            append (title_label);
            append (select_button);
            append (up_button);
            append (down_button);
            append (delete_button);

            select_button.clicked.connect (() => selected (index));
            up_button.clicked.connect (() => move_up_request (index));
            down_button.clicked.connect (() => move_down_request (index));
            delete_button.clicked.connect (() => delete_request (index));
        }
    }
}
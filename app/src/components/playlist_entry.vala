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
using Adw;

using PiPod.Core.Models;

namespace PiPod.Components {
    public class PlaylistEntry : Adw.ActionRow {
        public signal void selected (int index);
        public signal void move_up_request (int index);
        public signal void move_down_request (int index);
        public signal void delete_request (int index);

        private Song song;
        private int index;

        private Button up_button;
        private Button down_button;
        private Button delete_button;

        public PlaylistEntry (
            Song song,
            int index,
            bool is_current,
            int playlist_length
        ) {
            Object ();

            this.song = song;
            this.index = index;

            /*
             * ---------------------------------------------------------
             * Song information
             * ---------------------------------------------------------
             */

            title = song.title;
            title_lines = 1;

            if (song.album != null) {
                subtitle = song.album.name;
                subtitle_lines = 1;
            }

            /*
             * ---------------------------------------------------------
             * Current song indicator
             * ---------------------------------------------------------
             */

            if (is_current) {
                add_css_class ("accent");

                var playing_icon =
                    new Image.from_icon_name (
                        "media-playback-start-symbolic"
                    );

                playing_icon.tooltip_text =
                    "Currently playing";

                add_prefix (playing_icon);
            }

            /*
             * ---------------------------------------------------------
             * Selecting the song
             * ---------------------------------------------------------
             *
             * The entire row is the selection target.
             */

            activatable = true;

            activated.connect (() => {
                selected (this.index);
            });

            /*
             * ---------------------------------------------------------
             * Move up
             * ---------------------------------------------------------
             */

            up_button = new Button ();

            up_button.icon_name = "go-up-symbolic";
            up_button.tooltip_text = "Move up";

            up_button.add_css_class ("flat");

            up_button.sensitive = index > 0;

            up_button.clicked.connect (() => {
                move_up_request (this.index);
            });

            add_suffix (up_button);

            /*
             * ---------------------------------------------------------
             * Move down
             * ---------------------------------------------------------
             */

            down_button = new Button ();

            down_button.icon_name = "go-down-symbolic";
            down_button.tooltip_text = "Move down";

            down_button.add_css_class ("flat");

            down_button.sensitive =
                index < playlist_length - 1;

            down_button.clicked.connect (() => {
                move_down_request (this.index);
            });

            add_suffix (down_button);

            /*
             * ---------------------------------------------------------
             * Delete
             * ---------------------------------------------------------
             */

            delete_button = new Button ();

            delete_button.icon_name =
                "user-trash-symbolic";

            delete_button.tooltip_text =
                "Remove from playlist";

            delete_button.add_css_class ("flat");
            delete_button.add_css_class (
                "destructive-action"
            );

            delete_button.clicked.connect (() => {
                delete_request (this.index);
            });

            add_suffix (delete_button);
        }
    }
}
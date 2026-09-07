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

using Vesper.Core.Models;

namespace Vesper.App.Components {
    public class SongRow : Box {
        public Song song { get; construct; }

        public signal void selected (Song song);
        public signal void add_to_playlist_requested (Song song);

        private Button play_button;

        public SongRow (Song song) {
            Object (
                orientation: Orientation.HORIZONTAL,
                spacing: 0,
                song: song
            );

            build_ui ();

            connect_signals ();
        }

        private void build_ui () {
            hexpand = true;

            tooltip_text = song.title;

            play_button = new Button ();
            play_button.hexpand = true;
            play_button.halign = Align.FILL;
            play_button.has_frame = false;

            Box row = new Box (Orientation.HORIZONTAL, 12);
            row.set_margin_top (8);
            row.set_margin_bottom (8);
            row.set_margin_start (12);
            row.set_margin_end (12);

            Image icon = new Image.from_icon_name ("media-playback-start-symbolic");
            icon.pixel_size = 20;

            Label label = new Label (song.title);
            label.halign = Align.START;
            label.hexpand = true;
            label.ellipsize = Pango.EllipsizeMode.END;

            row.append (icon);
            row.append (label);
            play_button.set_child (row);

            append (play_button);

            var add_button = new Button ();
            add_button.icon_name = "list-add-symbolic";
            add_button.tooltip_text = "Add to playlist";
            add_button.add_css_class ("flat");
            add_button.clicked.connect (() => add_to_playlist_requested (song));
            append (add_button);
        }

        private void connect_signals () {
            play_button.clicked.connect (() => selected (song));
        }
    }
}
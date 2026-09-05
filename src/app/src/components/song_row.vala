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
    public class SongRow : Button {
        public Song song { get; construct; }

        public signal void selected (Song song);

        public SongRow (Song song) {
            Object (song: song);

            build_ui ();

            connect_signals ();
        }

        private void build_ui () {
            halign = Align.FILL;
            hexpand = true;
            has_frame = false;

            tooltip_text = song.title;

            Box row = new Box (Orientation.HORIZONTAL, 12);
            row.set_margin_top (8);
            row.set_margin_bottom (8);
            row.set_margin_start (12);
            row.set_margin_end (12);

            Image icon = new Image.from_icon_name ("audio-x-generic-symbolic");
            icon.pixel_size = 20;

            Label label = new Label (song.title);
            label.halign = Align.START;
            label.hexpand = true;
            label.ellipsize = Pango.EllipsizeMode.END;

            Image add_icon = new Image.from_icon_name ("list-add-symbolic");
            add_icon.add_css_class ("dim-label");

            row.append (icon);
            row.append (label);
            row.append (add_icon);

            set_child (row);
        }

        private void connect_signals () {
            clicked.connect (() => selected (song));
        }
    }
}
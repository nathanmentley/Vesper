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

using PiPod.Core.Models;

namespace PiPod.App.Components {
    public class AlbumRow : Button {
        public Album album { get; construct; }

        public signal void selected (Album album);

        public AlbumRow (Album album) {
            Object (album: album);

            build_ui ();

            connect_signals ();
        }

        private void build_ui () {
            halign = Align.FILL;
            hexpand = true;
            has_frame = false;

            tooltip_text = album.display_name ();

            Box row = new Box (Orientation.HORIZONTAL, 12);
            row.set_margin_top (8);
            row.set_margin_bottom (8);
            row.set_margin_start (12);
            row.set_margin_end (12);

            Image icon = new Image.from_icon_name ("media-optical-audio-symbolic");
            icon.pixel_size = 20;

            Label label = new Label (album.display_name ());
            label.halign = Align.START;
            label.hexpand = true;
            label.ellipsize = Pango.EllipsizeMode.END;

            Image arrow = new Image.from_icon_name ("go-next-symbolic");
            arrow.add_css_class ("dim-label");

            row.append (icon);
            row.append (label);
            row.append (arrow);

            set_child (row);
        }

        private void connect_signals () {
            clicked.connect (() => selected (album));
        }
    }
}
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
    public class NowPlayingView : BaseView {
        private Image album_art;
        private Label song_label;
        private Label album_label;

        public NowPlayingView () {
            Object (orientation: Orientation.VERTICAL, spacing: 6);

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            Box box = new Box (Orientation.VERTICAL, 4);

            box.get_style_context ().add_class ("art-box");

            album_art = new Image ();
            album_art.set_pixel_size (260);
            album_art.get_style_context ().add_class ("album-art");
            box.append (album_art);

            song_label = new Label ("No song selected");
            song_label.halign = Align.START;
            song_label.get_style_context ().add_class ("meta-label");
            box.append (song_label);

            album_label = new Label ("No album selected");
            album_label.halign = Align.START;
            album_label.get_style_context ().add_class ("meta-label");
            box.append (album_label);

            append (box);
        }

        private void connect_signals () {

        }

        public void set_song (Song song) {
            song_label.set_text (song.title);
        }

        public void set_album (Album album) {
            album_label.set_text (album.display_name ());
        }

        public void set_album_art (Bytes? data) {
            if (data == null) {
                album_art.set_from_icon_name ("audio-x-generic");

                return;
            }

            try {
                Gdk.PixbufLoader loader = new Gdk.PixbufLoader ();

                loader.write (data.get_data ());
                loader.close ();

                var pixbuf = loader.get_pixbuf ();

                if (pixbuf != null) {
                    album_art.set_from_pixbuf (pixbuf);
                } else {
                    album_art.set_from_icon_name ("audio-x-generic");
                }
            } catch (GLib.Error e) {
                album_art.set_from_icon_name ("audio-x-generic");
            }
        }
    }
}
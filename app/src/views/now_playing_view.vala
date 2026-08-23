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
using Gdk;

using PiPod.Core.Models;

using PiPod.App.Utils;

namespace PiPod.App.Views {
    public class NowPlayingView : BaseView {
        private Image album_art;

        private Label song_label;
        private Label album_label;

        private Gtk.Box content;

        public NowPlayingView () {
            Object (
                orientation: Orientation.VERTICAL,
                spacing: 0
            );

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Main content
             * ---------------------------------------------------------
             */

            content =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    12
                );

            content.halign =
                Align.CENTER;

            content.valign =
                Align.CENTER;

            content.vexpand = true;

            /*
             * ---------------------------------------------------------
             * Album artwork
             * ---------------------------------------------------------
             */

            album_art =
                new Image ();

            album_art.set_pixel_size (
                280
            );

            album_art.halign =
                Align.CENTER;

            album_art.valign =
                Align.CENTER;

            album_art.add_css_class (
                "album-art"
            );

            /*
             * Give the image a default placeholder.
             */

            album_art.set_from_icon_name (
                "audio-x-generic-symbolic"
            );

            content.append (
                album_art
            );

            /*
             * ---------------------------------------------------------
             * Song title
             * ---------------------------------------------------------
             */

            song_label =
                new Label (
                    "No song selected"
                );

            song_label.halign =
                Align.CENTER;

            song_label.justify =
                Justification.CENTER;

            song_label.wrap = true;

            song_label.max_width_chars = 40;

            song_label.add_css_class (
                "title-2"
            );

            content.append (
                song_label
            );

            /*
             * ---------------------------------------------------------
             * Album
             * ---------------------------------------------------------
             */

            album_label =
                new Label (
                    "No album selected"
                );

            album_label.halign =
                Align.CENTER;

            album_label.justify =
                Justification.CENTER;

            album_label.wrap = true;

            album_label.max_width_chars = 40;

            album_label.add_css_class (
                "dim-label"
            );

            content.append (
                album_label
            );

            /*
             * ---------------------------------------------------------
             * Clamp
             * ---------------------------------------------------------
             *
             * Keeps the player from becoming ridiculously wide on
             * large desktop windows while still allowing it to shrink
             * nicely on small screens.
             */

            var clamp =
                new Adw.Clamp ();

            clamp.maximum_size = 500;
            clamp.tightening_threshold = 400;

            clamp.halign =
                Align.CENTER;

            clamp.vexpand = true;

            clamp.set_child (
                content
            );

            append (
                clamp
            );
        }

        private void connect_signals () {
        }

        /*
         * -------------------------------------------------------------
         * Song
         * -------------------------------------------------------------
         */

        public void set_song (Song song) {
            song_label.set_text (
                song.title
            );

            if (song.album != null) {
                set_album (
                    song.album
                );
            }
        }

        /*
         * -------------------------------------------------------------
         * Album
         * -------------------------------------------------------------
         */

        public void set_album (Album album) {
            album_label.set_text (
                album.display_name ()
            );
        }

        /*
         * -------------------------------------------------------------
         * Album artwork
         * -------------------------------------------------------------
         */

        public void set_album_art (Bytes? data) {
            if (data == null) {
                set_default_album_art ();

                return;
            }

            try {
                var loader =
                    new Gdk.PixbufLoader ();

                loader.write (
                    data.get_data ()
                );

                loader.close ();

                var pixbuf =
                    loader.get_pixbuf ();

                if (pixbuf != null) {
                    album_art.set_from_pixbuf (
                        pixbuf
                    );
                } else {
                    set_default_album_art ();
                }
            } catch (GLib.Error e) {
                set_default_album_art ();
            }
        }

        private void set_default_album_art () {
            album_art.set_from_icon_name (
                "audio-x-generic-symbolic"
            );
        }
    }
}
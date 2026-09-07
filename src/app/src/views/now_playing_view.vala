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

using Gee;
using Gtk;
using Adw;
using Gdk;

using Vesper.Core.Models;

namespace Vesper.App.Views {

    public class NowPlayingView : BaseView {

        private Adw.BreakpointBin breakpoint_bin;
        private Gtk.Stack responsive_stack;

        /*
         * Desktop Now Playing widgets.
         */
        private Gtk.Image desktop_album_art;
        private Gtk.Label desktop_song_label;
        private Gtk.Label desktop_artist_label;
        private Gtk.Label desktop_album_label;

        /*
         * Mobile Now Playing widgets.
         */
        private Gtk.Image mobile_album_art;
        private Gtk.Label mobile_song_label;
        private Gtk.Label mobile_artist_label;
        private Gtk.Label mobile_album_label;

        /*
         * Desktop queue.
         */
        private Gtk.ListBox desktop_queue_list;
        private Gtk.Button desktop_queue_clear_button;

        /*
         * Mobile queue.
         */
        private Gtk.ListBox mobile_queue_list;
        private Gtk.Button mobile_queue_clear_button;

        private Adw.ViewStack mobile_stack;
        private Adw.ViewSwitcher mobile_view_switcher;

        public signal void queue_song_selected (int index);

        public signal void queue_song_move_request (
            int from_index,
            int to_index
        );

        public signal void queue_song_delete_request (
            int index
        );

        public signal void queue_clear_request ();

        public NowPlayingView (Gtk.Window parent_window) {
            base (parent_window);

            build_ui ();
        }

        private void build_ui () {
            breakpoint_bin =
                new Adw.BreakpointBin ();

            breakpoint_bin.hexpand = true;
            breakpoint_bin.vexpand = true;

            responsive_stack =
                new Gtk.Stack ();

            responsive_stack.hexpand = true;
            responsive_stack.vexpand = true;

            responsive_stack.add_named (
                build_desktop_view (),
                "desktop"
            );

            responsive_stack.add_named (
                build_mobile_view (),
                "mobile"
            );

            responsive_stack.set_visible_child_name (
                "desktop"
            );

            breakpoint_bin.set_child (
                responsive_stack
            );

            /*
             * Switch to the mobile layout when the view becomes
             * narrower than 700 pixels.
             */
            Adw.Breakpoint breakpoint =
                new Adw.Breakpoint (
                    Adw.BreakpointCondition.parse (
                        "max-width: 699px"
                    )
                );

            breakpoint.add_setter (
                responsive_stack,
                "visible-child-name",
                "mobile"
            );

            breakpoint_bin.add_breakpoint (
                breakpoint
            );

            append (
                breakpoint_bin
            );
        }

        private Gtk.Widget build_desktop_view () {
            Gtk.Paned paned =
                new Gtk.Paned (
                    Gtk.Orientation.HORIZONTAL
                );

            paned.hexpand = true;
            paned.vexpand = true;

            paned.set_start_child (
                build_desktop_now_playing_page ()
            );

            paned.set_end_child (
                build_desktop_queue_page ()
            );

            paned.set_resize_start_child (
                true
            );

            paned.set_resize_end_child (
                true
            );

            /*
             * Allow both sides to shrink when the available
             * width becomes constrained.
             */
            paned.set_shrink_start_child (
                true
            );

            paned.set_shrink_end_child (
                true
            );

            return paned;
        }

        private Gtk.Widget build_mobile_view () {
            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    0
                );

            box.hexpand = true;
            box.vexpand = true;

            mobile_view_switcher =
                new Adw.ViewSwitcher ();

            mobile_view_switcher.halign =
                Gtk.Align.CENTER;

            mobile_view_switcher.hexpand = true;

            mobile_view_switcher.margin_top = 8;
            mobile_view_switcher.margin_bottom = 8;

            mobile_stack =
                new Adw.ViewStack ();

            mobile_stack.hexpand = true;
            mobile_stack.vexpand = true;

            mobile_stack.add_titled (
                build_mobile_now_playing_page (),
                "now-playing",
                "Now Playing"
            );

            mobile_stack.add_titled (
                build_mobile_queue_page (),
                "queue",
                "Queue"
            );

            mobile_view_switcher.stack =
                mobile_stack;

            box.append (
                mobile_view_switcher
            );

            box.append (
                mobile_stack
            );

            return box;
        }

        private Gtk.Widget build_desktop_now_playing_page () {
            Gtk.Box outer_box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    0
                );

            outer_box.hexpand = true;
            outer_box.vexpand = true;

            Gtk.ScrolledWindow scrolled =
                new Gtk.ScrolledWindow ();

            scrolled.hexpand = true;
            scrolled.vexpand = true;

            scrolled.hscrollbar_policy =
                Gtk.PolicyType.NEVER;

            scrolled.vscrollbar_policy =
                Gtk.PolicyType.AUTOMATIC;

            Adw.Clamp clamp =
                new Adw.Clamp ();

            clamp.maximum_size = 500;
            clamp.tightening_threshold = 400;

            clamp.margin_start = 24;
            clamp.margin_end = 24;
            clamp.margin_top = 32;
            clamp.margin_bottom = 32;

            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    12
                );

            box.halign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;

            desktop_album_art =
                new Gtk.Image ();

            desktop_album_art.set_pixel_size (
                280
            );

            desktop_album_art.halign =
                Gtk.Align.CENTER;

            desktop_album_art.valign =
                Gtk.Align.CENTER;

            set_default_album_art (
                desktop_album_art
            );

            desktop_song_label =
                new Gtk.Label ("");

            desktop_song_label.halign =
                Gtk.Align.CENTER;

            desktop_song_label.hexpand = true;

            desktop_song_label.wrap = true;

            desktop_song_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            desktop_song_label.justify =
                Gtk.Justification.CENTER;

            desktop_song_label.add_css_class (
                "title-2"
            );

            desktop_artist_label =
                new Gtk.Label ("");

            desktop_artist_label.halign =
                Gtk.Align.CENTER;

            desktop_artist_label.hexpand = true;

            desktop_artist_label.wrap = true;

            desktop_artist_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            desktop_artist_label.justify =
                Gtk.Justification.CENTER;

            desktop_artist_label.add_css_class (
                "subtitle"
            );

            desktop_album_label =
                new Gtk.Label ("");

            desktop_album_label.halign =
                Gtk.Align.CENTER;

            desktop_album_label.hexpand = true;

            desktop_album_label.wrap = true;

            desktop_album_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            desktop_album_label.justify =
                Gtk.Justification.CENTER;

            desktop_album_label.add_css_class (
                "dim-label"
            );

            box.append (
                desktop_album_art
            );

            box.append (
                desktop_song_label
            );

            box.append (
                desktop_artist_label
            );

            box.append (
                desktop_album_label
            );

            clamp.set_child (
                box
            );

            scrolled.set_child (
                clamp
            );

            outer_box.append (
                scrolled
            );

            return outer_box;
        }

        private Gtk.Widget build_mobile_now_playing_page () {
            Gtk.Box outer_box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    0
                );

            outer_box.hexpand = true;
            outer_box.vexpand = true;

            Gtk.ScrolledWindow scrolled =
                new Gtk.ScrolledWindow ();

            scrolled.hexpand = true;
            scrolled.vexpand = true;

            scrolled.hscrollbar_policy =
                Gtk.PolicyType.NEVER;

            scrolled.vscrollbar_policy =
                Gtk.PolicyType.AUTOMATIC;

            Adw.Clamp clamp =
                new Adw.Clamp ();

            clamp.maximum_size = 500;
            clamp.tightening_threshold = 400;

            clamp.margin_start = 16;
            clamp.margin_end = 16;
            clamp.margin_top = 24;
            clamp.margin_bottom = 24;

            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    12
                );

            box.halign = Gtk.Align.CENTER;
            box.valign = Gtk.Align.CENTER;

            mobile_album_art =
                new Gtk.Image ();

            /*
             * Keep the artwork comfortably below the available
             * width on narrow phones.
             */
            mobile_album_art.set_pixel_size (
                220
            );

            mobile_album_art.halign =
                Gtk.Align.CENTER;

            mobile_album_art.valign =
                Gtk.Align.CENTER;

            set_default_album_art (
                mobile_album_art
            );

            mobile_song_label =
                new Gtk.Label ("");

            mobile_song_label.halign =
                Gtk.Align.CENTER;

            mobile_song_label.hexpand = true;

            mobile_song_label.wrap = true;

            mobile_song_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            mobile_song_label.justify =
                Gtk.Justification.CENTER;

            mobile_song_label.add_css_class (
                "title-2"
            );

            mobile_artist_label =
                new Gtk.Label ("");

            mobile_artist_label.halign =
                Gtk.Align.CENTER;

            mobile_artist_label.hexpand = true;

            mobile_artist_label.wrap = true;

            mobile_artist_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            mobile_artist_label.justify =
                Gtk.Justification.CENTER;

            mobile_artist_label.add_css_class (
                "subtitle"
            );

            mobile_album_label =
                new Gtk.Label ("");

            mobile_album_label.halign =
                Gtk.Align.CENTER;

            mobile_album_label.hexpand = true;

            mobile_album_label.wrap = true;

            mobile_album_label.wrap_mode =
                Pango.WrapMode.WORD_CHAR;

            mobile_album_label.justify =
                Gtk.Justification.CENTER;

            mobile_album_label.add_css_class (
                "dim-label"
            );

            box.append (
                mobile_album_art
            );

            box.append (
                mobile_song_label
            );

            box.append (
                mobile_artist_label
            );

            box.append (
                mobile_album_label
            );

            clamp.set_child (
                box
            );

            scrolled.set_child (
                clamp
            );

            outer_box.append (
                scrolled
            );

            return outer_box;
        }

        private Gtk.Widget build_desktop_queue_page () {
            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    0
                );

            box.hexpand = true;
            box.vexpand = true;

            Gtk.Box header =
                build_queue_header (
                    out desktop_queue_clear_button
                );

            Gtk.Separator separator =
                new Gtk.Separator (
                    Gtk.Orientation.HORIZONTAL
                );

            desktop_queue_list =
                new Gtk.ListBox ();

            desktop_queue_list.selection_mode =
                Gtk.SelectionMode.NONE;

            desktop_queue_list.hexpand = true;
            desktop_queue_list.vexpand = true;
            desktop_queue_list.show_separators = true;

            connect_queue_activation (
                desktop_queue_list
            );

            Gtk.ScrolledWindow scrolled =
                build_queue_scrolled_window (
                    desktop_queue_list
                );

            box.append (
                header
            );

            box.append (
                separator
            );

            box.append (
                scrolled
            );

            return box;
        }

        private Gtk.Widget build_mobile_queue_page () {
            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    0
                );

            box.hexpand = true;
            box.vexpand = true;

            Gtk.Box header =
                build_queue_header (
                    out mobile_queue_clear_button
                );

            Gtk.Separator separator =
                new Gtk.Separator (
                    Gtk.Orientation.HORIZONTAL
                );

            mobile_queue_list =
                new Gtk.ListBox ();

            mobile_queue_list.selection_mode =
                Gtk.SelectionMode.NONE;

            mobile_queue_list.hexpand = true;
            mobile_queue_list.vexpand = true;
            mobile_queue_list.show_separators = true;

            connect_queue_activation (
                mobile_queue_list
            );

            Gtk.ScrolledWindow scrolled =
                build_queue_scrolled_window (
                    mobile_queue_list
                );

            box.append (
                header
            );

            box.append (
                separator
            );

            box.append (
                scrolled
            );

            return box;
        }

        private Gtk.Box build_queue_header (
            out Gtk.Button clear_button
        ) {
            Gtk.Box header =
                new Gtk.Box (
                    Gtk.Orientation.HORIZONTAL,
                    12
                );

            header.margin_start = 18;
            header.margin_end = 18;
            header.margin_top = 12;
            header.margin_bottom = 12;

            Gtk.Label title =
                new Gtk.Label (
                    "Queue"
                );

            title.halign =
                Gtk.Align.START;

            title.hexpand = true;

            title.add_css_class (
                "title-2"
            );

            clear_button =
                new Gtk.Button.with_label (
                    "Clear"
                );

            clear_button.add_css_class (
                "flat"
            );

            clear_button.clicked.connect (() => {
                queue_clear_request ();
            });

            header.append (
                title
            );

            header.append (
                clear_button
            );

            return header;
        }

        private Gtk.ScrolledWindow build_queue_scrolled_window (
            Gtk.ListBox list
        ) {
            Gtk.ScrolledWindow scrolled =
                new Gtk.ScrolledWindow ();

            scrolled.hexpand = true;
            scrolled.vexpand = true;

            scrolled.hscrollbar_policy =
                Gtk.PolicyType.NEVER;

            scrolled.vscrollbar_policy =
                Gtk.PolicyType.AUTOMATIC;

            scrolled.set_child (
                list
            );

            return scrolled;
        }

        private void connect_queue_activation (
            Gtk.ListBox list
        ) {
            list.row_activated.connect (
                row => {
                    int index =
                        row.get_index ();

                    if (index >= 0) {
                        queue_song_selected (
                            index
                        );
                    }
                }
            );
        }

        public void set_song (
            Song song
        ) {
            desktop_song_label.set_text (
                song.title
            );

            desktop_artist_label.set_text (
                song.artist.name
            );

            mobile_song_label.set_text (
                song.title
            );

            mobile_artist_label.set_text (
                song.artist.name
            );
        }

        public void set_album (
            Album album
        ) {
            desktop_album_label.set_text (
                album.name
            );

            mobile_album_label.set_text (
                album.name
            );
        }

        public void set_album_art (
            GLib.Bytes? bytes
        ) {
            if (bytes == null) {
                set_default_album_art (
                    desktop_album_art
                );

                set_default_album_art (
                    mobile_album_art
                );

                return;
            }

            try {
                Gdk.PixbufLoader loader =
                    new Gdk.PixbufLoader ();

                loader.write (
                    bytes.get_data ()
                );

                loader.close ();

                Gdk.Pixbuf? pixbuf =
                    loader.get_pixbuf ();

                if (pixbuf == null) {
                    set_default_album_art (
                        desktop_album_art
                    );

                    set_default_album_art (
                        mobile_album_art
                    );

                    return;
                }

                Gdk.Texture texture =
                    Gdk.Texture.for_pixbuf (
                        pixbuf
                    );

                desktop_album_art.set_from_paintable (
                    texture
                );

                mobile_album_art.set_from_paintable (
                    texture
                );

            } catch (GLib.Error e) {
                set_default_album_art (
                    desktop_album_art
                );

                set_default_album_art (
                    mobile_album_art
                );
            }
        }

        private void set_default_album_art (
            Gtk.Image image
        ) {
            image.set_from_icon_name (
                "audio-x-generic-symbolic"
            );
        }

        public void set_queue (
            Collection<Song> songs,
            int current_index
        ) {
            rebuild_queue (
                desktop_queue_list,
                songs,
                current_index
            );

            rebuild_queue (
                mobile_queue_list,
                songs,
                current_index
            );

            bool has_songs =
                songs.size > 0;

            desktop_queue_clear_button.sensitive =
                has_songs;

            mobile_queue_clear_button.sensitive =
                has_songs;
        }

        private void rebuild_queue (
            Gtk.ListBox list,
            Collection<Song> songs,
            int current_index
        ) {
            while (true) {
                Gtk.ListBoxRow? row =
                    list.get_row_at_index (
                        0
                    );

                if (row == null) {
                    break;
                }

                list.remove (
                    row
                );
            }

            int index = 0;

            foreach (Song song in songs) {
                Gtk.ListBoxRow row =
                    create_queue_row (
                        song,
                        index,
                        current_index,
                        songs.size
                    );

                list.append (
                    row
                );

                index++;
            }
        }

        public void set_queue_current_index (
            int current_index
        ) {
            update_queue_current_index (
                desktop_queue_list,
                current_index
            );

            update_queue_current_index (
                mobile_queue_list,
                current_index
            );
        }

        private void update_queue_current_index (
            Gtk.ListBox list,
            int current_index
        ) {
            int index = 0;

            Gtk.ListBoxRow? row =
                list.get_row_at_index (
                    0
                );

            while (row != null) {
                update_queue_row_current_state (
                    row,
                    index == current_index
                );

                index++;

                row =
                    list.get_row_at_index (
                        index
                    );
            }
        }

        private Gtk.ListBoxRow create_queue_row (
            Song song,
            int index,
            int current_index,
            int queue_size
        ) {
            Gtk.ListBoxRow row =
                new Gtk.ListBoxRow ();

            Gtk.Box box =
                new Gtk.Box (
                    Gtk.Orientation.HORIZONTAL,
                    12
                );

            box.margin_start = 12;
            box.margin_end = 12;
            box.margin_top = 8;
            box.margin_bottom = 8;

            Gtk.Image current_icon =
                new Gtk.Image ();

            current_icon.set_pixel_size (
                20
            );

            current_icon.valign =
                Gtk.Align.CENTER;

            if (index == current_index) {
                current_icon.set_from_icon_name (
                    "audio-x-generic-symbolic"
                );
            }

            Gtk.Box labels =
                new Gtk.Box (
                    Gtk.Orientation.VERTICAL,
                    2
                );

            labels.hexpand = true;
            labels.valign = Gtk.Align.CENTER;

            Gtk.Label title =
                new Gtk.Label (
                    song.title
                );

            title.halign =
                Gtk.Align.START;

            title.hexpand = true;

            title.ellipsize =
                Pango.EllipsizeMode.END;

            title.max_width_chars = 40;

            Gtk.Label subtitle =
                new Gtk.Label (
                    song.album.name
                );

            subtitle.halign =
                Gtk.Align.START;

            subtitle.hexpand = true;

            subtitle.ellipsize =
                Pango.EllipsizeMode.END;

            subtitle.max_width_chars = 40;

            subtitle.add_css_class (
                "dim-label"
            );

            labels.append (
                title
            );

            labels.append (
                subtitle
            );

            Gtk.Box actions =
                new Gtk.Box (
                    Gtk.Orientation.HORIZONTAL,
                    0
                );

            actions.valign =
                Gtk.Align.CENTER;

            Gtk.Button move_up =
                new Gtk.Button ();

            move_up.icon_name =
                "go-up-symbolic";

            move_up.tooltip_text =
                "Move up";

            move_up.add_css_class (
                "flat"
            );

            Gtk.Button move_down =
                new Gtk.Button ();

            move_down.icon_name =
                "go-down-symbolic";

            move_down.tooltip_text =
                "Move down";

            move_down.add_css_class (
                "flat"
            );

            Gtk.Button remove =
                new Gtk.Button ();

            remove.icon_name =
                "user-trash-symbolic";

            remove.tooltip_text =
                "Remove from queue";

            remove.add_css_class (
                "flat"
            );

            move_up.sensitive =
                index > 0;

            move_down.sensitive =
                index < queue_size - 1;

            move_up.clicked.connect (() => {
                queue_song_move_request (
                    index,
                    index - 1
                );
            });

            move_down.clicked.connect (() => {
                queue_song_move_request (
                    index,
                    index + 1
                );
            });

            remove.clicked.connect (() => {
                queue_song_delete_request (
                    index
                );
            });

            actions.append (
                move_up
            );

            actions.append (
                move_down
            );

            actions.append (
                remove
            );

            box.append (
                current_icon
            );

            box.append (
                labels
            );

            box.append (
                actions
            );

            row.set_child (
                box
            );

            update_queue_row_current_state (
                row,
                index == current_index
            );

            return row;
        }

        private void update_queue_row_current_state (
            Gtk.ListBoxRow row,
            bool current
        ) {
            if (current) {
                row.add_css_class (
                    "selected"
                );
            } else {
                row.remove_css_class (
                    "selected"
                );
            }

            Gtk.Box? box =
                row.get_child () as Gtk.Box;

            if (box == null) {
                return;
            }

            Gtk.Widget? child =
                box.get_first_child ();

            if (child is Gtk.Image) {
                Gtk.Image icon =
                    (Gtk.Image) child;

                if (current) {
                    icon.set_from_icon_name (
                        "audio-x-generic-symbolic"
                    );
                } else {
                    icon.clear ();
                }
            }
        }
    }
}
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

using Vesper.Core.Models;

using Vesper.App.Components;

namespace Vesper.App.Views {
    public class BrowserView : BaseView {
        /*
         * -------------------------------------------------------------
         * Desktop lists
         * -------------------------------------------------------------
         */

        private ListBox desktop_artist_list;
        private ListBox desktop_album_list;
        private ListBox desktop_song_list;

        /*
         * -------------------------------------------------------------
         * Mobile lists
         * -------------------------------------------------------------
         */

        private ListBox mobile_artist_list;
        private ListBox mobile_album_list;
        private ListBox mobile_song_list;

        /*
         * -------------------------------------------------------------
         * Layouts
         * -------------------------------------------------------------
         */

        private Gtk.Box desktop_view;
        private Adw.NavigationView nav_view;

        /*
         * -------------------------------------------------------------
         * Data
         * -------------------------------------------------------------
         *
         * Keep the current data around so either presentation can
         * be populated from the same state.
         */

        private Artist[] artists = {};
        private Album[] albums = {};
        private Song[] songs = {};

        /*
         * Currently selected album.
         */

        private Album? current_album = null;

        /*
         * -------------------------------------------------------------
         * Album action buttons
         * -------------------------------------------------------------
         *
         * We have one for desktop and one for mobile because the two
         * presentations have separate headers.
         */

        private Button? desktop_add_album_button = null;
        private Button? mobile_add_album_button = null;

        /*
         * -------------------------------------------------------------
         * Signals
         * -------------------------------------------------------------
         */

        public signal void artist_selected (
            Artist artist
        );

        public signal void album_selected (
            Artist artist,
            Album album
        );

        public signal void song_selected (
            Song song
        );

        public signal void add_album_to_queue_requested (
            Album album,
            Song[] songs
        );

        public BrowserView (Gtk.Window parent_window) {
            base (parent_window);

            hexpand = true;
            vexpand = true;

            build_ui ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Create lists
             * ---------------------------------------------------------
             */

            desktop_artist_list = create_list ();
            desktop_album_list = create_list ();
            desktop_song_list = create_list ();

            mobile_artist_list = create_list ();
            mobile_album_list = create_list ();
            mobile_song_list = create_list ();

            /*
             * ---------------------------------------------------------
             * Build desktop
             * ---------------------------------------------------------
             */

            build_desktop_view ();

            /*
             * ---------------------------------------------------------
             * Build mobile
             * ---------------------------------------------------------
             */

            build_mobile_view ();

            /*
             * ---------------------------------------------------------
             * Responsive container
             * ---------------------------------------------------------
             */

            var breakpoint_bin =
                new Adw.BreakpointBin ();

            breakpoint_bin.hexpand = true;
            breakpoint_bin.vexpand = true;

            /*
             * Desktop is the normal/default presentation.
             */

            breakpoint_bin.set_child (
                desktop_view
            );

            /*
             * Switch to the NavigationView on narrow screens.
             */

            var breakpoint =
                new Adw.Breakpoint (
                    Adw.BreakpointCondition.parse (
                        "max-width: 700px"
                    )
                );

            breakpoint.add_setter (
                breakpoint_bin,
                "child",
                nav_view
            );

            breakpoint_bin.add_breakpoint (
                breakpoint
            );

            append (
                breakpoint_bin
            );

            update_album_action_buttons ();
        }

        /*
         * =============================================================
         * Desktop
         * =============================================================
         */

        private void build_desktop_view () {
            desktop_view =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    0
                );

            desktop_view.hexpand = true;
            desktop_view.vexpand = true;

            /*
             * Artists
             */

            var artist_column =
                create_desktop_column (
                    "Artists",
                    desktop_artist_list
                );

            /*
             * Albums
             */

            var album_column =
                create_desktop_column (
                    "Albums",
                    desktop_album_list
                );

            /*
             * Songs
             *
             * This column gets the "Add album to queue" action.
             */

            var song_column =
                create_desktop_column (
                    "Songs",
                    desktop_song_list,
                    true
                );

            artist_column.hexpand = true;
            album_column.hexpand = true;
            song_column.hexpand = true;

            artist_column.vexpand = true;
            album_column.vexpand = true;
            song_column.vexpand = true;

            desktop_view.append (
                artist_column
            );

            desktop_view.append (
                create_separator ()
            );

            desktop_view.append (
                album_column
            );

            desktop_view.append (
                create_separator ()
            );

            desktop_view.append (
                song_column
            );
        }

        private Gtk.Box create_desktop_column (
            string title,
            ListBox list,
            bool show_album_action = false
        ) {
            var column =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            column.hexpand = true;
            column.vexpand = true;

            /*
             * ---------------------------------------------------------
             * Header
             * ---------------------------------------------------------
             */

            var header =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    6
                );

            header.margin_top = 8;
            header.margin_bottom = 8;
            header.margin_start = 12;
            header.margin_end = 12;

            var label =
                new Gtk.Label (
                    title
                );

            label.halign = Align.START;
            label.hexpand = true;

            label.add_css_class (
                "heading"
            );

            header.append (
                label
            );

            /*
             * ---------------------------------------------------------
             * Album action
             * ---------------------------------------------------------
             *
             * This is deliberately in the Songs header, rather than
             * the Albums header. That makes it visually clear that the
             * action applies to the album whose songs are being shown.
             */

            if (show_album_action) {
                desktop_add_album_button =
                    create_add_album_button ();

                header.append (
                    desktop_add_album_button
                );
            }

            column.append (
                header
            );

            /*
             * ---------------------------------------------------------
             * Scrolling list
             * ---------------------------------------------------------
             */

            var scroller =
                new Gtk.ScrolledWindow ();

            scroller.hexpand = true;
            scroller.vexpand = true;

            scroller.hscrollbar_policy =
                PolicyType.NEVER;

            scroller.vscrollbar_policy =
                PolicyType.AUTOMATIC;

            scroller.set_child (
                list
            );

            column.append (
                scroller
            );

            return column;
        }

        private Gtk.Separator create_separator () {
            var separator =
                new Gtk.Separator (
                    Orientation.VERTICAL
                );

            separator.vexpand = true;

            return separator;
        }

        /*
         * =============================================================
         * Mobile
         * =============================================================
         */

        private void build_mobile_view () {
            nav_view =
                new Adw.NavigationView ();

            nav_view.hexpand = true;
            nav_view.vexpand = true;

            /*
             * Artists
             */

            var artist_page =
                create_mobile_page (
                    "Artists",
                    mobile_artist_list,
                    false
                );

            /*
             * Albums
             */

            var album_page =
                create_mobile_page (
                    "Albums",
                    mobile_album_list,
                    true
                );

            /*
             * Songs
             *
             * Give this page an action button too.
             */

            var song_page =
                create_mobile_page (
                    "Songs",
                    mobile_song_list,
                    true,
                    true
                );

            nav_view.add (
                artist_page
            );

            nav_view.add (
                album_page
            );

            nav_view.add (
                song_page
            );

            /*
             * Start at Artists.
             */

            nav_view.push (
                artist_page
            );
        }

        private Adw.NavigationPage create_mobile_page (
            string title,
            ListBox list,
            bool show_header,
            bool show_album_action = false
        ) {
            var toolbar =
                new Adw.ToolbarView ();

            toolbar.hexpand = true;
            toolbar.vexpand = true;

            /*
             * ---------------------------------------------------------
             * Header
             * ---------------------------------------------------------
             */

            if (show_header) {
                var header =
                    new Adw.HeaderBar ();

                /*
                 * Don't show window decoration buttons.
                 */

                header.show_start_title_buttons = false;
                header.show_end_title_buttons = false;

                /*
                 * Songs gets an "Add album" action.
                 */

                if (show_album_action) {
                    mobile_add_album_button =
                        create_add_album_button ();

                    header.pack_end (
                        mobile_add_album_button
                    );
                }

                toolbar.add_top_bar (
                    header
                );
            }

            /*
             * ---------------------------------------------------------
             * Scroller
             * ---------------------------------------------------------
             */

            var scroller =
                new Gtk.ScrolledWindow ();

            scroller.hexpand = true;
            scroller.vexpand = true;

            scroller.hscrollbar_policy =
                PolicyType.NEVER;

            scroller.vscrollbar_policy =
                PolicyType.AUTOMATIC;

            list.margin_top = 6;
            list.margin_bottom = 6;

            scroller.set_child (
                list
            );

            toolbar.set_content (
                scroller
            );

            /*
             * ---------------------------------------------------------
             * Navigation page
             * ---------------------------------------------------------
             */

            var page =
                new Adw.NavigationPage (
                    toolbar,
                    title
                );

            page.tag =
                title;

            return page;
        }

        /*
         * =============================================================
         * Album action
         * =============================================================
         */

        private Button create_add_album_button () {
            var button =
                new Button ();

            button.icon_name =
                "list-add-symbolic";

            button.tooltip_text =
                "Add album to queue";

            button.add_css_class (
                "flat"
            );

            button.clicked.connect (() => {
                add_current_album_to_queue ();
            });

            return button;
        }

        private void add_current_album_to_queue () {
            /*
             * There is nothing to add if an album hasn't been selected
             * or its songs haven't loaded yet.
             */

            if (current_album == null) {
                return;
            }

            if (songs.length == 0) {
                return;
            }

            add_album_to_queue_requested (
                current_album,
                songs
            );
        }

        private void update_album_action_buttons () {
            bool enabled =
                current_album != null &&
                songs.length > 0;

            if (desktop_add_album_button != null) {
                desktop_add_album_button.sensitive =
                    enabled;
            }

            if (mobile_add_album_button != null) {
                mobile_add_album_button.sensitive =
                    enabled;
            }
        }

        /*
         * =============================================================
         * List creation
         * =============================================================
         */

        private ListBox create_list () {
            var list =
                new ListBox ();

            list.hexpand = true;
            list.vexpand = true;

            list.selection_mode =
                SelectionMode.NONE;

            list.show_separators =
                true;

            return list;
        }

        /*
         * =============================================================
         * Clearing
         * =============================================================
         */

        public void clear () {
            artists = {};
            albums = {};
            songs = {};

            current_album = null;

            clear_list (
                desktop_artist_list
            );

            clear_list (
                desktop_album_list
            );

            clear_list (
                desktop_song_list
            );

            clear_list (
                mobile_artist_list
            );

            clear_list (
                mobile_album_list
            );

            clear_list (
                mobile_song_list
            );

            update_album_action_buttons ();
        }

        private void clear_list (
            ListBox list
        ) {
            Widget? child =
                list.get_first_child ();

            while (child != null) {
                Widget? next =
                    child.get_next_sibling ();

                list.remove (
                    child
                );

                child = next;
            }
        }

        /*
         * =============================================================
         * Artists
         * =============================================================
         */

        public void clear_artists () {
            artists = {};

            clear_list (
                desktop_artist_list
            );

            clear_list (
                mobile_artist_list
            );
        }

        public void add_artist (
            Artist artist
        ) {
            /*
             * Desktop row
             */

            var desktop_row =
                new ArtistRow (
                    artist
                );

            desktop_row.selected.connect (
                (selected_artist) => {
                    handle_artist_click (
                        selected_artist
                    );
                }
            );

            desktop_artist_list.append (
                desktop_row
            );

            /*
             * Mobile row
             */

            var mobile_row =
                new ArtistRow (
                    artist
                );

            mobile_row.selected.connect (
                (selected_artist) => {
                    handle_artist_click (
                        selected_artist
                    );
                }
            );

            mobile_artist_list.append (
                mobile_row
            );
        }

        public void show_artists (
            Artist[] artists
        ) {
            clear_artists ();

            this.artists =
                artists;

            foreach (Artist artist in artists) {
                add_artist (
                    artist
                );
            }
        }

        /*
         * =============================================================
         * Albums
         * =============================================================
         */

        public void clear_albums () {
            albums = {};

            clear_list (
                desktop_album_list
            );

            clear_list (
                mobile_album_list
            );
        }

        public void add_album (
            Artist artist,
            Album album
        ) {
            /*
             * Desktop row
             */

            var desktop_row =
                new AlbumRow (
                    album
                );

            desktop_row.selected.connect (
                (selected_album) => {
                    handle_album_click (
                        artist,
                        selected_album
                    );
                }
            );

            desktop_album_list.append (
                desktop_row
            );

            /*
             * Mobile row
             */

            var mobile_row =
                new AlbumRow (
                    album
                );

            mobile_row.selected.connect (
                (selected_album) => {
                    handle_album_click (
                        artist,
                        selected_album
                    );
                }
            );

            mobile_album_list.append (
                mobile_row
            );
        }

        public void show_albums (
            Artist artist,
            Album[] albums
        ) {
            clear_albums ();

            this.albums =
                albums;

            foreach (Album album in albums) {
                add_album (
                    artist,
                    album
                );
            }
        }

        /*
         * =============================================================
         * Songs
         * =============================================================
         */

        public void clear_songs () {
            songs = {};

            clear_list (
                desktop_song_list
            );

            clear_list (
                mobile_song_list
            );

            update_album_action_buttons ();
        }

        public void add_song (
            Song song
        ) {
            /*
             * Keep the backing array synchronized with the rows.
             *
             * This is important because the Navidrome controller loads
             * songs incrementally through this method.
             */

            songs += song;

            /*
             * Desktop row
             */

            var desktop_row =
                new SongRow (
                    song
                );

            desktop_row.selected.connect (
                (selected_song) => {
                    song_selected (
                        selected_song
                    );
                }
            );

            desktop_song_list.append (
                desktop_row
            );

            /*
             * Mobile row
             */

            var mobile_row =
                new SongRow (
                    song
                );

            mobile_row.selected.connect (
                (selected_song) => {
                    song_selected (
                        selected_song
                    );
                }
            );

            mobile_song_list.append (
                mobile_row
            );

            /*
             * The album action becomes available as soon as at least
             * one song has arrived.
             */

            update_album_action_buttons ();
        }

        public void show_songs (
            Song[] songs
        ) {
            clear_songs ();

            /*
             * Store the complete collection here, then create rows
             * directly rather than calling add_song(), since add_song()
             * also updates the backing collection.
             */

            this.songs =
                songs;

            foreach (Song song in songs) {
                add_song_row (
                    song
                );
            }

            update_album_action_buttons ();
        }

        private void add_song_row (
            Song song
        ) {
            /*
             * Desktop row
             */

            var desktop_row =
                new SongRow (
                    song
                );

            desktop_row.selected.connect (
                (selected_song) => {
                    song_selected (
                        selected_song
                    );
                }
            );

            desktop_song_list.append (
                desktop_row
            );

            /*
             * Mobile row
             */

            var mobile_row =
                new SongRow (
                    song
                );

            mobile_row.selected.connect (
                (selected_song) => {
                    song_selected (
                        selected_song
                    );
                }
            );

            mobile_song_list.append (
                mobile_row
            );
        }

        /*
         * =============================================================
         * Navigation
         * =============================================================
         */

        private void handle_artist_click (
            Artist artist
        ) {
            /*
             * Tell the controller that the artist changed.
             */

            artist_selected (
                artist
            );

            /*
             * Navigation only affects the mobile presentation.
             *
             * On desktop the Albums column is already visible.
             */

            var album_page =
                nav_view.find_page (
                    "Albums"
                );

            if (album_page == null) {
                return;
            }

            nav_view.pop_to_tag (
                "Artists"
            );

            nav_view.push (
                album_page
            );
        }

        private void handle_album_click (
            Artist artist,
            Album album
        ) {
            /*
             * Remember which album owns the currently displayed songs.
             */

            current_album =
                album;

            /*
             * Clear the old songs immediately. This also disables the
             * Add Album button while the new album is loading.
             */

            clear_songs ();

            /*
             * Tell the controller to load the new album.
             */

            album_selected (
                artist,
                album
            );

            /*
             * Navigation only affects mobile.
             */

            var song_page =
                nav_view.find_page (
                    "Songs"
                );

            if (song_page == null) {
                return;
            }

            if (
                nav_view.get_visible_page () ==
                song_page
            ) {
                return;
            }

            nav_view.push (
                song_page
            );
        }
    }
}
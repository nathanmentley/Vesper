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
         * Search
         * -------------------------------------------------------------
         */

        private SearchEntry search_entry;

        /*
         * -------------------------------------------------------------
         * Desktop lists
         * -------------------------------------------------------------
         */

        private ListBox desktop_artist_list;
        private ListBox desktop_album_list;
        private ListBox desktop_song_list;
        private ListBox desktop_search_list;

        /*
         * -------------------------------------------------------------
         * Mobile lists
         * -------------------------------------------------------------
         */

        private ListBox mobile_artist_list;
        private ListBox mobile_album_list;
        private ListBox mobile_song_list;
        private ListBox mobile_search_list;

        /*
         * -------------------------------------------------------------
         * Layouts
         * -------------------------------------------------------------
         */

        private Gtk.Box desktop_view;
        private Gtk.Box desktop_search_view;
        private Gtk.Stack desktop_stack;

        private Adw.NavigationView nav_view;
        private Adw.NavigationPage mobile_search_page;

        /*
         * -------------------------------------------------------------
         * Data
         * -------------------------------------------------------------
         */

        private Artist[] artists = {};
        private Album[] albums = {};
        private Song[] songs = {};
        private Artist? current_artist = null;

        private SearchResult[] search_results = {};

        /*
         * Currently selected album.
         */

        private Album? current_album = null;

        /*
         * -------------------------------------------------------------
         * Album action buttons
         * -------------------------------------------------------------
         */

        private Button? desktop_add_album_button = null;
        private Button? mobile_add_album_button = null;
        private Button? desktop_add_album_playlist_button = null;
        private Button? mobile_add_album_playlist_button = null;

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

        public signal void search_requested (
            string query
        );

        public signal void add_album_to_queue_requested (
            Album album,
            Song[] songs
        );

        public signal void add_album_to_playlist_requested (
            Album album,
            Song[] songs
        );

        public signal void add_song_to_playlist_requested (Song song);

        public BrowserView (
            Gtk.Window parent_window
        ) {
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
            desktop_search_list = create_list ();

            mobile_artist_list = create_list ();
            mobile_album_list = create_list ();
            mobile_song_list = create_list ();
            mobile_search_list = create_list ();

            /*
             * ---------------------------------------------------------
             * Build views
             * ---------------------------------------------------------
             */

            build_desktop_view ();
            build_desktop_search_view ();
            build_mobile_view ();

            /*
             * ---------------------------------------------------------
             * Desktop stack
             * ---------------------------------------------------------
             */

            desktop_stack =
                new Gtk.Stack ();

            desktop_stack.hexpand = true;
            desktop_stack.vexpand = true;

            desktop_stack.add_named (
                desktop_view,
                "browse"
            );

            desktop_stack.add_named (
                desktop_search_view,
                "search"
            );

            desktop_stack.visible_child_name =
                "browse";

            /*
             * ---------------------------------------------------------
             * Responsive container
             * ---------------------------------------------------------
             */

            var breakpoint_bin =
                new Adw.BreakpointBin ();

            breakpoint_bin.hexpand = true;
            breakpoint_bin.vexpand = true;

            breakpoint_bin.set_child (
                desktop_stack
            );

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

            /*
             * ---------------------------------------------------------
             * Search entry
             * ---------------------------------------------------------
             */

            search_entry =
                new SearchEntry ();

            search_entry.hexpand = true;

            search_entry.placeholder_text =
                "Search your music";

            search_entry.search_delay =
                250;

            search_entry.activate.connect (() => {
                search_requested (
                    search_entry.text
                );
            });

            search_entry.search_changed.connect (() => {
                if (search_entry.text.strip ().length == 0) {
                    show_browse ();
                }
            });

            var search_header =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    0
                );

            search_header.margin_top = 8;
            search_header.margin_bottom = 8;
            search_header.margin_start = 12;
            search_header.margin_end = 12;

            search_header.append (
                search_entry
            );

            /*
             * ---------------------------------------------------------
             * Root layout
             * ---------------------------------------------------------
             */

            var root_view =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            root_view.hexpand = true;
            root_view.vexpand = true;

            root_view.append (
                search_header
            );

            root_view.append (
                breakpoint_bin
            );

            append (
                root_view
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
                    desktop_artist_list,
                    false
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

        private void build_desktop_search_view () {
            desktop_search_view =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            desktop_search_view.hexpand = true;
            desktop_search_view.vexpand = true;

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
                    "Search Results"
                );

            label.halign = Align.START;
            label.hexpand = true;

            label.add_css_class (
                "heading"
            );

            header.append (
                label
            );

            desktop_search_view.append (
                header
            );

            var scroller =
                new Gtk.ScrolledWindow ();

            scroller.hexpand = true;
            scroller.vexpand = true;

            scroller.hscrollbar_policy =
                PolicyType.NEVER;

            scroller.vscrollbar_policy =
                PolicyType.AUTOMATIC;

            scroller.set_child (
                desktop_search_list
            );

            desktop_search_view.append (
                scroller
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

            if (show_album_action) {
                desktop_add_album_button =
                    create_add_album_button ();

                header.append (
                    desktop_add_album_button
                );

                desktop_add_album_playlist_button = create_add_album_playlist_button ();
                header.append (desktop_add_album_playlist_button);
            }

            column.append (
                header
            );

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
                    true
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
             */

            var song_page =
                create_mobile_page (
                    "Songs",
                    mobile_song_list,
                    true,
                    true
                );

            /*
             * Search results
             */

            mobile_search_page =
                create_mobile_search_page ();

            nav_view.add (
                artist_page
            );

            nav_view.add (
                album_page
            );

            nav_view.add (
                song_page
            );

            nav_view.add (
                mobile_search_page
            );

            /*
             * Start at Artists.
             */

            nav_view.push (
                artist_page
            );
        }

        private Adw.NavigationPage create_mobile_search_page () {
            var toolbar =
                new Adw.ToolbarView ();

            toolbar.hexpand = true;
            toolbar.vexpand = true;

            /*
             * Don't show window controls here.
             *
             * NavigationView handles navigation independently.
             */

            var header =
                new Adw.HeaderBar ();

            header.show_start_title_buttons = false;
            header.show_end_title_buttons = false;

            toolbar.add_top_bar (
                header
            );

            var scroller =
                new Gtk.ScrolledWindow ();

            scroller.hexpand = true;
            scroller.vexpand = true;

            scroller.hscrollbar_policy =
                PolicyType.NEVER;

            scroller.vscrollbar_policy =
                PolicyType.AUTOMATIC;

            mobile_search_list.margin_top = 6;
            mobile_search_list.margin_bottom = 6;

            scroller.set_child (
                mobile_search_list
            );

            toolbar.set_content (
                scroller
            );

            var page =
                new Adw.NavigationPage (
                    toolbar,
                    "Search Results"
                );

            page.tag =
                "Search Results";

            return page;
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

            if (show_header) {
                var header =
                    new Adw.HeaderBar ();

                header.show_start_title_buttons = false;
                header.show_end_title_buttons = false;

                if (show_album_action) {
                    mobile_add_album_button =
                        create_add_album_button ();

                    header.pack_end (
                        mobile_add_album_button
                    );

                    mobile_add_album_playlist_button = create_add_album_playlist_button ();
                    header.pack_end (mobile_add_album_playlist_button);
                }

                toolbar.add_top_bar (
                    header
                );
            }

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
         * Search
         * =============================================================
         */

        public void show_search_results (
            Gee.List<SearchResult> results
        ) {
            search_results =
                results.to_array ();

            clear_list (
                desktop_search_list
            );

            clear_list (
                mobile_search_list
            );

            foreach (SearchResult result in search_results) {
                add_search_result (
                    result
                );
            }

            /*
             * Desktop
             */

            desktop_stack.visible_child_name =
                "search";

            /*
             * Mobile
             */

            if (
                nav_view.get_visible_page () !=
                mobile_search_page
            ) {
                nav_view.push (
                    mobile_search_page
                );
            }
        }

        private void add_search_result (
            SearchResult result
        ) {
            /*
             * Desktop
             */

            desktop_search_list.append (
                create_search_result_row (
                    result
                )
            );

            /*
             * Mobile
             */

            mobile_search_list.append (
                create_search_result_row (
                    result
                )
            );
        }

        private Gtk.ListBoxRow create_search_result_row (
            SearchResult result
        ) {
            var row =
                new Gtk.ListBoxRow ();

            row.activatable = true;
            row.selectable = false;

            var box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    2
                );

            box.margin_top = 8;
            box.margin_bottom = 8;
            box.margin_start = 12;
            box.margin_end = 12;

            /*
             * Song title
             */

            var title =
                new Gtk.Label (
                    result.song.title
                );

            title.halign = Align.START;
            title.hexpand = true;

            title.ellipsize =
                Pango.EllipsizeMode.END;

            title.max_width_chars = 80;

            title.add_css_class (
                "heading"
            );

            /*
             * Artist / album
             */

            var subtitle =
                new Gtk.Label (
                    "%s • %s".printf (
                        result.artist.name,
                        result.song.album.name
                    )
                );

            subtitle.halign = Align.START;
            subtitle.hexpand = true;

            subtitle.ellipsize =
                Pango.EllipsizeMode.END;

            subtitle.max_width_chars = 80;

            subtitle.add_css_class (
                "dim-label"
            );

            box.append (
                title
            );

            box.append (
                subtitle
            );

            row.set_child (
                box
            );

            /*
             * Explicitly handle clicks.
             */

            var gesture =
                new Gtk.GestureClick ();

            gesture.released.connect (
                (n_press, x, y) => {
                    song_selected (
                        result.song
                    );
                }
            );

            row.add_controller (
                gesture
            );

            return row;
        }

        /*
         * =============================================================
         * Browse/Search mode
         * =============================================================
         */

        public void show_browse () {
            search_results = {};

            clear_list (
                desktop_search_list
            );

            clear_list (
                mobile_search_list
            );

            desktop_stack.visible_child_name =
                "browse";

            /*
             * Return mobile navigation to Artists when coming out
             * of search.
             */

            if (
                nav_view.get_visible_page () ==
                mobile_search_page
            ) {
                nav_view.pop_to_tag (
                    "Artists"
                );
            }
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
                "media-playback-start-symbolic";

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

        private Button create_add_album_playlist_button () {
            var button = new Button.from_icon_name ("list-add-symbolic");
            button.tooltip_text = "Add album to playlist";
            button.add_css_class ("flat");
            button.clicked.connect (() => {
                if (current_album != null) {
                    add_album_to_playlist_requested (current_album, songs);
                }
            });
            return button;
        }

        private void add_current_album_to_queue () {
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

            bool playlist_enabled = enabled;
            if (desktop_add_album_playlist_button != null) {
                desktop_add_album_playlist_button.sensitive = playlist_enabled;
            }
            if (mobile_add_album_playlist_button != null) {
                mobile_add_album_playlist_button.sensitive = playlist_enabled;
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
            search_results = {};

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
                desktop_search_list
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

            clear_list (
                mobile_search_list
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
                selected_artist => {
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
                selected_artist => {
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
            show_browse ();

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
                selected_album => {
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
                selected_album => {
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

            current_artist = artist;

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
            songs += song;

            /*
             * Desktop row
             */

            var desktop_row =
                new SongRow (
                    song
                );

            desktop_row.selected.connect (
                selected_song => {
                    song_selected (
                        selected_song
                    );
                }
            );

            desktop_row.add_to_playlist_requested.connect (
                selected_song => add_song_to_playlist_requested (selected_song)
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
                selected_song => {
                    song_selected (
                        selected_song
                    );
                }
            );

            mobile_row.add_to_playlist_requested.connect (
                selected_song => add_song_to_playlist_requested (selected_song)
            );

            mobile_song_list.append (
                mobile_row
            );

            update_album_action_buttons ();
        }

        public void show_songs (
            Song[] songs
        ) {
            clear_songs ();

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
                selected_song => {
                    song_selected (
                        selected_song
                    );
                }
            );

            desktop_row.add_to_playlist_requested.connect (
                selected_song => add_song_to_playlist_requested (selected_song)
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
                selected_song => {
                    song_selected (
                        selected_song
                    );
                }
            );

            mobile_row.add_to_playlist_requested.connect (
                selected_song => add_song_to_playlist_requested (selected_song)
            );

            mobile_song_list.append (
                mobile_row
            );
        }

        public void show_playlist_chooser (
            Song song,
            Gee.List<Playlist> playlists
        ) {
            if (playlists.size == 0) {
                warning ("Cannot add '%s': no playlists exist", song.title);
                return;
            }

            var chooser = new Gtk.ComboBoxText ();
            foreach (Playlist playlist in playlists) {
                chooser.append (playlist.id, playlist.name);
            }
            chooser.active = 0;

            var dialog = new Adw.AlertDialog (
                "Add to Playlist",
                song.title
            );
            dialog.set_extra_child (chooser);
            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("add", "Add");
            dialog.set_default_response ("add");
            dialog.set_close_response ("cancel");
            dialog.response.connect (response => {
                if (response == "add" && chooser.active_id != null) {
                    add_song_to_playlist_selected (
                        song,
                        chooser.active_id
                    );
                }
            });
            dialog.present (get_root () as Widget);
        }

        public signal void add_song_to_playlist_selected (
            Song song,
            string playlist_id
        );

        public signal void add_songs_to_playlist_selected (
            Gee.List<Song> songs,
            string playlist_id
        );

        public void show_songs_playlist_chooser (
            Gee.List<Song> songs,
            Gee.List<Playlist> playlists
        ) {
            if (songs.size == 0 || playlists.size == 0) {
                return;
            }

            var chooser = new Gtk.ComboBoxText ();
            foreach (Playlist playlist in playlists) {
                chooser.append (playlist.id, playlist.name);
            }
            chooser.active = 0;

            var dialog = new Adw.AlertDialog (
                "Add Songs to Playlist",
                "%d songs".printf (songs.size)
            );
            dialog.set_extra_child (chooser);
            dialog.add_response ("cancel", "Cancel");
            dialog.add_response ("add", "Add");
            dialog.set_close_response ("cancel");
            dialog.response.connect (response => {
                if (response == "add" && chooser.active_id != null) {
                    add_songs_to_playlist_selected (songs, chooser.active_id);
                }
            });
            dialog.present (get_root () as Widget);
        }

        /*
         * =============================================================
         * Navigation
         * =============================================================
         */

        private void handle_artist_click (
            Artist artist
        ) {
            artist_selected (
                artist
            );

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
            current_album =
                album;

            clear_songs ();

            album_selected (
                artist,
                album
            );

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
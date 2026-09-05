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
using Gdk;
using GLib;

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

using Vesper.Service.Libraries;
using Vesper.Service.Media;
using Vesper.Service.Playlists;
using Vesper.Service.Plugins;
using Vesper.Service.Settings;

using Vesper.App.Controllers;
using Vesper.App.Models;
using Vesper.App.Views;

namespace Vesper.App.Windows {
    public class MainWindow : Adw.ApplicationWindow {
        private IOC ioc;

        private BrowserController browser_controller;
        private NowPlayingController now_playing_controller;
        private PlayerController player_controller;
        private PlaylistController playlist_controller;
        private SettingsController settings_controller;

        private PlayQueue playlist;
        private bool shuffle_enabled = false;
        private bool repeat_enabled = false;

        /*
         * -------------------------------------------------------------
         * Libadwaita UI
         * -------------------------------------------------------------
         */

        private Adw.ViewStack view_stack;
        private Adw.ViewSwitcher view_switcher;
        private Adw.ViewSwitcherBar view_switcher_bar;
        private Adw.ToastOverlay toast_overlay;

        /*
         * Player remains visible while switching between views.
         */
        private Gtk.Box player_box;

        public MainWindow (Adw.Application app, IOC ioc) {
            Object (
                application: app,
                title: "Vesper",
                default_width: 1200,
                default_height: 640
            );

            this.playlist = new PlayQueue ();

            this.ioc = ioc;

            /*
             * ---------------------------------------------------------
             * Controllers
             * ---------------------------------------------------------
             */
            this.browser_controller = new BrowserController (ioc.library_service, this);
            this.now_playing_controller = new NowPlayingController (ioc.library_service, this);
            this.player_controller = new PlayerController (ioc.media_service, this);
            this.playlist_controller = new PlaylistController (playlist, ioc.playlist_service, this);
            this.settings_controller = new SettingsController (ioc.settings_service, this);

            build_ui ();
            connect_signals ();
            connect_to_navidrome ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Main View Stack
             * ---------------------------------------------------------
             */

            view_stack =
                new Adw.ViewStack ();

            /*
             * ---------------------------------------------------------
             * Now Playing
             * ---------------------------------------------------------
             */

            Gtk.Box now_playing_box = new Gtk.Box (Orientation.VERTICAL, 0);

            now_playing_box.set_margin_top (12);
            now_playing_box.set_margin_bottom (12);
            now_playing_box.set_margin_start (12);
            now_playing_box.set_margin_end (12);
            now_playing_controller.mount (now_playing_box);

            view_stack.add_titled_with_icon (
                now_playing_box,
                "now-playing",
                "Now Playing",
                "media-playback-start-symbolic"
            );

            /*
             * ---------------------------------------------------------
             * Library
             * ---------------------------------------------------------
             */

            var library_box = new Gtk.Box (Orientation.VERTICAL, 0);

            library_box.set_margin_top (12);
            library_box.set_margin_bottom (12);
            library_box.set_margin_start (12);
            library_box.set_margin_end (12);
            browser_controller.mount (library_box);

            view_stack.add_titled_with_icon (
                library_box,
                "library",
                "Library",
                "folder-music-symbolic"
            );

            /*
             * ---------------------------------------------------------
             * Playlist
             * ---------------------------------------------------------
             */

            var playlist_box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            playlist_box.set_margin_top (12);
            playlist_box.set_margin_bottom (12);
            playlist_box.set_margin_start (12);
            playlist_box.set_margin_end (12);
            playlist_controller.mount (playlist_box);

            view_stack.add_titled_with_icon (
                playlist_box,
                "playlist",
                "Playlist",
                "view-list-symbolic"
            );

            /*
             * ---------------------------------------------------------
             * Settings
             * ---------------------------------------------------------
             *
             * Keep Settings constrained on large displays.
             */

            Gtk.Box settings_box = new Gtk.Box (Orientation.VERTICAL, 0);

            settings_box.set_margin_top (12);
            settings_box.set_margin_bottom (12);
            settings_box.set_margin_start (12);
            settings_box.set_margin_end (12);
            settings_controller.mount (settings_box);

            Adw.Clamp settings_clamp = new Adw.Clamp ();
            settings_clamp.maximum_size = 600;
            settings_clamp.tightening_threshold = 400;
            settings_clamp.set_child (settings_box);

            view_stack.add_titled_with_icon (
                settings_clamp,
                "settings",
                "Settings",
                "emblem-system-symbolic"
            );

            /*
             * ---------------------------------------------------------
             * Desktop View Switcher
             * ---------------------------------------------------------
             */

            view_switcher = new Adw.ViewSwitcher ();
            view_switcher.stack = view_stack;
            view_switcher.policy = Adw.ViewSwitcherPolicy.WIDE;

            /*
             * ---------------------------------------------------------
             * Mobile View Switcher
             * ---------------------------------------------------------
             */

            view_switcher_bar = new Adw.ViewSwitcherBar ();
            view_switcher_bar.stack = view_stack;
            view_switcher_bar.reveal = false;

            /*
             * ---------------------------------------------------------
             * Header Bar
             * ---------------------------------------------------------
             */

            Adw.HeaderBar header_bar = new Adw.HeaderBar ();
            header_bar.set_title_widget (view_switcher);

            /*
             * ---------------------------------------------------------
             * Player
             * ---------------------------------------------------------
             */

            player_box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            player_controller.mount (
                player_box
            );

            /*
             * ---------------------------------------------------------
             * Main Content
             * ---------------------------------------------------------
             */

            var content =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            content.hexpand = true;
            content.vexpand = true;

            content.append (
                view_stack
            );

            content.append (
                player_box
            );

            /*
             * ---------------------------------------------------------
             * Toolbar View
             * ---------------------------------------------------------
             */

            var toolbar_view =
                new Adw.ToolbarView ();

            toolbar_view.add_top_bar (
                header_bar
            );

            toolbar_view.add_bottom_bar (
                view_switcher_bar
            );

            toolbar_view.set_content (
                content
            );

            /*
             * ---------------------------------------------------------
             * Toast Overlay
             * ---------------------------------------------------------
             */

            toast_overlay =
                new Adw.ToastOverlay ();

            toast_overlay.set_child (
                toolbar_view
            );

            set_content (
                toast_overlay
            );

            /*
             * ---------------------------------------------------------
             * Responsive Layout
             * ---------------------------------------------------------
             *
             * Desktop:
             *
             *   HeaderBar
             *       └── ViewSwitcher
             *
             * Mobile:
             *
             *   HeaderBar
             *
             *   content
             *
             *   ViewSwitcherBar
             */

            var breakpoint =
                new Adw.Breakpoint (
                    Adw.BreakpointCondition.parse (
                        "max-width: 600px"
                    )
                );

            breakpoint.add_setter (
                view_switcher,
                "visible",
                false
            );

            breakpoint.add_setter (
                view_switcher_bar,
                "reveal",
                true
            );

            add_breakpoint (
                breakpoint
            );
        }

        private void connect_signals () {
            /*
             * ---------------------------------------------------------
             * Settings
             * ---------------------------------------------------------
             */

            settings_controller.connection_requested.connect (
                connect_to_navidrome
            );

            /*
             * ---------------------------------------------------------
             * Library
             * ---------------------------------------------------------
             */

            browser_controller.play_requested.connect (
                on_play_requested
            );

            /*
             * ---------------------------------------------------------
             * Player
             * ---------------------------------------------------------
             */

            player_controller.song_finished.connect (
                on_song_finished
            );

            player_controller.previous_requested.connect (
                on_previous_requested
            );

            player_controller.next_requested.connect (
                on_next_requested
            );

            player_controller.shuffle_requested.connect (enabled => { shuffle_enabled = enabled; });
            player_controller.repeat_requested.connect (enabled => { repeat_enabled = enabled; });

            /*
             * ---------------------------------------------------------
             * Playlist
             * ---------------------------------------------------------
             */

            playlist_controller.selected.connect (
                () => {
                    Song? song =
                        playlist.get_current_song ();

                    if (song == null) {
                        player_controller.stop ();
                        return;
                    }

                    start_new_song (
                        song
                    );
                }
            );

            ioc.library_service.library_refresh.connect (
                () => {
                    browser_controller.load_artists ();

                    playlist_controller.load_playlists.begin ();
                }
            );

            /*
             * ---------------------------------------------------------
             * Window
             * ---------------------------------------------------------
             */

            close_request.connect (
                on_close
            );
        }

        /*
         * -------------------------------------------------------------
         * Toast Notifications
         * -------------------------------------------------------------
         *
         * Toasts are now reserved for things that actually require
         * the user's attention.
         *
         * Normal actions such as adding a song or connecting to the
         * server do not generate a toast.
         * -------------------------------------------------------------
         */

        private void show_error (
            string message
        ) {
            var toast =
                new Adw.Toast (
                    message
                );

            /*
             * Give errors a little longer to be read.
             */
            toast.timeout =
                5;

            toast_overlay.add_toast (
                toast
            );
        }

        /*
         * -------------------------------------------------------------
         * Playback
         * -------------------------------------------------------------
         */

        public void on_play_requested (
            Song song
        ) {
            playlist.add_song (
                song
            );

            if (!player_controller.is_playing ()) {
                start_new_song (
                    song
                );
            }

            playlist_controller.rebuild ();
        }

        private void on_song_finished () {
            Song? next_song = get_next_song_to_play ();

            if (next_song == null) {
                /*
                 * Nothing else to play.
                 *
                 * Stopping playback is enough feedback.
                 */

                player_controller.stop ();

                return;
            }

            start_new_song (
                next_song
            );
        }

        private Song? get_next_song_to_play () {
            if (repeat_enabled) {
                return playlist.get_current_song ();
            }

            if (shuffle_enabled) {
                return playlist.get_random_song ();
            }

            return playlist.get_next_song ();
        }

        private void on_previous_requested () {
            Song? previous_song =
                shuffle_enabled ?
                    playlist.get_random_song () :
                    playlist.get_previous_song ();

            if (previous_song == null) {
                /*
                 * There is simply no previous song.
                 *
                 * Don't interrupt the user with a notification.
                 */

                return;
            }

            start_new_song (
                previous_song
            );
        }

        private void on_next_requested () {
            Song? next_song =
                shuffle_enabled ?
                    playlist.get_random_song () :
                    playlist.get_next_song ();

            if (next_song == null) {
                /*
                 * There is simply no next song.
                 */

                return;
            }

            start_new_song (
                next_song
            );
        }

        private void start_new_song (
            Song song
        ) {
            player_controller.stop ();

            player_controller.play (
                song
            );

            now_playing_controller.set_song (
                song
            );

            playlist_controller.rebuild ();
        }

        /*
         * -------------------------------------------------------------
         * Navidrome Connection
         * -------------------------------------------------------------
         */
        private void connect_to_navidrome () {
            try {
                ioc.library_service.sync.begin ();

                browser_controller.load_artists ();

                playlist_controller.load_playlists.begin ();
            } catch (GLib.Error e) {
                string message =
                    "Unable to connect to Navidrome: " +
                    e.message;

                show_error (
                    message
                );
            }
        }

        /*
         * -------------------------------------------------------------
         * Window Lifecycle
         * -------------------------------------------------------------
         */

        private bool on_close () {
            player_controller.stop ();

            return false;
        }
    }
}
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

using PiPod.Core;
using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Controllers;
using PiPod.Models;
using PiPod.Views;

namespace PiPod.Windows {
    public class MainWindow : Adw.ApplicationWindow {
        private IConfig config;

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

        public MainWindow (Adw.Application app, IConfig config) {
            Object (
                application: app,
                title: "PiPod",
                default_width: 1200,
                default_height: 640
            );

            this.config = config;

            this.playlist = new PlayQueue ();

            /*
             * ---------------------------------------------------------
             * Controllers
             * ---------------------------------------------------------
             */

            PluginManager plugin_manager = new PluginManager(
                "/Users/nathan/projects/pipod/build/plugins",
                config
            );

            MusicLibrary library = get_first_plugin_impl(plugin_manager, typeof(MusicLibrary));
            PlaylistProvider playlist_provider = get_first_plugin_impl(plugin_manager, typeof(PlaylistProvider));
            MusicEngine music_engine = get_first_plugin_impl(plugin_manager, typeof(MusicEngine));

            this.browser_controller =
                new BrowserController (
                    library
                );

            this.now_playing_controller =
                new NowPlayingController (
                    library
                );

            this.player_controller =
                new PlayerController (
                    music_engine
                );

            this.playlist_controller =
                new PlaylistController (
                    playlist,
                    playlist_provider
                );

            this.settings_controller =
                new SettingsController (
                    config
                );

            build_ui ();
            connect_signals ();
            load_config ();
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

            var now_playing_box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            now_playing_box.set_margin_top (
                12
            );

            now_playing_box.set_margin_bottom (
                12
            );

            now_playing_box.set_margin_start (
                12
            );

            now_playing_box.set_margin_end (
                12
            );

            now_playing_controller.mount (
                now_playing_box
            );

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

            var library_box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            library_box.set_margin_top (
                12
            );

            library_box.set_margin_bottom (
                12
            );

            library_box.set_margin_start (
                12
            );

            library_box.set_margin_end (
                12
            );

            browser_controller.mount (
                library_box
            );

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

            playlist_box.set_margin_top (
                12
            );

            playlist_box.set_margin_bottom (
                12
            );

            playlist_box.set_margin_start (
                12
            );

            playlist_box.set_margin_end (
                12
            );

            playlist_controller.mount (
                playlist_box
            );

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

            var settings_box =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            settings_box.set_margin_top (
                12
            );

            settings_box.set_margin_bottom (
                12
            );

            settings_box.set_margin_start (
                12
            );

            settings_box.set_margin_end (
                12
            );

            settings_controller.mount (
                settings_box
            );

            var settings_clamp =
                new Adw.Clamp ();

            settings_clamp.maximum_size =
                600;

            settings_clamp.tightening_threshold =
                400;

            settings_clamp.set_child (
                settings_box
            );

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

            view_switcher =
                new Adw.ViewSwitcher ();

            view_switcher.stack =
                view_stack;

            view_switcher.policy =
                Adw.ViewSwitcherPolicy.WIDE;

            /*
             * ---------------------------------------------------------
             * Mobile View Switcher
             * ---------------------------------------------------------
             */

            view_switcher_bar =
                new Adw.ViewSwitcherBar ();

            view_switcher_bar.stack =
                view_stack;

            view_switcher_bar.reveal =
                false;

            /*
             * ---------------------------------------------------------
             * Header Bar
             * ---------------------------------------------------------
             */

            var header_bar =
                new Adw.HeaderBar ();

            header_bar.set_title_widget (
                view_switcher
            );

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

        private void on_play_requested (
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

            /*
             * No toast.
             *
             * The playlist changing is sufficient feedback.
             */
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
            /*
             * Missing configuration is not an application-wide
             * notification. The Settings view is the appropriate place
             * to eventually display this inline.
             */

            if (
                config.base_url.length == 0 ||
                config.user.length == 0
            ) {
                show_error (
                    "Enter server URL and username"
                );

                return;
            }

            try {
                config.save_config ();

                /*
                 * No "Connecting..." toast.
                 *
                 * No "Connected!" toast.
                 *
                 * The library populating itself provides the feedback.
                 */

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

        /*
         * -------------------------------------------------------------
         * Configuration
         * -------------------------------------------------------------
         */

        private void load_config () {
            if (!config.load_config ()) {
                return;
            }

            Idle.add (() => {
                connect_to_navidrome ();

                return false;
            });
        }

        private T get_first_plugin_impl<T> (
            PluginManager plugin_manager,
            GLib.Type type
        ) {
            Gee.List<GLib.Object> extensions =
                plugin_manager.get_extensions (type);

            foreach (var extension in extensions) {
                if (extension.get_type ().is_a (type)) {
                    return (T) extension;
                }
            }

            error (
                "No implementation found for %s",
                type.name ()
            );
        }
    }
}
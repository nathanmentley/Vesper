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

using PiPod.Clients;
using PiPod.Controllers;
using PiPod.Models;
using PiPod.Views;

namespace PiPod.Windows {
    public class MainWindow : ApplicationWindow {
        private IConfig config;
        private INavidromeClient navidrome;

        private BrowserController browser_controller;
        private NowPlayingController now_playing_controller;
        private PlayerController player_controller;
        private PlaylistController playlist_controller;
        private SettingsController settings_controller;

        private Playlist playlist;

        public MainWindow (Gtk.Application app, IConfig config, IMusicEngine music, INavidromeClient navidrome) {
            Object (application: app, title: "PiPod", default_width: 1200, default_height: 640);

            this.config = config;
            this.navidrome = navidrome;

            this.playlist = new Playlist ();

            this.browser_controller = new BrowserController (navidrome);
            this.now_playing_controller = new NowPlayingController (navidrome);
            this.player_controller = new PlayerController (music);
            this.playlist_controller = new PlaylistController (playlist);
            this.settings_controller = new SettingsController (config);

            build_ui ();
            connect_signals ();
            load_config ();
        }

        private void build_ui () {
            Box root = new Box (Orientation.VERTICAL, 8);

            root.get_style_context ().add_class ("pipod-root");

            set_child (root);

            Box box1 = new Box (Orientation.VERTICAL, 8);
            Box box2 = new Box (Orientation.VERTICAL, 8);
            Box box3 = new Box (Orientation.VERTICAL, 8);
            Box box4 = new Box (Orientation.VERTICAL, 8);

            now_playing_controller.mount (box1);
            browser_controller.mount (box2);
            playlist_controller.mount (box3);
            settings_controller.mount (box4);

            Label label1 = new Label ("Now Playing");
            Label label2 = new Label ("Library");
            Label label3 = new Label ("Playlist");
            Label label4 = new Label ("Settings");

            Notebook notebook = new Notebook ();

            notebook.append_page (box1, label1);
            notebook.append_page (box2, label2);
            notebook.append_page (box3, label3);
            notebook.append_page (box4, label4);

            root.append (notebook);

            player_controller.mount (root);
        }

        private void connect_signals () {
            settings_controller.connection_requested.connect (connect_to_navidrome);

            browser_controller.play_requested.connect (on_play_requested);

            player_controller.song_finished.connect (on_song_finished);

            player_controller.previous_requested.connect (on_previous_requested);

            player_controller.next_requested.connect  (on_next_requested);

            playlist_controller.selected.connect (() => {
                Song? song = playlist.get_current_song ();

                if (song == null) {
                    player_controller.stop ();

                    return;
                }

                start_new_song (song);
            });

            close_request.connect (on_close);
        }

        private void on_play_requested (Song song) {
            playlist.add_song (song);

            if (!player_controller.is_playing ()) {
                start_new_song (song);
            }

            playlist_controller.rebuild ();
        }

        private void on_song_finished () {
            Song? next_song = playlist.get_next_song ();

            if (next_song == null) {
                player_controller.stop ();

                player_controller.set_status ("Playlist finished");

                return;
            }

            start_new_song (next_song);
        }

        private void on_previous_requested () {
            Song? previous_song = playlist.get_previous_song ();

            if (previous_song == null) {
                player_controller.stop ();

                player_controller.set_status ("No previous song in playlist");

                return;
            }

            start_new_song (previous_song);
        }

        private void on_next_requested () {
            Song? next_song = playlist.get_next_song ();

            if (next_song == null) {
                player_controller.stop ();

                player_controller.set_status ("No next song in playlist");

                return;
            }

            start_new_song (next_song);
        }

        private void connect_to_navidrome () {
            if (config.base_url.length == 0 || config.user.length == 0) {
                player_controller.set_status ("Enter server URL and username");

                return;
            }

            try {
                config.save_config ();

                player_controller.set_status ("Querying server...");

                browser_controller.load_artists ();

                player_controller.set_status ("Connected");
            } catch (GLib.Error e) {
                player_controller.set_status ("Request failed: " + e.message);
            }
        }
        
        private bool on_close () {
            player_controller.stop ();

            return false;
        }

        private void start_new_song(Song song) {
            player_controller.stop ();
            player_controller.play (song);
            now_playing_controller.set_song (song);
            playlist_controller.rebuild ();
        }

        private void load_config () {
            if (!config.load_config ()) {
                return;
            }

            Idle.add (() => {
                connect_to_navidrome ();

                return false;
            });
        }
    }
}
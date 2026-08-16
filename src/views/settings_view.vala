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
    public class SettingsView : BaseView {
        public signal void connection_requested ();

        private Entry server_entry;
        private Entry user_entry;
        private Entry pass_entry;
        private Button connect_button;

        private IConfig config;

        public SettingsView (IConfig config) {
            Object (orientation: Orientation.VERTICAL, spacing: 6);

            this.config = config;

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            Box box = new Box (Orientation.VERTICAL, 6);

            box.get_style_context ().add_class ("conn-box");

            append (box);

            server_entry = new Entry ();
            server_entry.placeholder_text = "Navidrome URL";

            user_entry = new Entry ();
            user_entry.placeholder_text = "Username";

            pass_entry = new Entry ();
            pass_entry.placeholder_text = "Password";
            pass_entry.visibility = false;

            connect_button = new Button.with_label ("Connect");

            box.append (new Label ("Navidrome URL"));
            box.append (server_entry);
            box.append (new Label ("Username"));
            box.append (user_entry);
            box.append (new Label ("Password"));
            box.append (pass_entry);
            box.append (connect_button);
        }

        private void connect_signals () {
            connect_button.clicked.connect (() => connection_requested ());

            config.bind_property (
                "base_url", 
                server_entry, 
                "text", 
                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE
            );

            config.bind_property (
                "user", 
                user_entry, 
                "text", 
                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE
            );

            config.bind_property (
                "pass", 
                pass_entry, 
                "text", 
                GLib.BindingFlags.BIDIRECTIONAL | GLib.BindingFlags.SYNC_CREATE
            );
        }
    }
}
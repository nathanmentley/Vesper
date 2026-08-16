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

using PiPod.Core;
using PiPod.Core.Models;
using PiPod.Core.Utils;

namespace PiPod.Views {
    public class SettingsView : BaseView {
        public signal void connection_requested ();

        private EntryRow server_entry;
        private EntryRow user_entry;
        private PasswordEntryRow pass_entry;

        private Button connect_button;

        private IConfig config;

        public SettingsView (IConfig config) {
            Object (
                orientation: Orientation.VERTICAL,
                spacing: 0
            );

            this.config = config;

            build_ui ();
            connect_signals ();
        }

        private void build_ui () {
            /*
             * ---------------------------------------------------------
             * Content
             * ---------------------------------------------------------
             */

            var content =
                new Gtk.Box (
                    Orientation.VERTICAL,
                    0
                );

            content.hexpand = true;
            content.vexpand = true;

            /*
             * ---------------------------------------------------------
             * Navidrome preferences
             * ---------------------------------------------------------
             */

            var navidrome_group =
                new Adw.PreferencesGroup ();

            navidrome_group.title =
                "Navidrome";

            navidrome_group.description =
                "Connect PiPod to your Navidrome server.";

            /*
             * ---------------------------------------------------------
             * Server URL
             * ---------------------------------------------------------
             */

            server_entry =
                new Adw.EntryRow ();

            server_entry.title =
                "Server URL";

            server_entry.input_purpose =
                InputPurpose.URL;

            navidrome_group.add (
                server_entry
            );

            /*
             * ---------------------------------------------------------
             * Username
             * ---------------------------------------------------------
             */

            user_entry =
                new Adw.EntryRow ();

            user_entry.title =
                "Username";

            user_entry.input_purpose =
                InputPurpose.FREE_FORM;

            navidrome_group.add (
                user_entry
            );

            /*
             * ---------------------------------------------------------
             * Password
             * ---------------------------------------------------------
             */

            pass_entry =
                new Adw.PasswordEntryRow ();

            pass_entry.title =
                "Password";

            navidrome_group.add (
                pass_entry
            );

            content.append (
                navidrome_group
            );

            /*
             * ---------------------------------------------------------
             * Connect button
             * ---------------------------------------------------------
             *
             * This deliberately lives outside the PreferencesGroup.
             *
             * The fields are settings.
             * The button is an action.
             *
             * Keeping those concepts visually separate makes the
             * interface feel much less like a pile of form controls.
             */

            var button_box =
                new Gtk.Box (
                    Orientation.HORIZONTAL,
                    0
                );

            button_box.halign =
                Align.CENTER;

            button_box.margin_top =
                12;

            button_box.margin_bottom =
                12;

            connect_button =
                new Gtk.Button.with_label (
                    "Connect"
                );

            connect_button.add_css_class (
                "suggested-action"
            );

            connect_button.add_css_class (
                "pill"
            );

            connect_button.width_request =
                140;

            button_box.append (
                connect_button
            );

            content.append (
                button_box
            );

            /*
             * ---------------------------------------------------------
             * Mount
             * ---------------------------------------------------------
             */

            append (
                content
            );
        }

        private void connect_signals () {
            /*
             * ---------------------------------------------------------
             * Connect
             * ---------------------------------------------------------
             */

            connect_button.clicked.connect (() => {
                connection_requested ();
            });

            /*
             * ---------------------------------------------------------
             * Configuration bindings
             * ---------------------------------------------------------
             */

            config.bind_property (
                "base_url",
                server_entry,
                "text",
                GLib.BindingFlags.BIDIRECTIONAL |
                GLib.BindingFlags.SYNC_CREATE
            );

            config.bind_property (
                "user",
                user_entry,
                "text",
                GLib.BindingFlags.BIDIRECTIONAL |
                GLib.BindingFlags.SYNC_CREATE
            );

            config.bind_property (
                "pass",
                pass_entry,
                "text",
                GLib.BindingFlags.BIDIRECTIONAL |
                GLib.BindingFlags.SYNC_CREATE
            );
        }
    }
}
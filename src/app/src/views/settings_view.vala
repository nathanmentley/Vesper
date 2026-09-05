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
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

using Vesper.Service.Settings;

using Vesper.App.Utils;

namespace Vesper.App.Views {
    public class SettingsView : BaseView {
        public signal void connection_requested ();

        private Button connect_button;
        private Button about_button;

        private SettingsService settings_service;

        private Gee.HashMap<string, Adw.EntryRow> setting_rows;

        public SettingsView (SettingsService settings_service, Gtk.Window parent_window) {
            base (parent_window);

            this.settings_service = settings_service;

            this.setting_rows =
                new Gee.HashMap<string, Adw.EntryRow> ();

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
             * Settings providers
             * ---------------------------------------------------------
             */

            var setting_definitions = settings_service.get_setting_definitions ();
            foreach (var provider in setting_definitions.keys) {
                var group =
                    create_provider_group (
                        provider,
                        setting_definitions.get (provider)
                    );

                content.append (
                    group
                );
            }

            /*
             * ---------------------------------------------------------
             * Connect button
             * ---------------------------------------------------------
             *
             * Settings are displayed above.
             * Connecting is an action, so it deliberately lives
             * outside the PreferencesGroups.
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
                    "Save"
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

            about_button =
                new Gtk.Button.with_label (
                    "About"
                );

            about_button.add_css_class (
                "pill"
            );

            about_button.width_request =
                140;

            button_box.append (
                about_button
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

        private Adw.PreferencesGroup create_provider_group (
            PluginKey provider,
            Gee.List<SettingDefinition> definitions
        ) {
            var group =
                new Adw.PreferencesGroup ();

            group.title =
                provider.source;

            foreach (var definition in definitions) {
                var row =
                    create_setting_row (
                        provider,
                        definition
                    );

                if (row != null) {
                    group.add (
                        row
                    );
                }
            }

            return group;
        }

        private Adw.PreferencesRow? create_setting_row (
            PluginKey provider,
            SettingDefinition definition
        ) {
            switch (definition.setting_type) {
                case SettingType.STRING:
                    return create_string_row (
                        provider,
                        definition
                    );

                case SettingType.PASSWORD:
                    return create_password_row (
                        provider,
                        definition
                    );

                case SettingType.DIRECTORY:
                    return create_directory_row (
                        provider,
                        definition
                    );

                default:
                    warning (
                        "Unknown setting type for '%s'",
                        definition.key
                    );

                    return null;
            }
        }

        private Adw.EntryRow create_string_row (
            PluginKey provider,
            SettingDefinition definition
        ) {
            var row =
                new Adw.EntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private Adw.PasswordEntryRow create_password_row (
            PluginKey provider,
            SettingDefinition definition
        ) {
            var row =
                new Adw.PasswordEntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private Adw.EntryRow create_directory_row (
            PluginKey provider,
            SettingDefinition definition
        ) {
            /*
             * For now DIRECTORY behaves like a string.
             *
             * This can later become an Adw.ActionRow with a
             * Gtk.FileDialog folder picker.
             */

            var row =
                new Adw.EntryRow ();

            row.title =
                definition.name;

            if (definition.description != "") {
                row.tooltip_text =
                    definition.description;
            }

            register_setting_row (
                provider,
                definition,
                row
            );

            return row;
        }

        private void register_setting_row (
            PluginKey provider,
            SettingDefinition definition,
            Adw.EntryRow row
        ) {
            setting_rows.set (
                get_setting_id (
                    provider,
                    definition
                ),
                row
            );
        }

        /*
         * -------------------------------------------------------------
         * Public setting access
         * -------------------------------------------------------------
         */

        public string? get_setting_value (
            PluginKey key,
            SettingDefinition definition
        ) {
            var row = get_setting_row (key, definition);

            if (row == null) {
                return null;
            }

            return row.text;
        }

        public void set_setting_value (
            PluginKey key,
            SettingDefinition definition,
            string? value
        ) {
            var row = get_setting_row (key, definition);

            if (row == null) {
                return;
            }

            row.text = value ?? "";
        }

        private Adw.EntryRow? get_setting_row (
            PluginKey key,
            SettingDefinition definition
        ) {
            return setting_rows.get (
                get_setting_id (
                    key,
                    definition
                )
            );
        }

        /*
         * -------------------------------------------------------------
         * Setting identity
         * -------------------------------------------------------------
         *
         * Setting keys are only unique within a plugin.
         *
         * For example:
         *
         *     navidrome/server_url
         *     jellyfin/server_url
         *
         * are different settings.
         */

        private string get_setting_id (
            PluginKey key,
            SettingDefinition definition
        ) {
            return "%s/%s".printf (
                key.id,
                definition.key
            );
        }

        /*
         * -------------------------------------------------------------
         * Signals
         * -------------------------------------------------------------
         */

        private void connect_signals () {
            connect_button.clicked.connect (() => {
                connection_requested ();
            });

            about_button.clicked.connect (() => {
                show_about_dialog ();
            });
        }

        private void show_about_dialog () {
            Gtk.AboutDialog about = new Gtk.AboutDialog ();

            // Standard GNOME window placement rules
            about.transient_for = parent_window;
            about.modal = true;

            // App Metadata
            about.program_name = "Vesper";
            about.version = "0.1.0";
            about.copyright = "© 2026 Nathan Mentley";
            about.comments = "A simple music player for GNOME.";
            about.website = "https://github.com/nathanmentley/vesper";
            about.website_label = "Project Homepage";

            // Set up the GPL License (GTK handles the boilerplate notice text)
            about.license_type = Gtk.License.GPL_3_0;

            // Credits (Expects null-terminated arrays, which Vala wraps nicely)
            about.authors = { "Lead Developer <nathanmentley@gmail.com>", "Nathan Mentley" };
            about.artists = { "Nathan Mentley" };
            about.documenters = { "Nathan Mentley" };

            // App Icon (Uses your app's desktop file icon id)
            about.logo_icon_name = "com.poketrirx.vesper";

            // Show the dialog
            about.present ();
        }
    }
}
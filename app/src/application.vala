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

using PiPod.Core.Models;
using PiPod.Core.Plugins;
using PiPod.Core.Settings;

using PiPod.App.Windows;

namespace PiPod.App {
    public class PipodApplication : Adw.Application {
        private MainWindow? window;

        public PipodApplication () {
            Object (application_id: "com.poketrirx.pipod", flags: ApplicationFlags.FLAGS_NONE);
        }

        protected override void activate () {
            SettingsEngine settings = new SettingsEngineImpl("pipod-config.ini");

            if (window == null) {
                window = new MainWindow (this, settings);

                load_css ();
            }

            window.present ();
        }

        private void load_css () {
            Gtk.CssProvider provider = new Gtk.CssProvider ();

            try {
                provider.load_from_resource ("/com/pipod/app/styles/pipod.css");

                Gdk.Display display = Gdk.Display.get_default ();

                if (display != null) {
                    Gtk.StyleContext.add_provider_for_display (display, provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                }
            } catch (GLib.Error e) {
                warning ("Failed to load CSS: %s", e.message);
            }
        }
    }
}
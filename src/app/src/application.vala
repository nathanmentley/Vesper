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

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

using Vesper.Service.Libraries;
using Vesper.Service.Media;
using Vesper.Service.Playlists;
using Vesper.Service.Plugins;
using Vesper.Service.Settings;

using Vesper.App.Windows;

namespace Vesper.App {
    public class VesperApplication : Adw.Application {
        private MainWindow? window;
        private IOC ioc;

        public VesperApplication () {
            Object (application_id: "com.poketrirx.vesper", flags: ApplicationFlags.HANDLES_OPEN);

            ioc = new IOC ();
        }

        protected override void activate () {
            if (window == null) {
                window = new MainWindow (this, ioc);

                load_css ();
            }

            window.present ();
        }

        protected override void open (GLib.File[] files, string hint) {
            if (window == null) {
                window = new MainWindow (this, ioc);

                load_css ();
            }

            window.present ();

            for (int i = 0; i < files.length; i++) {
                if (!files[i].query_exists ()) {
                    warning ("File does not exist: %s", files[i].get_path ());
                    continue;
                }

                var file = GLib.File.new_for_path (files[i].get_path ());

                // 3. Extract the properly formatted URI
                string gstreamer_url = file.get_uri ();

                window.on_play_requested (
                    new Song (
                        files[i].get_path (),
                        files[i].get_path (),
                        gstreamer_url,
                        0,
                        new Album ("", "", null, null),
                        new Artist("", "", "")
                    )
                );
            }
        }

        private void load_css () {
            Gtk.CssProvider provider = new Gtk.CssProvider ();

            try {
                provider.load_from_resource ("/com/vesper/app/styles/vesper.css");

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
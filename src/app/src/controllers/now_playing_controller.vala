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

using GLib;

using Vesper.Core.Models;

using Vesper.Service.Libraries;

using Vesper.App.Views;

namespace Vesper.App.Controllers {
    public class NowPlayingController : BaseController<NowPlayingView> {
        private LibraryService library_service;

        public NowPlayingController (LibraryService library_service, Gtk.Window parent_window) {
            base(new NowPlayingView (parent_window));

            this.library_service = library_service;
        }

        protected override void connect_view () {
        }
        
        public void set_song (Song song) {
            view.set_song (song);
            view.set_album (song.album);

            set_cover_art.begin (song);
        }

        private async void set_cover_art (Song song) {
            if (song.album.cover == null) {
                view.set_album_art (null);
            }

            try {
                GLib.Bytes? bytes = yield library_service.get_artwork (song);

                if (bytes == null) {
                    view.set_album_art (null);
                }

                view.set_album_art (bytes);
            } catch (GLib.Error e) {
                view.set_album_art (null);
            }
        }
    }
}
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

using PiPod.Clients;
using PiPod.Models;
using PiPod.Views;

namespace PiPod.Controllers {
    public class NowPlayingController : BaseController<NowPlayingView> {
        private INavidromeClient navidrome;

        public NowPlayingController (INavidromeClient navidrome) {
            base(new NowPlayingView ());

            this.navidrome = navidrome;
        }

        protected override void connect_view () {
        }
        
        public void set_song (Song song) {
            view.set_song (song);
            view.set_album (song.album);
            
            if (song.album.cover != null) {
                try {
                    navidrome.get_cover_bytes_async (song.album.cover, view.set_album_art);
                } catch (GLib.Error e) {
                    view.set_album_art (null);
                }
            } else {
                view.set_album_art (null);
            }
        }
    }
}
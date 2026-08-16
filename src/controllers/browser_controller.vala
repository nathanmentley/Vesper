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
    public class BrowserController : BaseController<BrowserView> {
        public signal void play_requested (Song song);

        private INavidromeClient navidrome;

        public BrowserController (INavidromeClient navidrome) {
            base(new BrowserView ());

            this.navidrome = navidrome;
        }

        protected override void connect_view () {
            view.artist_selected.connect (load_albums);

            view.album_selected.connect (load_album);

            view.song_selected.connect (play_song);
        }

        public void load_artists () {
            view.clear ();

            try {
                navidrome.get_artists (view.add_artist);
            } catch (GLib.Error e) {
            }
        }

        private void load_albums (Artist artist) {
            view.clear_albums ();
            view.clear_songs ();

            try {
                navidrome.get_albums (artist.id, view.add_album);
            } catch (GLib.Error e) {
            }
        }

        private void load_album (Album album) {
            view.clear_songs ();

            try {
                navidrome.get_songs (album, view.add_song);
            } catch (GLib.Error e) {
            }
        }

        private void play_song (Song song) {
            if (song.stream_url == null) {
                return;
            }

            play_requested (song);
        }
    }
}
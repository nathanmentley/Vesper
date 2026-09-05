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
    public class BrowserController : BaseController<BrowserView> {
        public signal void play_requested (Song song);
        private LibraryService library_service;

        public BrowserController (LibraryService library_service, Gtk.Window parent_window) {
            base (
                new BrowserView (parent_window)
            );

            this.library_service = library_service;
        }

        protected override void connect_view () {
            view.artist_selected.connect (artist => load_albums.begin(artist));

            view.album_selected.connect ((artist, album) => load_album.begin(artist, album));

            view.song_selected.connect (play_song);

            view.add_album_to_queue_requested.connect (
                (album, songs) => {
                    foreach (Song song in songs) {
                        play_requested (song);
                    }
                }
            );
        }

        public async void load_artists () {
            view.clear ();
            
            Gee.List<Artist> artists = yield library_service.get_artists ();

            foreach (Artist artist in artists) {
                view.add_artist(artist);
            }
        }

        private async void load_albums (Artist artist) {
            view.clear_albums ();
            view.clear_songs ();

            Gee.List<Album> albums = yield library_service.get_albums (artist.library_id, artist.id);

            foreach (Album album in albums) {
                view.add_album (artist, album);
            }
        }

        private async void load_album (Artist artist, Album album) {
            view.clear_songs ();

            // Todo only look up from library of album
            Gee.List<Song> songs = yield library_service.get_tracks (artist.library_id, artist.id, album.id);

            foreach (Song song in songs) {
                view.add_song (song);
            }
        }

        private void play_song (Song song) {
            if (song.stream_url == null) {
                warning (
                    "Cannot play song '%s': no stream URL",
                    song.title
                );

                return;
            }

            play_requested (song);
        }
    }
}
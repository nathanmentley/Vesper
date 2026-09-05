/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

using Gee;
using Vesper.Core.Models;

namespace Vesper.Core.Plugins {
    public interface MusicLibrary : Plugin, Object {
        public abstract string get_id ();

        public abstract async Gee.List<Artist> get_artists ();

        public abstract async Gee.List<Album> get_albums (string artist_id);

        public abstract async Gee.List<Song> get_tracks (string album_id);

        public abstract async GLib.Bytes? get_artwork (Song song);
    }
}
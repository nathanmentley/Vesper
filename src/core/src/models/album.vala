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
using Gee;

namespace Vesper.Core.Models {
    public class Album : Object {
        public string id { get; construct; }
        public string name { get; construct; }
        public string? cover { get; construct; }
        public string? year { get; construct; }
        public int64? added_at { get; private set; }
        public Gee.List<Genre> genres { get; private set; }
        public string? musicbrainz_release_id { get; construct; }
        public string? musicbrainz_release_group_id { get; construct; }

        public Album (
            string id,
            string name,
            string? cover = null,
            string? year = null,
            Gee.List<Genre>? genres = null,
            string? musicbrainz_release_id = null,
            string? musicbrainz_release_group_id = null,
            int64? added_at = null
        ) {
            Object (
                id: id,
                name: name,
                cover: cover,
                year: year,
                musicbrainz_release_id: musicbrainz_release_id,
                musicbrainz_release_group_id: musicbrainz_release_group_id
            );
            this.added_at = added_at;
            this.genres = genres ?? new Gee.ArrayList<Genre> ();
        }

        public string display_name () {
            if (year != null) {
                return "%s (%s)".printf (name, year);
            }

            return name;
        }
    }
}
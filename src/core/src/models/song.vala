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
    public class Song : Object {
        public string id { get; construct; }
        public string title { get; construct; }
        public string stream_url { get; construct; }
        public int track_number { get; construct; }
        public Album album { get; construct; }
        public int64? added_at { get; private set; }
        public int? duration { get; private set; }
        public int? disc_number { get; private set; }
        public int? year { get; private set; }
        public int? bit_rate { get; private set; }
        public int? bit_depth { get; private set; }
        public int? sample_rate { get; private set; }
        public int? channel_count { get; private set; }
        public int64? file_size { get; private set; }
        public string? content_type { get; construct; }
        public string? file_suffix { get; construct; }
        public int? bpm { get; private set; }
        public string? musicbrainz_recording_id { get; construct; }
        public Gee.List<Genre> genres { get; private set; }

        public Song (
            string id,
            string title,
            string stream_url,
            int track_number,
            Album album,
            int? duration = null,
            int? disc_number = null,
            int? year = null,
            int? bit_rate = null,
            int? bit_depth = null,
            int? sample_rate = null,
            int? channel_count = null,
            int64? file_size = null,
            string? content_type = null,
            string? file_suffix = null,
            int? bpm = null,
            string? musicbrainz_recording_id = null,
            Gee.List<Genre>? genres = null,
            int64? added_at = null
        ) {
            Object (
                id: id,
                title: title,
                stream_url: stream_url,
                track_number: track_number,
                album: album,
                content_type: content_type,
                file_suffix: file_suffix,
                musicbrainz_recording_id: musicbrainz_recording_id
            );
            this.added_at = added_at;
            this.duration = duration;
            this.disc_number = disc_number;
            this.year = year;
            this.bit_rate = bit_rate;
            this.bit_depth = bit_depth;
            this.sample_rate = sample_rate;
            this.channel_count = channel_count;
            this.file_size = file_size;
            this.bpm = bpm;
            this.genres = genres ?? new Gee.ArrayList<Genre> ();
        }
    }
}
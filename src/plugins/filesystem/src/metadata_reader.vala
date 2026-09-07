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

using Gst;
using Gst.PbUtils;

namespace Vesper.Plugins.Filesystem {
    public class MetadataReader : GLib.Object {
        private Gst.PbUtils.Discoverer discoverer;

        public MetadataReader () {
            discoverer = new Gst.PbUtils.Discoverer (5 * Gst.SECOND);
        }

        public TrackMetadata read (GLib.File file) {
            var metadata = new TrackMetadata ();

            try {
                var info = discoverer.discover_uri (file.get_uri ());
                var tags = info.get_tags ();

                if (tags != null) {
                    string value;

                    if (tags.get_string (Gst.Tags.TITLE, out value)) {
                        metadata.title = value;
                    }

                    if (tags.get_string (Gst.Tags.ARTIST, out value)) {
                        metadata.artist = value;
                    }

                    if (tags.get_string (Gst.Tags.ALBUM, out value)) {
                        metadata.album = value;
                    }

                    if (tags.get_string (
                        Gst.Tags.ALBUM_ARTIST,
                        out value
                    )) {
                        metadata.album_artist = value;
                    }

                    if (tags.get_string (Gst.Tags.GENRE, out value)) {
                        metadata.genre = value;
                    }

                    uint uint_value;

                    if (tags.get_uint (
                        Gst.Tags.TRACK_NUMBER,
                        out uint_value
                    )) {
                        metadata.track_number = uint_value;
                    }

                    if (tags.get_uint (
                        Gst.Tags.ALBUM_VOLUME_NUMBER,
                        out uint_value
                    )) {
                        metadata.disc_number = uint_value;
                    }

                    GLib.Date? date = null;

                    if (tags.get_date (
                        Gst.Tags.DATE,
                        out date
                    ) && date != null) {
                        metadata.year = date.get_year ();
                    }

                    Gst.Sample? sample = null;

                    if (tags.get_sample (
                        Gst.Tags.IMAGE,
                        out sample
                    ) && sample != null) {
                        metadata.artwork = sample_to_bytes (sample);
                    }
                }

                var duration = info.get_duration ();

                if (duration != Gst.CLOCK_TIME_NONE) {
                    metadata.duration = duration;
                }

            } catch (Error e) {
                warning (
                    "Failed to read metadata from '%s': %s",
                    file.get_path (),
                    e.message
                );
            }

            return metadata;
        }

        private static GLib.Bytes? sample_to_bytes (
            Gst.Sample sample
        ) {
            var buffer = sample.get_buffer ();

            if (buffer == null) {
                return null;
            }

            Gst.MapInfo map;

            if (!buffer.map (
                out map,
                Gst.MapFlags.READ
            )) {
                return null;
            }

            try {
                // Copy the data because the Gst.Buffer is going
                // to be unmapped when we leave this scope.
                return new GLib.Bytes (
                    map.data
                );
            } finally {
                buffer.unmap (map);
            }
        }
    }
}
/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 */

namespace Vesper.Plugins.Filesystem {
    public class TrackMetadata : GLib.Object {
        public string? title { get; set; }
        public string? artist { get; set; }
        public string? album { get; set; }
        public string? album_artist { get; set; }
        public string? genre { get; set; }

        public uint? track_number { get; set; }
        public uint? disc_number { get; set; }
        public uint? year { get; set; }

        public uint64? duration { get; set; }

        public GLib.Bytes? artwork { get; set; }
    }
}
/*
 * Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
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

using Gee;
using GLib;
using Json;
using Soup;

using Vesper.Core.Models;
using Vesper.Core.Plugins;
using Vesper.Core.Settings;

namespace Vesper.Plugins.Lrclib {
    public sealed class LrclibLyricsProvider :
        GLib.Object,
        Vesper.Core.Plugins.Plugin,
        LyricsProvider,
        ConfigurablePlugin {

        private const string API_URL = "https://lrclib.net";

        public PluginKey key {
            owned get {
                return new PluginKey ("lrclib-1", "LRCLIB");
            }
        }

        public LrclibLyricsProvider () {
        }

        public void configure (SettingsEngine settings) {
        }

        public async Lyrics? get_lyrics (Song song) {
            // Prefer the MusicBrainz recording ID when available.
            if (song.musicbrainz_recording_id != null &&
                song.musicbrainz_recording_id.strip () != "") {

                try {
                    return yield get_by_recording_id (
                        song.musicbrainz_recording_id
                    );
                } catch (Error e) {
                    warning (
                        "LRCLIB lookup by MusicBrainz ID failed: %s",
                        e.message
                    );
                }
            }

            // Fall back to artist/title/album/duration lookup.
            try {
                return yield get_by_track (
                    song.artist.name,
                    song.title,
                    song.album.name,
                    song.duration
                );
            } catch (Error e) {
                warning (
                    "LRCLIB lookup failed for '%s' by '%s': %s",
                    song.title,
                    song.artist.name,
                    e.message
                );
            }

            return null;
        }

        private async Lyrics get_by_recording_id (
            string recording_id
        ) throws Error {
            string encoded_id = Uri.escape_string (
                recording_id,
                null,
                true
            );

            string url = "%s/api/get?%s".printf (
                API_URL,
                "track_name=&artist_name=&album_name=&duration=&"
                + "recording_mbid=%s".printf (encoded_id)
            );

            return yield request_lyrics (url);
        }

        private async Lyrics get_by_track (
            string artist_name,
            string track_name,
            string? album_name,
            int? duration
        ) throws Error {
            var query = new StringBuilder ();

            query.append ("artist_name=");
            query.append (
                Uri.escape_string (
                    artist_name,
                    null,
                    true
                )
            );

            query.append ("&track_name=");
            query.append (
                Uri.escape_string (
                    track_name,
                    null,
                    true
                )
            );

            if (album_name != null &&
                album_name.strip () != "") {

                query.append ("&album_name=");
                query.append (
                    Uri.escape_string (
                        album_name,
                        null,
                        true
                    )
                );
            }

            if (duration != null) {
                query.append (
                    "&duration=%d".printf (duration)
                );
            }

            string url = "%s/api/get?%s".printf (
                API_URL,
                query.str
            );

            return yield request_lyrics (url);
        }

        private async Lyrics request_lyrics (
            string url
        ) throws Error {
            var session = new Soup.Session ();
            session.user_agent = "Vesper/1.0";

            Soup.Message message = new Soup.Message (
                "GET",
                url
            );

            message.request_headers.append (
                "Accept",
                "application/json"
            );

            Bytes response = yield session.send_and_read_async (
                message,
                Priority.DEFAULT,
                null
            );

            uint status = message.status_code;

            if (status == Soup.Status.NOT_FOUND) {
                throw new IOError.NOT_FOUND (
                    "Lyrics not found"
                );
            }

            if (status < 200 || status >= 300) {
                throw new IOError.FAILED (
                    "LRCLIB returned HTTP status %u",
                    status
                );
            }

            string json = (string) response.get_data ();

            return parse_response (json);
        }

        private Lyrics parse_response (
            string json
        ) throws Error {
            var parser = new Json.Parser ();
            parser.load_from_data (json, -1);

            Json.Node root = parser.get_root ();

            if (root == null ||
                root.get_node_type () != Json.NodeType.OBJECT) {

                throw new IOError.FAILED (
                    "Invalid LRCLIB response"
                );
            }

            Json.Object object = root.get_object ();

            string? synced_lyrics = null;
            string? plain_lyrics = null;

            if (object.has_member ("syncedLyrics") &&
                !object.get_null_member ("syncedLyrics")) {

                synced_lyrics = object.get_string_member (
                    "syncedLyrics"
                );
            }

            if (object.has_member ("plainLyrics") &&
                !object.get_null_member ("plainLyrics")) {

                plain_lyrics = object.get_string_member (
                    "plainLyrics"
                );
            }

            if (synced_lyrics != null &&
                synced_lyrics.strip () != "") {

                return parse_synced_lyrics (
                    synced_lyrics
                );
            }

            if (plain_lyrics != null &&
                plain_lyrics.strip () != "") {

                return parse_plain_lyrics (
                    plain_lyrics
                );
            }

            throw new IOError.NOT_FOUND (
                "LRCLIB returned no lyrics"
            );
        }

        private Lyrics parse_synced_lyrics (
            string lyrics
        ) throws Error {
            var data = new ArrayList<LyricsLine> ();

            string[] lines = lyrics.split ("\n");

            foreach (string line in lines) {
                string trimmed = line.strip ();

                if (trimmed == "") {
                    continue;
                }

                /*
                 * LRC format:
                 *
                 * [00:12.34]Some lyrics
                 *
                 * Multiple timestamps are also supported:
                 *
                 * [00:12.34][00:15.67]Some lyrics
                 */

                var timestamps = new ArrayList<int64?> ();

                int position = 0;

                while (position < trimmed.length &&
                       trimmed[position] == '[') {

                    int closing = trimmed.index_of (
                        "]",
                        position
                    );

                    if (closing < 0) {
                        break;
                    }

                    string timestamp = trimmed.substring (
                        position + 1,
                        closing - position - 1
                    );

                    int64? milliseconds =
                        parse_timestamp (timestamp);

                    if (milliseconds != null) {
                        timestamps.add (
                            milliseconds
                        );
                    }

                    position = closing + 1;
                }

                if (timestamps.size == 0) {
                    continue;
                }

                string text = trimmed.substring (
                    position
                ).strip ();

                if (text == "") {
                    continue;
                }

                foreach (int64 timestamp in timestamps) {
                    data.add (
                        new LyricsLine (
                            timestamp,
                            text
                        )
                    );
                }
            }

            data.sort ((a, b) => {
                if (a.timestamp < b.timestamp) {
                    return -1;
                }

                if (a.timestamp > b.timestamp) {
                    return 1;
                }

                return 0;
            });

            return new Lyrics (data);
        }

        private Lyrics parse_plain_lyrics (
            string lyrics
        ) {
            var data = new ArrayList<LyricsLine> ();

            string[] lines = lyrics.split ("\n");

            foreach (string line in lines) {
                string text = line.strip ();

                if (text == "") {
                    continue;
                }

                /*
                 * Plain lyrics don't have timestamps.
                 *
                 * Use -1 to represent an untimed lyric line.
                 */
                data.add (
                    new LyricsLine (
                        -1,
                        text
                    )
                );
            }

            return new Lyrics (data);
        }

        private int64? parse_timestamp (
            string timestamp
        ) {
            string[] parts = timestamp.split (":");

            if (parts.length != 2) {
                return null;
            }

            double minutes;
            double seconds;

            if (!double.try_parse (
                parts[0],
                out minutes
            )) {
                return null;
            }

            if (!double.try_parse (
                parts[1],
                out seconds
            )) {
                return null;
            }

            if (minutes < 0 || seconds < 0) {
                return null;
            }

            return (int64) (
                (minutes * 60.0 + seconds) * 1000.0
            );
        }
    }
}

[ModuleInit]
public void peas_register_types (TypeModule module) {
    Peas.ObjectModule object_module =
        module as Peas.ObjectModule;

    object_module.register_extension_type (
        typeof (LyricsProvider),
        typeof (Vesper.Plugins.Lrclib.LrclibLyricsProvider)
    );
}
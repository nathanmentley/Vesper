using GLib;

namespace Vesper.Core.Models {
    public class SongStats : Object {
        public string song_id { get; construct; }
        public int play_count { get; construct; }
        public int64 total_play_seconds { get; construct; }
        public int64? last_played { get; private set; }

        public SongStats (
            string song_id,
            int play_count,
            int64 total_play_seconds,
            int64? last_played
        ) {
            Object (
                song_id: song_id,
                play_count: play_count,
                total_play_seconds: total_play_seconds
            );
            this.last_played = last_played;
        }
    }
}

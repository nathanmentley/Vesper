using GLib;

namespace Vesper.Core.Models {
    public class PlayHistoryEntry : Object {
        public int64 id { get; construct; }
        public string song_id { get; construct; }
        public int64 played_at { get; construct; }
        public int duration { get; construct; }
        public bool completed { get; construct; }

        public PlayHistoryEntry (
            int64 id,
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) {
            Object (
                id: id,
                song_id: song_id,
                played_at: played_at,
                duration: duration,
                completed: completed
            );
        }
    }
}

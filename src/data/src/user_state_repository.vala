using Gee;
using Vesper.Core.Models;

namespace Vesper.Data {
    public interface UserStateRepository : Object {
        public abstract SongStats? get (string song_id) throws Error;

        public abstract void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error;

        public abstract void append (PlayHistoryEntry entry) throws Error;

        public abstract Gee.List<PlayHistoryEntry> get_recent (
            int limit = 50
        ) throws Error;

        public abstract void cleanup (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error;
    }
}

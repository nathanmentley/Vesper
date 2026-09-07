using Gee;
using Vesper.Core.Models;

namespace Vesper.Service.UserState {
    public interface UserStateService : Object {
        public abstract void record_play (
            string song_id,
            int64 played_at,
            int duration,
            bool completed
        ) throws Error;

        public abstract SongStats? get_song_stats (string song_id) throws Error;

        public abstract Gee.List<PlayHistoryEntry> get_recently_played (
            int limit = 50
        ) throws Error;

        public abstract void cleanup_play_history (
            int64 retention_seconds = 90 * 24 * 60 * 60,
            int maximum_events = 1000
        ) throws Error;

        public abstract bool is_favorite (string song_id) throws Error;

        public abstract void favorite (string song_id) throws Error;

        public abstract void unfavorite (string song_id) throws Error;

        public abstract async Gee.List<Song> get_favorites () throws Error;
    }
}

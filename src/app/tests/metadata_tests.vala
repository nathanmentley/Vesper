using GLib;
using Gee;

using Vesper.Core.Models;
using Vesper.Data;

namespace Vesper.App.Tests {
    void test_user_state_round_trip_and_cleanup () {
        string path = "/tmp/vesper-user-state-test.db";
        FileUtils.remove (path);

        try {
            var database = new DatabaseImpl (path);
            var library_repository = new LibraryRepositoryImpl (database);
            var repository = new UserStateRepositoryImpl (database);
            library_repository.save_library ("library-1", "provider-1", "Library", 0);
            library_repository.save_artist (
                "library-1",
                new Artist ("artist-1", "Artist A", "library-1")
            );
            library_repository.save_album (
                "library-1",
                "artist-1",
                new Album ("album-1", "Album A")
            );
            library_repository.save_song (
                "library-1",
                "artist-1",
                new Song (
                    "song-1",
                    "Song A",
                    "stream://song-1",
                    1,
                    new Album ("album-1", "Album A")
                )
            );

            int64 now = new DateTime.now_utc ().to_unix ();
            repository.record_play ("song-1", now - 10, 12, false);
            repository.record_play ("song-1", now - 5, 34, true);

            var stats = repository.get ("song-1");
            assert (stats != null);
            assert (stats.play_count == 2);
            assert (stats.total_play_seconds == 46);
            assert (stats.last_played == now - 5);
            assert (repository.get_recent (10).size == 2);
            assert (repository.get_recent (10)[0].played_at == now - 5);
            assert (repository.get_recent (10)[0].completed);

            var reloaded_database = new DatabaseImpl (path);
            var reloaded_repository = new UserStateRepositoryImpl (reloaded_database);
            assert (reloaded_repository.get ("song-1").play_count == 2);
            assert (reloaded_repository.get_recent (10).size == 2);

            for (int index = 0; index < 5; index++) {
                reloaded_repository.append (
                    new PlayHistoryEntry (
                        0,
                        "song-1",
                        now + index,
                        1,
                        false
                    )
                );
            }

            reloaded_repository.cleanup (100, 3);
            assert (reloaded_repository.get_recent (10).size == 3);
            assert (reloaded_repository.get_recent (10)[0].played_at == now + 4);
            assert (reloaded_repository.get ("song-1").play_count == 2);
            reloaded_repository.cleanup (100, 3);
            assert (reloaded_repository.get_recent (10).size == 3);

            reloaded_database.exec ("DELETE FROM songs WHERE id = 'song-1';");
            assert (reloaded_repository.get ("song-1") == null);
            assert (reloaded_repository.get_recent (10).size == 0);
        } catch (Error e) {
            warning ("User state test failed: %s", e.message);
            assert_not_reached ();
        }

        FileUtils.remove (path);
    }

    void test_metadata_round_trip () {
        string path = "/tmp/vesper-metadata-test.db";
        FileUtils.remove (path);

        try {
            var database = new DatabaseImpl (path);
            var repository = new LibraryRepositoryImpl (database);
            var artist_genres = new ArrayList<Genre> ();
            artist_genres.add (new Genre ("Punk"));
            artist_genres.add (new Genre ("Hardcore"));
            var artist = new Artist ("artist-1", "Artist A", "library-1", artist_genres);
            var album_genres = new ArrayList<Genre> ();
            album_genres.add (new Genre ("Political"));
            var album = new Album ("album-1", "Album A", null, null, album_genres);
            var song_genres = new ArrayList<Genre> ();
            song_genres.add (new Genre ("Punk"));
            song_genres.add (new Genre ("Hardcore"));
            song_genres.add (new Genre ("Political"));
            var song = new Song (
                "song-1",
                "Song A",
                "https://example.test/song-1",
                1,
                album,
                null,
                null,
                null,
                320,
                null,
                44100,
                2,
                null,
                "audio/mpeg",
                "mp3",
                null,
                null,
                song_genres
            );

            repository.save_library ("library-1", "provider-1", "Library", 0);
            repository.save_artist ("library-1", artist);
            repository.save_album ("library-1", artist.id, album);
            repository.save_song ("library-1", artist.id, song);

            var loaded_artist = repository.get_artists ("library-1")[0];
            var loaded_album = repository.get_albums (artist.id)[0];
            var loaded_song = repository.get_tracks (album.id)[0];

            assert (loaded_artist.added_at != null);
            assert (loaded_album.added_at != null);
            assert (loaded_song.added_at != null);

            int64 artist_added_at = loaded_artist.added_at;
            int64 album_added_at = loaded_album.added_at;
            int64 song_added_at = loaded_song.added_at;
            repository.save_artist ("library-1", artist);
            repository.save_album ("library-1", artist.id, album);
            repository.save_song ("library-1", artist.id, song);
            assert (repository.get_artists ("library-1")[0].added_at == artist_added_at);
            assert (repository.get_albums (artist.id)[0].added_at == album_added_at);
            assert (repository.get_tracks (album.id)[0].added_at == song_added_at);

            assert (loaded_artist.genres.size == 2);
            assert (loaded_album.genres.size == 1);
            assert (loaded_album.genres[0].name == "Political");
            assert (loaded_song.genres.size == 3);
            assert (loaded_song.bit_rate == 320);
            assert (loaded_song.sample_rate == 44100);
            assert (loaded_song.channel_count == 2);
            assert (loaded_song.duration == null);

            repository.save_song_genres (song.id, new ArrayList<Genre> ());
            assert (repository.get_song_genres (song.id).size == 0);

            var reloaded_database = new DatabaseImpl (path);
            var reloaded_repository = new LibraryRepositoryImpl (reloaded_database);
            assert (reloaded_repository.get_track ("library-1", song.id).genres.size == 0);
        } catch (Error e) {
            warning ("Metadata round trip failed: %s", e.message);
            assert_not_reached ();
        }

        FileUtils.remove (path);
    }

    public void register_metadata_tests () {
        Test.add_func (
            "/vesper/data/metadata/round_trip",
            test_metadata_round_trip
        );
        Test.add_func (
            "/vesper/data/user_state/round_trip_and_cleanup",
            test_user_state_round_trip_and_cleanup
        );
    }
}

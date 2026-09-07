using GLib;
using Gee;

using Vesper.Core.Models;
using Vesper.Data;

namespace Vesper.App.Tests {
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
    }
}

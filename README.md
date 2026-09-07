# Vesper

**A music player for music you control.**

Vesper is an open-source desktop music player for Linux, written in [Vala](https://vala.dev/) with GTK 4 and libadwaita. It brings local music and Subsonic-compatible servers such as [Navidrome](https://www.navidrome.org/) together in a native desktop player.

Vesper is designed around your music library, not a streaming service. Your library, your playlists, your queue, and your listening history stay under your control.

> 🦇 Vesper is an early-stage project. It is usable for day-to-day music playback, but the application and its interfaces are still evolving.

## Features

* Browse artists, albums, songs, genres, and recently added music
* Connect to Subsonic-compatible servers
* Play music from local folders
* Stream remote music through GStreamer
* Build and manage a persistent play queue
* Play, pause, stop, seek, skip, shuffle, and repeat
* Create and manage playlists
* Favorite songs
* Track play history and listening statistics
* Dynamic mixes such as Favorites, Recently Played, Recently Added, and Most Played
* Responsive desktop and mobile-friendly layouts
* Extensible providers and playback engines through libpeas plugins
* Store application state locally in SQLite

## Plugins

Vesper uses plugins to separate music library providers from the playback engine.

| Plugin         | Role                                                                              |
| -------------- | --------------------------------------------------------------------------------- |
| **Filesystem** | Reads a local music directory and its metadata                                    |
| **Subsonic**   | Connects to Subsonic-compatible servers and provides music, metadata, and artwork |
| **GStreamer**  | Provides playback for local and remote media                                      |

This architecture allows additional providers and playback implementations to be added without coupling them to the rest of the application.

## Requirements

Vesper requires:

* [Meson](https://mesonbuild.com/) 1.11 or newer
* [Ninja](https://ninja-build.org/)
* [Vala](https://vala.dev/)
* [GTK 4](https://www.gtk.org/)
* [libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)
* [GStreamer](https://gstreamer.freedesktop.org/) and its base/audio/video plugins
* [libsoup 3](https://libsoup.gnome.org/)
* [libgee](https://wiki.gnome.org/Projects/Libgee)
* [libpeas 2](https://gitlab.gnome.org/GNOME/libpeas)
* [gdk-pixbuf](https://docs.gtk.org/gdk-pixbuf/)
* [libxml2](https://gitlab.gnome.org/GNOME/libxml2)
* [SQLite](https://www.sqlite.org/)

To use the Subsonic provider, you also need an accessible Subsonic-compatible server. Vesper does not provide a server.

## Build on Linux

### Ubuntu

Install the development dependencies:

```bash
sudo apt update
sudo apt install \
    build-essential meson ninja-build valac pkg-config \
    libgee-0.8-dev libglib2.0-dev libgtk-4-dev \
    libadwaita-1-dev libpeas-2-dev \
    libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    libsoup-3.0-dev libgdk-pixbuf-2.0-dev libxml2-dev \
    libsqlite3-dev
```

Configure and compile from the repository root:

```bash
meson setup build
meson compile -C build
```

Run Vesper:

```bash
./build/src/app/vesper
```

Run the test suite:

```bash
meson test -C build --verbose
```

For a clean build, remove the `build` directory and run `meson setup build` again.

### Fedora

Install the development dependencies:

```bash
sudo dnf install \
    gcc gcc-c++ meson ninja-build vala pkgconf-pkg-config \
    libgee-devel glib2-devel gtk4-devel \
    libadwaita-devel libpeas-devel \
    gstreamer1-devel gstreamer1-plugins-base-devel \
    libsoup3-devel gdk-pixbuf2-devel libxml2-devel \
    sqlite-devel
```

Then configure and compile from the repository root:

```bash
meson setup build
meson compile -C build
```

Run Vesper:

```bash
./build/src/app/vesper
```

Run the test suite:

```bash
meson test -C build --verbose
```

Other Linux distributions should provide equivalent packages for the dependencies listed in the [Requirements](#requirements) section.

## Build on macOS (Experimental)

Vesper can currently be built on macOS using [Homebrew](https://brew.sh/), but macOS support is **experimental**.

There is currently no native application bundle, installer, or distribution package.

Install the required dependencies:

```bash
brew install \
    meson ninja pkgconf vala \
    gtk4 libadwaita \
    gstreamer \
    libsoup \
    libgee \
    libpeas \
    gdk-pixbuf \
    libxml2 \
    sqlite
```

Then configure and compile from the repository root:

```bash
meson setup build
meson compile -C build
```

Run Vesper:

```bash
./build/src/app/vesper
```

The macOS build is primarily intended for development and testing. Platform-specific issues may remain, particularly around GNOME-oriented runtime behavior, plugin discovery, multimedia integration, and application integration with macOS.

## Configuration

Vesper reads `vesper-config.ini` from the current working directory.

Start with the example configuration:

```bash
cp vesper-config.ini.example vesper-config.ini
```

The general settings configure the plugin directory and SQLite database location. Built-in providers use the following sections:

```ini
[general]
plugin-directory=./build/src/plugins
database-directory=./data.db

[subsonic-1]
server-url=https://navidrome.example
username=username
password=password

[filesystem-1]
directory=/path/to/music
```

Keep credentials in your local configuration and do not commit them.

The application currently resolves relative paths from its working directory, so run it from the repository root unless you configure absolute paths.

## Project layout

```text
src/
├── app/       GTK application, views, controllers, and tests
├── core/      Shared models, plugin interfaces, and settings
├── data/      SQLite database and repositories
├── service/   Application services and plugin management
└── plugins/   Filesystem, GStreamer, and Subsonic providers

docs/          Project website
```

The application is organized into core, data, service, and UI layers.

Plugin interfaces live in `src/core`. Implementations are discovered from the configured plugin directory through libpeas.

## Project status

Vesper is under active development.

The core library, playback engine, playlists, metadata, artwork, favorites, listening history, and statistics are implemented.

The next major area of development is smart functionality, including:

* Dynamic mixes
* Search
* Playlist actions
* Radio-style playback
* Improved recommendations

The interface is intentionally still evolving. A broader UI and visual polish pass will happen after the current functionality has settled.

## License

Vesper is licensed under the [GNU General Public License v3.0 or later](LICENSE).

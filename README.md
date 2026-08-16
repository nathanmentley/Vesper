# PiPod

PiPod is a desktop music player written in [Vala](https://vala.dev/) using GTK 4 and libadwaita. It connects to Subsonic-compatible music servers such as Navidrome and provides a native desktop interface for browsing and playing music.

## Features

- Browse artists, albums, and songs from a Subsonic-compatible server
- Stream music using GStreamer
- Queue and manage songs for playback
- Playlist support
- Now Playing view
- Playback controls including:
  - Play
  - Pause
  - Stop
  - Previous / next
  - Seeking
  - Shuffle
  - Repeat
  - Volume control
- Responsive desktop and narrow-window layouts
- GTK 4 and libadwaita interface
- Configurable Navidrome / Subsonic server connection
- Unit tests using Meson

## Requirements

PiPod is built with:

- [Meson](https://mesonbuild.com/)
- [Ninja](https://ninja-build.org/)
- [Vala](https://vala.dev/)
- [GTK 4](https://www.gtk.org/)
- [libadwaita](https://gnome.pages.gitlab.gnome.org/libadwaita/)
- [GStreamer](https://gstreamer.freedesktop.org/)
- [libsoup 3](https://libsoup.gnome.org/)
- [libgee](https://wiki.gnome.org/Projects/Libgee)
- [gdk-pixbuf](https://docs.gtk.org/gdk-pixbuf/)
- [libxml2](https://gitlab.gnome.org/GNOME/libxml2)

A Subsonic-compatible server such as Navidrome is required for streaming music.

## Linux

### Ubuntu

On a recent Ubuntu release, install the build dependencies:

```bash
sudo apt update

sudo apt install \
    build-essential \
    meson \
    ninja-build \
    valac \
    pkg-config \
    libgee-0.8-dev \
    libglib2.0-dev \
    libgtk-4-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libsoup-3.0-dev \
    libgdk-pixbuf-2.0-dev \
    libxml2-dev \
    libadwaita-1-dev
```

Then configure and build:

```bash
meson setup build
meson compile -C build
```

Run PiPod:

```bash
./build/pipod
```

Run the test suite:

```bash
meson test -C build
```

If you are using a minimal Ubuntu installation or a different Ubuntu release, package names may vary slightly.

### Fedora

Fedora provides the required GTK, GNOME, GStreamer, and Vala development packages through its standard repositories.

```bash
sudo dnf install \
    gcc \
    gcc-c++ \
    meson \
    ninja-build \
    vala \
    pkg-config \
    libgee-devel \
    glib2-devel \
    gtk4-devel \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel \
    libsoup3-devel \
    gdk-pixbuf2-devel \
    libxml2-devel \
    libadwaita-devel
```

Then:

```bash
meson setup build
meson compile -C build
./build/pipod
```

Run tests with:

```bash
meson test -C build
```

### Arch Linux

Install the required packages:

```bash
sudo pacman -S \
    base-devel \
    meson \
    ninja \
    vala \
    libgee \
    glib2 \
    gtk4 \
    gstreamer \
    gst-plugins-base \
    libsoup3 \
    gdk-pixbuf2 \
    libxml2 \
    libadwaita
```

Then:

```bash
meson setup build
meson compile -C build
./build/pipod
```

## macOS

PiPod is primarily developed and targeted for Linux, but GTK 4, libadwaita, GStreamer, and Vala are available on macOS, so building it there is possible.

The easiest starting point is [Homebrew](https://brew.sh/).

Install the required packages:

```bash
brew install \
    meson \
    ninja \
    vala \
    pkg-config \
    libgee \
    glib \
    gtk4 \
    gstreamer \
    gst-plugins-base \
    libsoup \
    gdk-pixbuf \
    libxml2 \
    libadwaita
```

Then configure the project:

```bash
meson setup build
meson compile -C build
```

Run it with:

```bash
./build/app/pipod
```

### macOS notes

macOS support is currently best considered experimental.

GTK applications on macOS depend on the GTK macOS backend and the corresponding native integration. GStreamer also requires its appropriate macOS plugins for the media formats you want to play.

The project does not currently provide a native macOS application bundle or installer. The Meson build currently produces the executable directly.

## Other Platforms

### Windows

GTK 4, libadwaita, GStreamer, and Vala can be made to work on Windows, but PiPod is currently designed primarily around the Linux/GNOME environment.

Windows support would likely require additional work around:

- GTK/GNOME runtime packaging
- GStreamer runtime and plugin distribution
- Application installation
- Desktop integration
- Windows-specific configuration paths

Windows is therefore not currently a supported target.

### BSD and other Unix-like systems

PiPod may be buildable on other Unix-like systems that provide the required GTK 4, libadwaita, GStreamer, libsoup, and Vala dependencies.

No additional platform-specific support is currently provided.

## Building From a Fresh Checkout

After cloning the repository:

```bash
git clone <repository-url>
cd pipod
```

Configure the build:

```bash
meson setup build
```

Compile:

```bash
meson compile -C build
```

Run:

```bash
./build/pipod
```

Run tests:

```bash
meson test -C build
```

For a clean rebuild:

```bash
rm -rf build
meson setup build
meson compile -C build
```

## Installing

The Meson project is configured to install the `pipod` executable.

To install it:

```bash
meson install -C build
```

The installation location depends on the Meson prefix. For a system installation, you can configure the prefix during setup:

```bash
meson setup build --prefix=/usr/local
meson compile -C build
sudo meson install -C build
```

## Development

PiPod uses Meson to build both the application and its unit tests.

The project is organized roughly as follows:

```text
src/
├── clients/       Server and media-engine clients
├── components/    Reusable GTK components
├── controllers/   Application controllers
├── models/        Application data models
├── utils/         Utility classes
├── views/         GTK/libadwaita views
├── windows/       Application windows
├── application.vala
├── config.vala
└── main.vala

tests/
└── utils/         Unit tests

resources/
└── assets.xml     GResource definitions
```

The application follows a controller/view-oriented architecture. Server communication, media playback, application models, and GTK views are kept separate where practical.

## Running Tests

Build the test executable and run the Meson test suite:

```bash
meson test -C build
```

For more detailed output:

```bash
meson test -C build --verbose
```

## Music Server

PiPod communicates with Subsonic-compatible APIs. It is currently developed with [Navidrome](https://www.navidrome.org/) as the primary server target.

You will need:

- A running Subsonic-compatible server
- The server URL
- A username
- A password or other supported authentication credentials

PiPod does not provide a music server itself. Your music library remains on the configured server.

## License

PiPod is licensed under the **GNU General Public License v3.0 or later**. See the [LICENSE](LICENSE) file for details.

```text
Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://gnu.org>.
```
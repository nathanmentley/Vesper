# Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
#
# This file is part of your-app-name.
#
# your-app-name is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# your-app-name is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://gnu.org>.

project(
  'pipod',
  ['vala', 'c'],
  version: '0.1.0',
  license: 'GPL-3.0-or-later',
  meson_version: '>= 0.57.0',
  default_options: [
    'buildtype=debug',
    'warning_level=1'
  ]
)

gnome = import('gnome')

app_resources = gnome.compile_resources(
  'app-resources',
  'resources/assets.xml',
  source_dir: 'resources'
)

# Dependencies
gee_dep = dependency('gee-0.8')
glib_dep = dependency('glib-2.0')
gobject_dep = dependency('gobject-2.0')
gtk_dep = dependency('gtk4')
gst_dep = dependency('gstreamer-1.0')
libsoup_dep = dependency('libsoup-3.0')
gdkpixbuf_dep = dependency('gdk-pixbuf-2.0')
xml_dep = dependency('libxml-2.0')

dependencies = [
  gee_dep,
  glib_dep,
  gobject_dep,
  gtk_dep,
  gst_dep,
  libsoup_dep,
  gdkpixbuf_dep,
  xml_dep
]

# Application sources
app_sources = [
  'src/main.vala',
]

# Application/library sources
library_sources = [
  'src/clients/music_engine.vala',
  'src/clients/navidrome.vala',
  
  'src/components/album_row.vala',
  'src/components/artist_row.vala',
  'src/components/playlist_entry.vala',
  'src/components/song_row.vala',

  'src/controllers/base_controller.vala',
  'src/controllers/browser_controller.vala',
  'src/controllers/now_playing_controller.vala',
  'src/controllers/player_controller.vala',
  'src/controllers/playlist_controller.vala',
  'src/controllers/settings_controller.vala',

  'src/models/album.vala',
  'src/models/artist.vala',
  'src/models/playlist.vala',
  'src/models/song.vala',

  'src/utils/string_utils.vala',
  
  'src/views/base_view.vala',
  'src/views/browser_view.vala',
  'src/views/now_playing_view.vala',
  'src/views/player_view.vala',
  'src/views/playlist_view.vala',
  'src/views/settings_view.vala',

  'src/windows/main_window.vala',

  'src/application.vala',
  'src/config.vala',
]

# Main application
executable(
  'pipod',
  app_sources + library_sources,
  app_resources,
  dependencies: dependencies,
  install: true
)

# Unit tests
test_sources = [
  'tests/utils/string_utils_tests.vala',
  'tests/main.vala',
]

test_exe = executable(
  'pipod_tests',
  test_sources + library_sources,
  app_resources,
  dependencies: dependencies,
  install: false
)

test(
  'unit_tests',
  test_exe
)
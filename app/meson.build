# Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
#
# PiPod is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# PiPod is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with PiPod.  If not, see <https://gnu.org>.

app_resources = gnome.compile_resources(
  'app-resources',
  'resources/assets.xml',
  source_dir: 'resources'
)

app_sources = [
  # Components
  'src/components/album_row.vala',
  'src/components/artist_row.vala',
  'src/components/playlist_entry.vala',
  'src/components/song_row.vala',

  # Controllers
  'src/controllers/base_controller.vala',
  'src/controllers/browser_controller.vala',
  'src/controllers/now_playing_controller.vala',
  'src/controllers/player_controller.vala',
  'src/controllers/playlist_controller.vala',
  'src/controllers/settings_controller.vala',

  # Models
  'src/models/play_queue.vala',

  # Utils
  'src/utils/string_utils.vala',

  # Views
  'src/views/base_view.vala',
  'src/views/browser_view.vala',
  'src/views/now_playing_view.vala',
  'src/views/player_view.vala',
  'src/views/playlist_view.vala',
  'src/views/settings_view.vala',

  # Windows
  'src/windows/main_window.vala',

  # Application
  'src/application.vala',
]

pipod = executable(
  'pipod',
  ['src/main.vala'] + app_sources,
  app_resources,
  dependencies: [
    gee_dep,
    glib_dep,
    gobject_dep,
    libpeas_dep,
    gtk_dep,
    libadwaita_dep,
    gst_dep,
    libsoup_dep,
    gdkpixbuf_dep,
    xml_dep,
    pipod_service_dep,
    pipod_data_dep,
    pipod_plugin_dep,
  ],
  install: true,
)

test_sources = [
  'tests/utils/string_utils_tests.vala',
  'tests/main.vala',
]

pipod_tests = executable(
  'pipod_tests',
  test_sources + app_sources,
  app_resources,
  dependencies: [
    gee_dep,
    glib_dep,
    gobject_dep,
    libpeas_dep,
    gtk_dep,
    libadwaita_dep,
    gst_dep,
    libsoup_dep,
    gdkpixbuf_dep,
    xml_dep,
    pipod_service_dep,
    pipod_data_dep,
    pipod_plugin_dep,
  ],
  install: false,
)

test(
  'unit_tests',
  pipod_tests
)
# Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>
#
# Vesper is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Vesper is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Vesper.  If not, see <https://gnu.org>.

core_sources = [
  'src/models/genre.vala',
  'src/models/mix.vala',
  'src/models/play_history_entry.vala',
  'src/models/song_stats.vala',
  'src/models/album.vala',
  'src/models/artist.vala',
  'src/models/library.vala',
  'src/models/lyrics.vala',
  'src/models/playlist_item.vala',
  'src/models/playlist.vala',
  'src/models/search_result.vala',
  'src/models/song.vala',

  'src/plugins/configurable_plugin.vala',
  'src/plugins/lyrics_provider.vala',
  'src/plugins/music_engine.vala',
  'src/plugins/music_library.vala',
  'src/plugins/plugin_key.vala',
  'src/plugins/plugin.vala',
  'src/plugins/settings_provider.vala',

  'src/settings/setting_type.vala',
  'src/settings/settings_definition.vala',
  'src/settings/settings_engine.vala',
]

vesper_core = library(
  'vesper-core',
  core_sources,
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    libpeas_dep,
  ],
  vala_header: 'vesper-core.h',
  vala_vapi: 'vesper-core.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

vesper_core_dep = declare_dependency(
  link_with: vesper_core,
  include_directories: include_directories('.'),
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    libpeas_dep,
  ],
)
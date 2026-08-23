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

plugin_sources = [
  'src/models/album.vala',
  'src/models/artist.vala',
  'src/models/playlist.vala',
  'src/models/song.vala',

  'src/plugins/configurable_plugin.vala',
  'src/plugins/music_engine.vala',
  'src/plugins/music_library.vala',
  'src/plugins/playlist_provider.vala',
  'src/plugins/plugin.vala',
  'src/plugins/settings_provider.vala',

  'src/settings/setting_type.vala',
  'src/settings/settings_definition.vala',
  'src/settings/settings_engine.vala',
]

pipod_plugin = library(
  'pipod-plugin',
  plugin_sources,
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    libpeas_dep,
  ],
  vala_header: 'pipod-plugin.h',
  vala_vapi: 'pipod-plugin.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

pipod_plugin_dep = declare_dependency(
  link_with: pipod_plugin,
  include_directories: include_directories('.'),
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    libpeas_dep,
  ],
)
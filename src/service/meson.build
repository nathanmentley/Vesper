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

service_sources = [
  'src/libraries/library_service_impl.vala',
  'src/libraries/library_service.vala',
  'src/media/media_service_impl.vala',
  'src/media/media_service.vala',
  'src/playlists/playlist_service_impl.vala',
  'src/playlists/playlist_service.vala',
  'src/plugins/plugin_manager.vala',
  'src/settings/settings_engine_impl.vala',
  'src/settings/settings_service_impl.vala',
  'src/settings/settings_service.vala',
]

vesper_service = library(
  'vesper-service',
  service_sources,
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    vesper_core_dep,
    vesper_data_dep,
  ],
  vala_header: 'vesper-service.h',
  vala_vapi: 'vesper-service.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

vesper_service_dep = declare_dependency(
  link_with: vesper_service,
  include_directories: include_directories('.'),
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    vesper_core_dep,
    vesper_data_dep,
  ],
)

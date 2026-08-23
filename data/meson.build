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

data_sources = [
  'src/database.vala',
  'src/library_repository.vala',
  'src/migrations.vala',
]

pipod_data = library(
  'pipod-data',
  data_sources,
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    sqlite_dep,
    pipod_plugin_dep,
  ],
  vala_header: 'pipod-data.h',
  vala_vapi: 'pipod-data.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

pipod_data_dep = declare_dependency(
  link_with: pipod_data,
  include_directories: include_directories('.'),
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    sqlite_dep,
    pipod_plugin_dep,
  ],
)

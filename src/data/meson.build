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

data_sources = [
  'src/database_impl.vala',
  'src/database.vala',
  'src/library_repository_impl.vala',
  'src/library_repository.vala',
  'src/migrations.vala',
  'src/playlist_repository_impl.vala',
  'src/playlist_repository.vala',
]

vesper_data = library(
  'vesper-data',
  data_sources,
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    sqlite_dep,
    vesper_core_dep,
  ],
  vala_header: 'vesper-data.h',
  vala_vapi: 'vesper-data.vapi',
  install_vala_header: true,
  install_vala_vapi: true,
  install: true,
)

vesper_data_dep = declare_dependency(
  link_with: vesper_data,
  include_directories: include_directories('.'),
  dependencies: [
    glib_dep,
    gee_dep,
    gobject_dep,
    sqlite_dep,
    vesper_core_dep,
  ],
)

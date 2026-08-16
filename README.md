# PiPod

A simple music player written in vala that'll play from a subsonic api

## Building and Installing

This project uses the Meson build system. Ensure you have `meson`, `ninja`, and a Vala compiler installed.

```bash
# Configure the build directory
meson setup build

# Build the project
meson compile -C build

# execute the app
./build/pipod
```

## License

This project is licensed under the **GNU General Public License v3.0 or later** - see the [LICENSE](LICENSE) file for details.

```text
Copyright (C) 2026 Nathan Mentley <nathanmentley@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
```
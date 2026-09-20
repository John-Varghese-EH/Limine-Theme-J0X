# Limine Theme - J0X Edition

**An Interactive, Automated Theme Manager for the Limine Bootloader**

[![Validate Installer](https://github.com/John-Varghese-EH/Limine-Theme-J0X/actions/workflows/validate.yml/badge.svg)](https://github.com/John-Varghese-EH/Limine-Theme-J0X/actions/workflows/validate.yml)
[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

[**Install**](#installation) • [**Features**](#features) • [**Contribute**](CONTRIBUTING.md)

---

## The Vision

The Limine bootloader is incredibly powerful and fast, but customizing its appearance often requires manually editing configuration files that contain critical system boot entries. One wrong keystroke can render your system unbootable.

This repository provides a **robust interactive theme manager**. It safely applies custom aesthetics (like the Pitch Black or Kawaii palette) to your Limine boot menu while completely isolating and preserving your existing OS boot entries (like Windows and Linux).

## Features

| Feature | Description |
|---|---|
| **Interactive TUI** | Run the script without arguments to launch a beautiful Terminal User Interface to configure your bootloader visually. |
| **Zero-Touch Boot Entries** | The installer dynamically parses your existing `/boot/limine.conf`, separating UI settings from boot entries. Your kernels and OS paths are never touched. |
| **Robust Installer** | Built with strict bash error handling (`set -Euo pipefail`). If anything fails, it safely reports the error instead of destroying your bootloader configuration. |
| **Automatic Backups** | Before any change is made, your existing `limine.conf` is backed up with a timestamp. |
| **Live Config Previews** | View exactly how your config will be rewritten before writing it to the disk. |

## Installation

Execute the following commands to safely manage the theme in your active Limine configuration:

```bash
git clone https://github.com/John-Varghese-EH/Limine-Theme-J0X.git
cd Limine-Theme-J0X
chmod +x install.sh
sudo ./install.sh
```

Running `./install.sh` will launch the **Interactive Theme Manager** where you can:
1. Preview your bootloader tree layout.
2. Customize the Branding Text dynamically.
3. Switch between color palettes (Pitch Black vs Kawaii).
4. Restore previous configurations safely.

### Automation Flags

The manager also supports extensive parameterization for silent or scripted deployments:

```bash
# Preview what would happen without modifying any files on your system
./install.sh --dry-run

# Inject the theme using a completely different background image
sudo ./install.sh --bg /path/to/your/custom_image.jpg

# Change the greeting text at the top of the bootloader silently
sudo ./install.sh --branding "Custom System Name"

# Safely revert to the configuration you had before running the installer
sudo ./install.sh --uninstall
```

## How It Works

1. The installer reads your active `/boot/limine.conf`.
2. It extracts essential global settings (like `timeout` and `default_entry`).
3. It extracts every boot entry (identifying them by the `/` prefix).
4. It compiles a new configuration file combining your global settings, the new `theme.conf` UI definitions, and your pristine boot entries.
5. It safely overwrites `/boot/limine.conf`.

## CI/CD Validation

To guarantee absolute reliability, the `install.sh` script is continuously validated using GitHub Actions. Every commit is analyzed by `shellcheck` to ensure strict compliance with shell scripting best practices and POSIX standards.

## License

This project is licensed under the **GPL-3.0 License**. See the [LICENSE](LICENSE) file for complete details.

---

## About the Author

**John Varghese (J0X)**
* **LinkedIn**: [/in/John--Varghese/](https://linkedin.com/in/John--Varghese/)
* **GitHub**: [John-Varghese-EH](https://github.com/John-Varghese-EH)

_If this theme improved your dual-boot experience, consider starring the repository on GitHub._

# Changelog

## 1.0.1

Fixes for Debian when a root password is set during installation, which leaves out sudo and curl.

- The installer and the `kiosk` command add `/usr/sbin` and `/sbin` to the PATH, so they work after a plain `su`
  (without `-`). Before, the install stopped with *useradd: command not found*.
- Without sudo, the installer and the `kiosk` command say to become root with `su -`, and their hints and
  `kiosk help` show `kiosk …` instead of `sudo kiosk …`.
- README and TESTING (step 1.6) cover it.
- The resolution and rotation wait up to 10 seconds for the screens to be listed, and Kiosk checks the resolution
  took effect (trying up to 5 times). The log now says what was set, or that it couldn't be set; before, a failure
  was silent. On a virtual machine the message suggests giving its display more memory: Proxmox's default display
  memory is too small for 1920×1080.
- The repository no longer includes internal notes.

## 1.0.0

The first release: one command turns a Linux computer into a full-screen player for one web address, with screen
off and on times, rotation, resolution, a nightly restart, automatic updates, and optional management from Rock
with the Kiosk Manager plugin.

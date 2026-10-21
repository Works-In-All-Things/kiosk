# Changelog

## 1.0.1

Fixes for Debian when a root password is set during installation, which leaves out sudo and curl.

- The installer and the `kiosk` command add `/usr/sbin` and `/sbin` to the PATH, so they work after a plain `su`
  (without `-`). Before, the install stopped with *useradd: command not found*.
- Without sudo, the installer and the `kiosk` command say to become root with `su -`, and their hints and
  `kiosk help` show `kiosk …` instead of `sudo kiosk …`.
- README and TESTING (step 1.6) cover it.
- The repository no longer includes internal notes.

## 1.0.0

The first release: one command turns a Linux computer into a full-screen player for one web address, with screen
off and on times, rotation, resolution, a nightly restart, automatic updates, and optional management from Rock
with the Kiosk Manager plugin.

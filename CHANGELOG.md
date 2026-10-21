# Changelog

## 1.1.0

- **A start-up logo.** While the computer starts, the screen shows the Works In All Things logo on black, and it
  stays up until the page appears (the browser opens a small start page with the logo, then the address). Set your
  own with `kiosk boot logo <file.png or https address>`; `kiosk boot logo default` puts ours back.
- **A quiet start-up, on by default.** No boot menu, no scrolling text and no blinking cursor. The installer asks (yes unless you say
  no; `--quiet-boot yes|no` without questions), and a managed install is quiet. `kiosk boot normal` shows the text
  again, and `kiosk uninstall` puts the start-up back as it was. Works on Debian, Ubuntu and Mint (GRUB), Fedora
  (grubby) and Raspberry Pi OS; `kiosk status` shows it. Kiosks updated from 1.0 keep their start-up text until you
  run `kiosk boot quiet`, and show the logo while the browser starts.
- The wait for the address (up to 90 seconds) now happens before the display starts, with the logo on the screen.

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

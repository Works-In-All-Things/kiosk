# Kiosk: Plan for Version 1.0

**Status:** the release test passed on Ubuntu 26.04; the other distributions are still to test. See [README.md](README.md) for how it works
and [TESTING.md](TESTING.md) for the release test.

**What it is:** Works In All Things Kiosk. One command turns a Linux computer into a TV player that opens one web
address full screen, starts on power-up, and recovers on its own. It's made for the Signage Player URL and works
just as well for the Parent Page number board, or any page that should fill a screen.

## Decisions

| Question | Decision |
|---|---|
| Free or paid? | **Free and public**, MIT license. |
| Which distributions? | **Any** with systemd and apt, dnf, pacman or zypper. Tested first: Debian 12/13, Raspberry Pi OS Lite (64-bit), Ubuntu 24.04, Fedora. |
| Raspberry Pi | **Raspberry Pi OS Lite (64-bit)** on the Pi 5 (and Pi 4). |
| Hardware | **Not tied to any.** 64-bit Intel/AMD or ARM, 4 GB memory; the distribution's own drivers. |
| Browser | The distribution's Chromium where it's a real package with full video support (Debian, Raspberry Pi OS, Mint, Arch). Otherwise Chromium from **Flathub** (Ubuntu's is a snap; Fedora's and openSUSE's can't play H.264 MP4s). |
| Display | **cage**, packaged by every supported distribution. |
| In 1.0 | Screen off/on times, rotation, resolution, nightly restart, automatic updates, and optional management from Rock: an agent for the **Kiosk Manager** plugin (`kiosk manage`, planned in `Works-In-All-Things/kiosk-manager`, §7 of its PLAN.md). Network settings are left alone (the computer is already online to download the installer). Kiosk never runs Rock check-in. |
| Later | SSH set-up during install, HDMI-CEC (turning the TV itself off), showing the IP address on screen. |

## How it fits together

| File | Installed to | What it does |
|---|---|---|
| `install.sh` | (run once, from the website) | Downloads the latest release and runs `kiosk install`. |
| `kiosk` | `/usr/local/lib/kiosk/kiosk`, linked from `/usr/local/bin/kiosk` | The installer and every command. |
| `lib/distro.sh` | `/usr/local/lib/kiosk/lib/` | Finds the package manager and the package names for each distribution family. |
| `lib/start` | `/usr/local/lib/kiosk/lib/` | Starts cage (with `-r` rotation on cage before 0.1.5). |
| `lib/session` | `/usr/local/lib/kiosk/lib/` | Runs inside cage: resolution and rotation with wlr-randr, waits for the network, clears the crash flag, starts Chromium. |
| `lib/pam-kiosk` | `/etc/pam.d/kiosk` | The login session, so the kiosk user gets the screen, sound and a session bus. |
| `systemd/*` | `/etc/systemd/system/` | The kiosk service, the screen, restart and browser-update jobs. The daily timers are written from the settings. |
| (written) | `/etc/kiosk/kiosk.conf` | The settings. |
| (written) | `/etc/kiosk/install-state` | What was on before (desktop login, console login), so uninstall can put it back. |

## Checked so far

- `shellcheck` is clean.
- A full install on Ubuntu 24.04 in a container with systemd: packages, the `kiosk` user, the login session on
  tty1 (seat0), the timers in the right time zone, settings with unusual characters, and the commands.
- The questions on Ubuntu 26.04, typed into a real interactive shell, with both `… | bash` and `… | sudo bash`.
  Its sudo-rs freezes any program that reads the keyboard unless it's the one sudo started, so `install.sh` hands
  over to the installer with `exec` (or runs sudo itself with the keyboard as input), and the installer never
  reads answers inside `$(...)` or changes terminal settings.
- **Randy ran the whole release test (TESTING.md) on Ubuntu 26.04 (reported 2026-10-19): every step passed.**
- Not checked yet: Debian, Raspberry Pi OS, Fedora, Arch or openSUSE (their package
  mirrors and Flathub can't be reached from where it was written). That's what TESTING.md is for.

## Next

1. Add the Kiosk Manager agent (Kiosk Manager's Milestone A). The version stays **1.0.0**.
2. Randy tests the other distributions along the way: the Intel mini PCs and the Raspberry Pi 5 (TESTING.md).
   Ubuntu 26.04 is done.
3. Once the agent's heartbeat format is settled, tag `v1.0.0` (a GitHub release), which `install.sh` and
   `kiosk update` download.
4. Add a `/kiosk/` page to the website with the install command and a copy of `install.sh` at
   `/kiosk/install.sh`, and link it from the Signage and Parent Page pages.

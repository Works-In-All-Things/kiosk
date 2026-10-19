# Kiosk: Plan for Version 1.0

**Status:** version 1.0.0 is released, with the Kiosk Manager agent. The release test passed on Ubuntu 26.04; the other distributions are still to test. See [README.md](README.md) for how it works
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
| `lib/manage.sh` | `/usr/local/lib/kiosk/lib/` | Management from Rock (Kiosk Manager): `kiosk manage`, `unmanage` and `heartbeat`, and the kiosk lock. |
| `lib/start` | `/usr/local/lib/kiosk/lib/` | Starts cage (with `-r` rotation on cage before 0.1.5). |
| `lib/session` | `/usr/local/lib/kiosk/lib/` | Runs inside cage: resolution and rotation with wlr-randr, waits for the network, clears the crash flag, starts Chromium. |
| `lib/pam-kiosk` | `/etc/pam.d/kiosk` | The login session, so the kiosk user gets the screen, sound and a session bus. |
| `systemd/*` | `/etc/systemd/system/` | The kiosk service, the screen, restart and browser-update jobs. The daily timers are written from the settings. |
| (written) | `/etc/kiosk/kiosk.conf` | The settings. |
| (written) | `/etc/kiosk/installed-from` | The release tag or branch and the commit the files came from, so `kiosk update` knows when it's up to date. |
| (written) | `/etc/kiosk/install-state` | What was on before (desktop login, console login), so uninstall can put it back. |
| (written) | `/etc/kiosk/manager.conf`, `/etc/kiosk/manager-state/` | Only when managed by Rock: the Rock address and token (root only), and the applied settings version, action results and last heartbeat. |

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

1. ~~Add the Kiosk Manager agent.~~ Done: `lib/manage.sh`, `kiosk-heartbeat.service` and `.timer`,
   `kiosk install --manage`, the kiosk lock and `jq`, and `kiosk update` that says *up to date* and follows a test
   branch until the first release. Randy linked the Ubuntu 26.04 kiosk to Kiosk Manager on Rock 19.4 and ran
   Kiosk Manager's test (its Milestone A); the update fix is confirmed.
2. Randy tests the other distributions along the way: the Intel mini PCs and the Raspberry Pi 5 (TESTING.md,
   including section 7). Ubuntu 26.04 is done.
3. **Release v1.0.0** (Kiosk Manager's Milestone C needs it first). Randy chose to release on 2026-10-19. In this
   order:
   1. ~~The heartbeat format is settled.~~ From here on the JSON names in `lib/manage.sh` never change; Kiosk
      Manager's remaining tests run against the release.
   2. ~~Set `VERSION` to `1.0.0`.~~
   3. Merge the branch into `main` (a pull request), then tag `v1.0.0` on `main` and publish a GitHub release
      from the tag. `install.sh` and `kiosk update` download the latest *published release*
      (`releases/latest`), so a tag on its own isn't enough.
   4. On a test kiosk, `sudo kiosk update` (it moves from the branch to the release), then
      `sudo kiosk update` again: *up to date*.
4. ~~Add a `/kiosk/` page to the website.~~ Written on the website's branch: `/kiosk/` (install command,
   requirements, commands, troubleshooting) and a copy of `install.sh` at `/kiosk/install.sh` (the command Kiosk
   Manager shows downloads it from there), linked from every page's footer, the plugins page and the Signage pages.
   **Deploy it only after step 3**: before the release, the installer falls back to `main`, whose `kiosk` doesn't
   take the `--source` and `--commit` options it passes. Whenever `install.sh` changes, copy it to the website too.
   Link the Kiosk Manager page once it's on the Rock Shop.

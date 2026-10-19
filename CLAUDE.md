# Kiosk: notes for Claude Code

**Works In All Things Kiosk** turns a Linux computer (any distribution with systemd and apt, dnf, pacman or zypper)
into a full-screen web player for one address, such as a Signage Player URL. It's free and open source (MIT).
Status: the release test passed on Ubuntu 26.04; other distributions are still to test. Version 1.0.0 is released and
includes the optional agent for the Kiosk Manager plugin (`Works-In-All-Things/kiosk-manager`). Kiosk never runs Rock
check-in. See [PLAN.md](PLAN.md), [README.md](README.md) and
[TESTING.md](TESTING.md).

## Working rules

- Work on branch `claude/kind-knuth-jopajs`. Never push to `main`. Don't open pull requests unless asked.
- Commit as **Randy Reed <randy.reed23@gmail.com>** (`git -c user.name="Randy Reed" -c user.email="randy.reed23@gmail.com" commit …`).
- Never write "tested on X" in any doc until Randy confirms the test passed.
- No AI model names or identifiers in commits, code or docs.
- Related repos: the Signage plugin is `Works-In-All-Things/rocksign`; the website (`/kiosk/` page and the hosted
  `install.sh`) is `Works-In-All-Things/worksinallthings-site`.

## Code rules

- Bash, `set -euo pipefail`, `shellcheck -x kiosk install.sh lib/session lib/start lib/distro.sh lib/manage.sh` clean, with no
  disabled checks unless a comment says why. A comment above every function.
- Distribution differences go in `lib/distro.sh`. Nothing may depend on particular hardware.
- Test installs in a container with systemd (see PLAN.md, *Checked so far*); the screen itself needs real hardware.
- When behavior changes, update README, TESTING.md and PLAN.md in the same change.
- Safe to run twice. Never overwrite a setting without asking.
- Everything the installer adds, `kiosk uninstall` removes.

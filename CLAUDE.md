# Kiosk: notes for Claude Code

**Works In All Things Kiosk** turns a fresh Debian 12/13 computer (or a Raspberry Pi 5 with Raspberry Pi OS Lite)
into a full-screen web player for one address, such as a Signage Player URL. Status: planning; see
[PLAN.md](PLAN.md).

## Working rules

- Work on branch `claude/kind-knuth-jopajs`. Never push to `main`. Don't open pull requests unless asked.
- Commit as **Randy Reed <rreed@hf.church>** (`git -c user.name="Randy Reed" -c user.email="rreed@hf.church" commit …`).
- Never write "tested on X" in any doc until Randy confirms the test passed.
- No AI model names or identifiers in commits, code or docs.
- Related repos: the Signage plugin is `randyjreed/rocksign`; the website (`/kiosk/` page and the hosted
  `install.sh`) is `randyjreed/worksinallthings-site`.

## Code rules

- Bash, `set -euo pipefail`, `shellcheck` clean with no disabled checks unless a comment says why.
- Safe to run twice. Never overwrite a setting without asking.
- Everything the installer adds, `kiosk uninstall` removes.

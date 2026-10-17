# Kiosk: Plan for Version 1.0

**Status:** draft for Randy's review. No code has been written yet.

**What it is:** Works In All Things Kiosk. One command turns a fresh Debian computer into a TV player that opens
one web address full screen, starts on power-up, and recovers on its own. It's made for the Signage Player URL and
works just as well for the Parent Page number board, or any page that should fill a screen.

---

## 1. What the church does

1. Install **Debian 12 or 13** (no desktop) on a mini PC, or **Raspberry Pi OS Lite (64-bit)** on a Raspberry Pi 5.
2. Log in and run:

   ```bash
   curl -fsSL https://worksinallthings.com/kiosk/install.sh | sudo bash
   ```

3. Paste the **Player URL** when asked (and pick Wi-Fi, screen rotation and the screen's time zone if needed).
4. The computer restarts and plays the page. From then on it starts by itself every time it's powered on.

Changing it later: `sudo kiosk url <new address>`, `sudo kiosk status`, `sudo kiosk restart`, `sudo kiosk update`,
`sudo kiosk uninstall`.

## 2. What gets installed

| Part | Choice | Why |
|---|---|---|
| Display | **cage**, a Wayland compositor that runs exactly one app full screen | No desktop, no window manager, nothing to click away. In Debian 12, 13 and Raspberry Pi OS. |
| Browser | **Chromium** from the distribution | Signage is tested on Chromium; updates come with normal security updates. On the Pi, Raspberry Pi OS's own Chromium build has hardware video decoding. |
| Start-up | A **systemd service** (`kiosk.service`) on tty1, running as a locked-down `kiosk` user | Starts at boot, restarts within seconds if the browser crashes. No auto-login shell. |
| Browser data | A **persistent profile** in `/var/lib/kiosk` | Signage's offline storage survives restarts, so a kiosk that boots with no network still plays (better than Porteus, which forgets everything). |
| Network | **NetworkManager**, Wi-Fi set up during install | `sudo nmtui` changes it later. |
| Video | Intel: `intel-media-va-driver` (VA-API). Pi 5: Raspberry Pi OS's driver | Smooth 1080p video without maxing the CPU. Checked on real hardware (section 5). |
| Audio | PipeWire, with HDMI as the output | For video sound. Chromium is started with `--autoplay-policy=no-user-gesture-required`. |
| Updates | **unattended-upgrades** for security updates, and an optional nightly restart (default 3:30 am) | A TV nobody touches for a year stays patched and fresh. |
| Settings | `/etc/kiosk/kiosk.conf` (plain text: URL, rotation, restart time, screen on/off times) | Easy to read and copy between kiosks. |

Chromium starts with `--kiosk`, no first-run screens, no "restore pages?" bubble, no translate bar, no update nags,
and no pop-ups. No mouse pointer shows unless a mouse is plugged in.

## 3. Nice extras (each one optional, decided in section 6)

- **Screen off at night:** turn the HDMI output off and on at set times (`wlopm`), or the TV itself via HDMI-CEC
  where the TV supports it.
- **Rotation** for portrait TVs: 0, 90, 180 or 270.
- **Remote help:** SSH on, with a key or password you choose during install. Off by default.
- **Show the address on screen at boot** for 10 seconds (IP address and host name), so you can find it to SSH in.

**One thing to check first:** rotation and screen off/on need cage 0.2 (in Debian 13). Debian 12 has cage 0.1.4,
which may not support them. If it doesn't, Debian 12 uses a small X11 set-up instead (Xorg running only Chromium),
with the same `kiosk` command and settings. I'll confirm this before writing the rest.

## 4. How it's built

- One Bash installer, `install.sh`, plus the `kiosk` command and the service files it installs. It checks it's on
  Debian 12/13 or Raspberry Pi OS (64-bit), and stops with a clear message otherwise.
- Safe to run again: running it twice gives the same result, and it never overwrites settings without asking.
- `kiosk uninstall` removes everything it added and puts the computer back to a normal console login.
- Checks: `shellcheck` clean; an automated install test in Debian 12 and 13 containers (everything except the
  screen); then the hardware tests below.
- Releases are tagged. The website serves the current `install.sh`, which downloads that tagged release, so the
  one-line command never changes.

## 5. Testing on your hardware (about a week)

| Test | Intel mini PC (Debian 12) | Intel mini PC (Debian 13) | Raspberry Pi 5 |
|---|---|---|---|
| Install from the one-line command, wired and Wi-Fi | | | |
| Boots straight into the Player URL; no pop-ups or bars | | | |
| 1080p video plays smoothly (and 4K if the TV does) | | | |
| HDMI audio | | | |
| Signage offline tests O1–O11, including O5 (restart while offline) | | | |
| Pull the power, plug it back in: plays again | | | |
| Browser killed (`sudo pkill chromium`): back within 10 seconds | | | |
| Rotation, screen off/on times, nightly restart | | | |
| `kiosk url`, `kiosk update`, `kiosk uninstall` | | | |
| A week of running without being touched | | | |

## 6. Questions for you

1. **Free or paid?** A free download (MIT license, the repo public) helps sell Signage and Parent Page. Paid would
   need a license check, which is a lot more work for a script.
2. **Which Pi OS?** Plain Debian on the Pi 5 still lacks good video drivers, so I'd support **Raspberry Pi OS Lite
   (64-bit)** there. Is that OK?
3. **Extras for 1.0:** which of section 3 do you want in 1.0? I'd suggest screen off at night (`wlopm` only),
   rotation and the nightly restart, with SSH and HDMI-CEC later.
4. **Install questions:** URL, Wi-Fi, rotation and time zone are asked during install. Anything else?
5. **Hardware:** which mini PC models do you have to test on?

## 7. Time

About 2–4 days to write it, then about a week of testing on real hardware.

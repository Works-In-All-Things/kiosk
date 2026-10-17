# Kiosk: Release Test

Do this on real hardware before a release. Use a Signage Player URL from the Rock dev site, with a playlist that
has pictures, an MP4 video with sound, and a Lava slide.

Write each result in the tables at the end: ✓, ✗ (with a note), or – for not tried.

## 1. Install

| # | Do this | You should see |
|---|---|---|
| 1.1 | On a fresh install of the distribution, run `curl -fsSL https://worksinallthings.com/kiosk/install.sh \| sudo KIOSK_REF=<branch> bash` (leave out `KIOSK_REF` once there's a release). | It asks for the address, time zone, rotation, screen times and restart time, installs, and offers to restart. |
| 1.2 | On a computer with Wi-Fi, answer **y** to *Set up Wi-Fi now?* and join a network. | The Wi-Fi screen opens; the network works after the restart. |
| 1.3 | Restart. | The address fills the screen within a minute of power-on: no login, desktop, bars, bubbles or pop-ups. No mouse pointer (unless a mouse is plugged in). |
| 1.4 | On a computer with a desktop installed, run the installer. | It asks to turn the desktop off. After the restart the kiosk shows instead of the login screen. |
| 1.5 | Run the installer again and press Enter at every question. | Nothing changes; the kiosk still works. |

## 2. Playing

| # | Do this | You should see |
|---|---|---|
| 2.1 | Watch a full playlist. | Pictures, Lava and transitions look right. |
| 2.2 | Watch the video slide. | Smooth, with sound from the TV. Check CPU with `top` over SSH or on Ctrl+Alt+F2: under about 50% for 1080p. |
| 2.3 | Signage offline tests O1–O11 (rocksign TESTING.md section 10). | As described there. O5 (restart while offline) should play. |

## 3. Recovery

| # | Do this | You should see |
|---|---|---|
| 3.1 | Pull the power while it plays; plug it back in. | It plays again with no "Restore pages?" bubble. |
| 3.2 | On Ctrl+Alt+F2, log in and run `sudo pkill chromium` (Flathub browser: `sudo pkill -f org.chromium`). | Back within about 10 seconds. |
| 3.3 | Turn on with the network unplugged (before Signage ever stored anything, use a fresh install). | It waits about 90 seconds, then shows the browser's offline page. Plug in the network: it loads within a minute or two (or after `sudo kiosk restart`). |

## 4. Settings

| # | Do this | You should see |
|---|---|---|
| 4.1 | `sudo kiosk url <another address>` | It switches within a few seconds. `kiosk url` shows the new address. |
| 4.2 | `sudo kiosk rotate 90`, then `sudo kiosk rotate 0` | The picture turns for a portrait screen, then back. Note the cage version (`cage -v`) if it doesn't. |
| 4.3 | `sudo kiosk screen schedule <in 2 minutes> <in 4 minutes>` | The screen goes off (the TV says *no signal* or sleeps) and comes back on at the times. |
| 4.4 | `sudo kiosk screen off`, then `sudo kiosk screen on` | Off, then on. |
| 4.5 | Set the screen to be off now, then `sudo reboot`. | It stays off after the restart, and comes on at the on time. |
| 4.6 | `sudo kiosk restart-time <in 2 minutes>` | The computer restarts and plays again. |
| 4.7 | `kiosk status` and `sudo kiosk logs` | The settings, IP address and recent messages. |
| 4.8 | `sudo kiosk update <branch>` | It updates and restarts the browser; settings are kept. |

## 5. Uninstall

| # | Do this | You should see |
|---|---|---|
| 5.1 | `sudo kiosk uninstall`, then restart. | The normal console login (or the desktop's login screen) comes back. `/etc/kiosk`, `/var/lib/kiosk`, `/usr/local/lib/kiosk` and the `kiosk` user are gone. |
| 5.2 | Install again. | It works as in section 1. |

## 6. A week untouched

| # | Do this | You should see |
|---|---|---|
| 6.1 | Leave it playing for a week with the nightly restart on. | Still playing, still on time, with no messages on screen. |

## Results

Fill in one column per computer and distribution (for example *N100 mini PC, Debian 13*).

| Test | | | | |
|---|---|---|---|---|
| Hardware | | | | |
| Distribution and version | | | | |
| Browser (`kiosk status`) | | | | |
| 1.1–1.5 Install | | | | |
| 2.1–2.2 Playing (note CPU for 2.2) | | | | |
| 2.3 Signage offline | | | | |
| 3.1–3.3 Recovery | | | | |
| 4.1–4.8 Settings | | | | |
| 5.1–5.2 Uninstall | | | | |
| 6.1 A week untouched | | | | |

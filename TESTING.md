# Kiosk: Release Test

Do this on real hardware before a release. Use a Signage Player URL from the Rock dev site, with a playlist that
has pictures, an MP4 video with sound, and a Lava slide.

Write each result in the tables at the end: ✓, ✗ (with a note), or – for not tried.

## 1. Install

| # | Do this | You should see |
|---|---|---|
| 1.1 | On a fresh install of the distribution, connected to the network, run `curl -fsSL https://worksinallthings.com/kiosk/install.sh \| KIOSK_REF=<branch> bash` (leave out `KIOSK_REF` once there's a release). | It asks for the address, time zone (from a numbered list), rotation, screen times and restart time, then shows one line per step (the details go to `/var/log/kiosk-install.log`) and offers to restart. A mistyped answer is asked again. |
| 1.2 | On a computer connected by Wi-Fi, install and restart. | It's still on the same Wi-Fi after the restart (Kiosk doesn't change network settings). |
| 1.3 | Restart. | The address fills the screen within a minute of power-on: no login, desktop, bars, bubbles or pop-ups. No mouse pointer (unless a mouse is plugged in). |
| 1.4 | On a computer with a desktop installed, run the installer. | It asks to turn the desktop off. After the restart the kiosk shows instead of the login screen. |
| 1.5 | Run the installer again and press Enter at every question. | Nothing changes; the kiosk still works. |
| 1.6 | **Debian with a root password set** (no sudo or curl): run `wget -qO- https://worksinallthings.com/kiosk/install.sh \| bash` as your user. Then `su -` and run it again. Afterwards, as your user, `kiosk url https://example.org`. | As your user: *sudo isn't installed … Become root with: su -*. As root it installs as in 1.1. The `kiosk` command says *Run this as root: su -*. |

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
| 4.2a | `sudo kiosk resolution 1920x1080`, then `sudo kiosk resolution auto` | The picture changes to 1920×1080 (no black bars on a 16:9 slide), then back. On a virtual machine, note the display type (for example Proxmox *Default* or *VirtIO-GPU*). |
| 4.3 | `sudo kiosk screen schedule <in 2 minutes> <in 4 minutes>` | The screen goes off (the TV says *no signal* or sleeps) and comes back on at the times. |
| 4.4 | `sudo kiosk screen off`, then `sudo kiosk screen on` | Off, then on. |
| 4.5 | Set the screen to be off now, then `sudo reboot`. | It stays off after the restart, and comes on at the on time. |
| 4.6 | `sudo kiosk restart-time <in 2 minutes>` | The computer restarts and plays again. |
| 4.7 | `kiosk status` and `sudo kiosk logs` | The settings, IP address and recent messages. |
| 4.8 | `sudo kiosk update <branch>` | It updates and restarts the browser; settings are kept. |
| 4.9 | `sudo kiosk update` straight afterwards. | *Kiosk is up to date*, with nothing downloaded. (Before the first release it follows the branch from 4.8.) |

## 5. Uninstall

| # | Do this | You should see |
|---|---|---|
| 5.1 | `sudo kiosk uninstall`, then restart. | The normal console login (or the desktop's login screen) comes back. `/etc/kiosk`, `/var/lib/kiosk`, `/usr/local/lib/kiosk` and the `kiosk` user are gone. |
| 5.2 | Install again. | It works as in section 1. |

## 6. A week untouched

| # | Do this | You should see |
|---|---|---|
| 6.1 | Leave it playing for a week with the nightly restart on. | Still playing, still on time, with no messages on screen. |

## 7. Managed by Rock

Needs the Kiosk Manager plugin on the Rock dev site (its TESTING.md has the Rock side).

| # | Do this | You should see |
|---|---|---|
| 7.1 | In Rock, add a kiosk with a Player URL, rotation 0 and screen times. On a fresh install of the distribution, paste the install command Rock shows (add `KIOSK_REF=<branch>` before `bash`). | No questions except turning off a desktop. It says *Linked to the kiosk "…" in Rock* and *Applied Rock's settings*, and after the restart it shows the Player URL. In Rock the kiosk is Online within a minute, with its health filled in. |
| 7.2 | On a computer that already runs Kiosk, make a kiosk in Rock and run `sudo kiosk manage <rock address> <code>`. | Linked, and its settings change to Rock's within a few seconds. |
| 7.3 | Run the same command again with the used code. | *Rock didn't accept the code*; nothing changes. |
| 7.4 | In Rock, change the address, rotation, resolution, screen times and nightly restart. | Within about a minute the kiosk shows the new address and turns the picture. `kiosk status` shows the new times. |
| 7.5 | On the kiosk, `sudo kiosk url https://example.org`. | It refuses: the kiosk is managed by Rock. |
| 7.6 | In Rock, press Restart Browser, Screen Off, Screen On, Reboot and Update Kiosk, one at a time. | Each happens within about a minute, and Rock's Recent Actions shows *Done* for each (Reboot after the computer is back). |
| 7.7 | In Rock, set the time zone to `Mars/Base`. | The kiosk keeps its old time zone, and Rock shows *couldn't apply all its settings: … doesn't know the time zone*. Put it back. |
| 7.8 | Unplug the network for 5 minutes, then plug it back in. | It keeps playing. Rock shows it Offline, then Online again within a minute of the network coming back. |
| 7.9 | In Rock, press Make New Code. | Within a minute the kiosk stops sending heartbeats and `kiosk status` says *Managed by Rock: no longer*. It keeps showing the same address. Link it again with the new code (7.2). |
| 7.10 | `sudo kiosk unmanage`, then `sudo kiosk url https://example.org`. | The settings stay; the address change now works. |
| 7.11 | Link it again, then `sudo kiosk uninstall`. | `/etc/kiosk` is gone, including the token, and `kiosk-heartbeat.timer` no longer exists. |

## Results

Fill in one column per computer and distribution (for example *N100 mini PC, Debian 13*).

| Test | | | | |
|---|---|---|---|---|
| Hardware | | | | |
| Distribution and version | | | | |
| Browser (`kiosk status`) | | | | |
| 1.1–1.6 Install | | | | |
| 2.1–2.2 Playing (note CPU for 2.2) | | | | |
| 2.3 Signage offline | | | | |
| 3.1–3.3 Recovery | | | | |
| 4.1–4.8 Settings | | | | |
| 5.1–5.2 Uninstall | | | | |
| 6.1 A week untouched | | | | |
| 7.1–7.11 Managed by Rock | | | | |

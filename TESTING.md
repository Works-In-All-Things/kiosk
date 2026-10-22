# Kiosk: Release Test

Do this on real hardware before a release. Use a Signage Player URL from the Rock dev site, with a playlist that
has pictures, an MP4 video with sound, and a Lava slide.

Write each result in the tables at the end: ✓, ✗ (with a note), or – for not tried.

## 1. Install

| # | Do this | You should see |
|---|---|---|
| 1.1 | On a fresh install of the distribution, connected to the network, run `curl -fsSL https://worksinallthings.com/kiosk/install.sh \| KIOSK_REF=<branch> bash` (leave out `KIOSK_REF` once there's a release). | It asks for the address, time zone (from a numbered list), rotation, screen times and restart time, and whether to hide the start-up text (yes), then shows one line per step (the details go to `/var/log/kiosk-install.log`) and offers to restart. A mistyped answer is asked again. |
| 1.2 | On a computer connected by Wi-Fi, install and restart. | It's still on the same Wi-Fi after the restart (Kiosk doesn't change network settings). |
| 1.3 | Restart. | The address fills the screen within a minute of power-on: no login, desktop, bars, bubbles or pop-ups. No mouse pointer (unless a mouse is plugged in). |
| 1.4 | On a computer with a desktop installed, run the installer. | It asks to turn the desktop off. After the restart the kiosk shows instead of the login screen. |
| 1.5 | Run the installer again and press Enter at every question. | Nothing changes; the kiosk still works. |
| 1.6 | **Debian with a root password set** (no sudo or curl): run `wget -qO- https://worksinallthings.com/kiosk/install.sh \| bash` as your user. Then `su` (plain, without `-`) and run it again. Afterwards, as your user, `kiosk url https://example.org`. | As your user: *sudo isn't installed … Become root with: su -*. As root it installs as in 1.1, with no *command not found* errors (plain `su` leaves `/usr/sbin` off the PATH; Kiosk adds it). The `kiosk` command says *Run this as root: su -*. The installer's last lines, `kiosk help` and the other hints show `kiosk …` without `sudo`, and `kiosk help` says the computer has no sudo. |

## 2. Playing

| # | Do this | You should see |
|---|---|---|
| 2.1 | Watch a full playlist. | Pictures, Lava and transitions look right. |
| 2.2 | Watch the video slide. | Smooth, with sound from the TV. Check CPU with `top` over SSH or on Ctrl+Alt+F2: under about 50% for 1080p. |
| 2.3 | Signage offline tests O1–O11 (rocksign TESTING.md section 10). | As described there. O5 (restart while offline) should play. |
| 2.4 | Show an address on the public internet whose page loads something from a `192.168.x.x` or `10.x` address (for example a Signage Web Page slide pointing at a device on your network). Then `sudo cat /var/lib/flatpak/extension/org.chromium.Chromium.Extension.kiosk/*/1/policies/managed/kiosk.json` (distribution's Chromium: `/etc/chromium/policies/managed/works-in-all-things-kiosk.json`). | No *wants to access other devices on your local network* box on the screen. The file lists the address's `https://host`. After `sudo kiosk url <another address>` it lists the new one. |

## 3. Recovery

| # | Do this | You should see |
|---|---|---|
| 3.1 | Pull the power while it plays; plug it back in. | It plays again with no "Restore pages?" bubble. |
| 3.2 | On Ctrl+Alt+F2, log in and run `sudo pkill chromium` (Flathub browser: `sudo pkill -f org.chromium`). | Back within about 10 seconds. |
| 3.3 | Turn on with the network unplugged (before Signage ever stored anything, use a fresh install). | It waits about 90 seconds with the logo on the screen, then shows the browser's offline page. Plug in the network: it loads within a minute or two (or after `sudo kiosk restart`). |

## 4. Settings

| # | Do this | You should see |
|---|---|---|
| 4.1 | `sudo kiosk url <another address>` | It switches within a few seconds. `kiosk url` shows the new address. |
| 4.2 | `sudo kiosk rotate 90`, then `sudo kiosk rotate 0` | The picture turns for a portrait screen, then back. Note the cage version (`cage -v`) if it doesn't. |
| 4.2a | `sudo kiosk resolution 1920x1080`, then `sudo kiosk resolution auto` | The picture changes to 1920×1080 (no black bars on a 16:9 slide), then back. Set 1920×1080 again and restart the computer: it starts at 1920×1080. On a virtual machine, note the display type and memory (for example Proxmox *Default* or *VirtIO-GPU*, 64 MiB); with too little memory the log says *Cannot allocate memory*. |
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
| 5.1 | `sudo kiosk uninstall`, then restart. | The normal console login (or the desktop's login screen) comes back. `/etc/kiosk`, `/var/lib/kiosk`, `/usr/local/lib/kiosk`, the browser policy from 2.4 and the `kiosk` user are gone. |
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

## 8. Start-up screen

On a virtual machine, watch the start-up in its console. Check each after a restart.

| # | Do this | You should see |
|---|---|---|
| 8.1 | A fresh install, pressing Enter at *Hide the start-up text?* Restart. | No boot menu and no scrolling text. After the computer maker's logo, the Works In All Things logo on black, staying up until the page appears (at most a moment of black as the browser starts). No blinking cursor at any point. `kiosk status` says *Start-up: quiet, with the Works In All Things logo*. |
| 8.2 | `sudo kiosk boot logo <a PNG file or https address>`. Restart. | Your logo instead, the same way. *Start-up: quiet, with your logo*. |
| 8.3 | `sudo kiosk boot logo <a text file>` | Refused: *The logo must be a PNG image*. Nothing changes. |
| 8.4 | `sudo kiosk boot logo default`. Restart. | The Works In All Things logo again. |
| 8.5 | Restart holding **Shift** (or pressing **Esc**) as it starts. | The boot menu appears. Choose the first entry: it starts as normal. |
| 8.6 | `sudo kiosk boot normal`. Restart. | The start-up text is back (the boot menu on Debian, the distribution's own start-up screen or messages), then the logo while the browser starts. *Start-up: start-up text shown, then …*. |
| 8.7 | `sudo kiosk boot quiet`, run it again, then restart. | Quiet again; the second run changes nothing (no *Updating the start-up image*). |
| 8.8 | Unplug the network and restart (a kiosk whose Signage player was stored for offline play). | The logo stays up for about 90 seconds, then the player plays offline. |
| 8.9 | `sudo kiosk uninstall`, then restart. | The start-up is as it was before Kiosk. `/etc/default/grub.d/90-kiosk.cfg` (Debian, Ubuntu), `/usr/share/plymouth/themes/kiosk` and `/etc/systemd/system/plymouth-quit.service.d/90-kiosk.conf` are gone; on a Raspberry Pi, `cmdline.txt` is as it was and `config.txt` has no Kiosk lines. |
| 8.10 | Install without questions with `--quiet-boot no`, and a managed install (7.1). | The first shows the start-up text (*Start-up: start-up text shown, …*); the managed one is quiet. Both show the logo while the browser starts. |

## 9. Remote control (VNC)

From another computer on the same network, with a VNC viewer: TigerVNC, and RealVNC Viewer if you have it.

| # | Do this | You should see |
|---|---|---|
| 9.1 | `kiosk vnc` | *VNC: off*. |
| 9.2 | `sudo kiosk vnc on`. Type a 5-character password, then two different ones, then a good one twice. | It installs wayvnc, refuses the short password and the mismatch, then *VNC is on (port 5900, user name kiosk)* and how to connect. The browser restarts. |
| 9.3 | Connect the viewer to `<kiosk IP>:5900`, user `kiosk`, the password. | It asks to trust the certificate (TigerVNC) or shows the key (RealVNC), then shows the screen. Moving the mouse moves a pointer on the TV; clicking and typing work in the page. |
| 9.4 | Connect with a wrong password. | Refused. |
| 9.5 | `sudo kiosk vnc password`, set a new one. | The old password is refused, the new one works. |
| 9.6 | `sudo kiosk vnc ssh-only`. Try 9.3 again, then `ssh -L 5901:localhost:5900 <you>@<kiosk IP>` and connect the viewer to `localhost:5901`. | Direct: no connection. Through the tunnel: it works. |
| 9.6a | On a Mac, with the tunnel from 9.6: Finder ▸ **Go ▸ Connect to Server**, `vnc://localhost:5901`, user `kiosk` and the VNC password. Then try `vnc://<kiosk IP>` after `sudo kiosk vnc on`. | Through the tunnel, Screen Sharing shows and controls the screen. Directly (with `on`), Screen Sharing can't sign in. |
| 9.6b | Note `wayvnc --version`. `sudo kiosk vnc on --allow-mac` (on Ubuntu 26.04, with wayvnc 0.9, it says *Building wayvnc 0.10* and *Built wayvnc: v0.10.2*; run it again: no rebuild). `kiosk vnc` says which wayvnc runs. Then `vnc://<kiosk IP>` in Screen Sharing, with the VNC password. Then `sudo kiosk vnc on` and try again. `sudo kiosk vnc on --mac` too. | With `--allow-mac` it signs in and works, and `kiosk vnc` says *Mac Screen Sharing allowed*. After plain `on`, it can't sign in. `--mac` is refused with how to use the command. |
| 9.7 | `sudo kiosk screen off`, then `sudo kiosk screen on`. | VNC drops while the screen is off and works again once it's back. |
| 9.8 | `sudo kiosk vnc off`, then `sudo reboot`. | No connection, before and after the restart. *VNC: off* in `kiosk status`. |
| 9.9 | On Fedora (firewalld on): `sudo kiosk vnc on`, `sudo firewall-cmd --list-services`, then `sudo kiosk vnc off` and list again. | `vnc-server` is listed while VNC is on, and gone after off. (On Ubuntu with `sudo ufw enable` first: `sudo ufw status` shows `5900/tcp` the same way.) |
| 9.10 | VNC on, then `sudo kiosk uninstall`. | `/etc/kiosk/vnc` and `/usr/local/lib/kiosk-wayvnc` are gone, and so is any firewall port from 9.9. |

## Results

Fill in one column per computer and distribution (for example *N100 mini PC, Debian 13*).

| Test | | | | |
|---|---|---|---|---|
| Hardware | Not noted | Proxmox virtual machine (display memory 32 MiB) | | |
| Distribution and version | Ubuntu 26.04 | Debian 13 (trixie) | | |
| Browser (`kiosk status`) | Chromium (Flathub) | Debian's Chromium | | |
| Kiosk version | 1.0.0 | 1.0.1 | | |
| 1.1–1.6 Install | ✓ (1.6 is for Debian) | ✓ | | |
| 2.1–2.2 Playing (note CPU for 2.2) | ✓ | ✓ | | |
| 2.3 Signage offline | ✓ | ✓ | | |
| 3.1–3.3 Recovery | ✓ | ✓ | | |
| 4.1–4.8 Settings | ✓ | ✓ | | |
| 5.1–5.2 Uninstall | ✓ | ✓ | | |
| 6.1 A week untouched | ✓ | Running since 2026-10-21 | | |
| 7.1–7.11 Managed by Rock | ✓ | ✓ | | |
| 8.1–8.10 Start-up screen | ✓ (1.1.0) | ✓ (1.1.0) | | |
| 2.4 Local network question | | | | |
| 9.1–9.10 Remote control (VNC) | 9.6b ✓ (Screen Sharing from a Mac over VPN; wayvnc 0.10.2 built by Kiosk) | | | |

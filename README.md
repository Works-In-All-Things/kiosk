# Works In All Things Kiosk

Turns a Linux computer into a TV player for one web address, such as a
[Signage](https://worksinallthings.com/plugins/signage/) Player URL or a Parent Page number board. It starts on
power-up, fills the screen, recovers on its own, and needs no keyboard or mouse once it's set up.

Free and open source (MIT license).

## Install

1. Install a Linux distribution on the computer (no desktop needed; see *What you need*).
2. Log in and run:

   ```bash
   curl -fsSL https://worksinallthings.com/kiosk/install.sh | sudo bash
   ```

   No curl? Use `wget -qO- https://worksinallthings.com/kiosk/install.sh | sudo bash`.

3. Answer the questions: the **address to show** (paste the Player URL), the time zone, screen rotation, when to
   turn the screen off and on (optional) and when to restart each night (3:30 am unless you change it). If the
   computer has Wi-Fi, it offers to set that up too.
4. Restart. From then on the computer shows the address whenever it's turned on.

To install without questions, pass the answers:

```bash
curl -fsSL https://worksinallthings.com/kiosk/install.sh | sudo bash -s -- \
    --url https://rock.example.org/signage/tv/AbCdE --timezone America/Chicago --yes --reboot
```

Running the installer again changes the settings and keeps anything you don't change.

## What you need

**Any 64-bit computer that runs Linux:** an Intel or AMD mini PC, an old desktop or laptop, or a Raspberry Pi 5.
Kiosk isn't tied to any hardware; it uses the distribution's own drivers.

| | Minimum | Better |
|---|---|---|
| Processor | 64-bit Intel/AMD (x86-64) or ARM (Raspberry Pi 4 or 5) | Intel N100 or newer, or a Raspberry Pi 5 |
| Memory | 4 GB | 8 GB |
| Storage | 16 GB (32 GB if the browser comes from Flathub) | 64 GB SSD |
| Graphics | Intel, AMD or Raspberry Pi graphics | Intel (smooth video with very little CPU) |

NVIDIA graphics work, but videos are decoded by the processor, so pair them with a fast one. Some Wi-Fi cards need
the distribution's non-free firmware.

**Any of these distributions** (the server or "lite" edition is best; Kiosk turns off a desktop's login screen if
there is one):

| Distribution | Browser |
|---|---|
| Debian 12 or 13 | Debian's Chromium |
| Raspberry Pi OS Lite (64-bit) | Raspberry Pi's Chromium |
| Ubuntu 24.04 LTS or later, and Ubuntu-based ones (Linux Mint, Pop!\_OS…) | Chromium from Flathub on Ubuntu (its own is a snap); the distribution's Chromium on Mint |
| Fedora 41 or later | Chromium from Flathub (Fedora's can't play most MP4 videos) |
| Arch Linux, and Arch-based ones | Arch's Chromium |
| openSUSE Tumbleweed or Leap | Chromium from Flathub |

It needs systemd and one of the apt, dnf, pacman or zypper package managers. It doesn't run on image-based systems
(Fedora Silverblue, SteamOS, Ubuntu Core) or on Alpine, Void or Gentoo.

## Commands

```text
sudo kiosk install                  Install, or change the settings (asks questions)
kiosk url                           Show the address
sudo kiosk url <address>            Show a different address
sudo kiosk rotate 0|90|180|270      Turn the picture for portrait or upside-down screens
sudo kiosk screen off|on            Turn the screen off or on now
sudo kiosk screen schedule 22:00 06:00
                                    Turn the screen off and on at these times each day
sudo kiosk screen schedule off      Keep the screen on
sudo kiosk restart-time 03:30|off   Restart the computer at this time each day
sudo kiosk restart                  Restart the browser
kiosk status                        Show what the kiosk is doing
sudo kiosk logs                     Show recent messages
sudo kiosk update                   Update Kiosk to the latest release
sudo kiosk uninstall                Remove Kiosk
```

To use these on a running kiosk, plug in a keyboard and press **Ctrl+Alt+F2** for a login prompt (**Ctrl+Alt+F1**
goes back), or connect over SSH if you've set it up.

## How it works

- **cage**, a display server that runs one app full screen with no desktop, starts **Chromium** in kiosk mode on
  the first screen. A systemd service (`kiosk.service`) starts it at boot and again within seconds if it closes.
- Chromium runs as a `kiosk` user that has no password and can't log in. Its data is kept in `/var/lib/kiosk`, so
  Signage's offline storage survives restarts: a TV that's turned on with no network still plays.
- At start-up it waits up to 90 seconds for the address to answer, then opens it either way.
- There are no first-run screens, "Restore pages?" bubbles, translate bars or update nags, and videos play with
  sound without a click.
- Settings are in `/etc/kiosk/kiosk.conf`. After editing it by hand, run `sudo kiosk restart`.
- **Screen off:** stops the browser and blanks the screen, which sends most TVs and monitors to sleep. A nightly
  restart during the off hours keeps the screen off.
- **Updates:** Debian, Ubuntu and Raspberry Pi OS get automatic security updates (unattended-upgrades), and Fedora
  gets dnf-automatic. A Flathub browser is updated daily. Arch and openSUSE have no standard automatic updates, so
  update those by hand now and then.

## Uninstall

```bash
sudo kiosk uninstall
```

It removes Kiosk's files, settings, timers and the `kiosk` user, turns the console login (and any desktop login
screen) back on, and leaves the installed packages, such as cage and Chromium, in place.

## Troubleshooting

- **Black screen:** run `kiosk status` and `sudo kiosk logs`. Check the address opens in a normal browser.
- **No sound:** the sound goes to the HDMI output the system picks. Check the TV's volume and input.
- **Offline storage for Signage** needs an `https://` address.
- **Rotation doesn't work:** rotation needs cage 0.2 or later, or a cage older than 0.1.5 (which rotates by
  itself). Check with `cage -v`.

## Developing

- `shellcheck -x kiosk install.sh lib/session lib/start lib/distro.sh` must be clean.
- From a copy of this repository, `sudo ./install.sh` installs that copy.
- To install a branch for testing: `curl -fsSL … | sudo KIOSK_REF=<branch> bash`.
- The release test is in [TESTING.md](TESTING.md).

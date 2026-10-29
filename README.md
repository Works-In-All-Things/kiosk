# Works In All Things Kiosk

Turns a Linux computer into a TV player for one web address, such as a
[Signage](https://worksinallthings.com/plugins/signage/) Player URL or a Parent Page number board. It starts on
power-up, fills the screen, recovers on its own, and needs no keyboard or mouse once it's set up.

Free and open source (MIT license; see *License*).

## Install

1. Install a Linux distribution on the computer (no desktop needed; see *What you need*).
2. Connect it to the network (wired, or Wi-Fi when you install the distribution), log in and run:

   ```bash
   curl -fsSL https://worksinallthings.com/kiosk/install.sh | bash
   ```

   It asks for your password (with sudo). No curl? Use `wget -qO- https://worksinallthings.com/kiosk/install.sh | bash`.
   `… | sudo bash` works too.

   **No sudo?** Debian leaves out sudo (and curl) when you set a root password during installation. Become root
   with `su -` (it asks for the root password), then run the `wget` command above. As root, leave `sudo` off every
   `kiosk` command below.

3. Answer the questions: the **address to show** (paste the Player URL), the **time zone** (pick a number from
   the US list, or type any zone name such as `Europe/London`), screen rotation, when to turn the screen off and
   on (optional), when to restart each night (3:30 am unless you change it), and whether to hide the start-up text
   (yes unless you say no; see *Start-up screen*). Press Enter to keep what's shown in brackets. A mistyped answer
   is simply asked again.
4. Restart. From then on the computer shows the address whenever it's turned on.

To install without questions, pass the answers:

```bash
curl -fsSL https://worksinallthings.com/kiosk/install.sh | bash -s -- \
    --url https://rock.example.org/signage/tv/AbCdE --timezone central --yes --reboot
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
sudo kiosk resolution 1920x1080|auto
                                    Set the screen resolution (auto: the screen's own best)
sudo kiosk screen off|on            Turn the screen off or on now
sudo kiosk screen schedule 22:00 06:00
                                    Turn the screen off and on at these times each day
sudo kiosk screen schedule off      Keep the screen on
sudo kiosk restart-time 03:30|off   Restart the computer at this time each day
sudo kiosk restart                  Restart the browser
sudo kiosk boot quiet|normal        Hide the start-up text, or show it again
sudo kiosk boot logo <file.png>|default
                                    Your logo while the computer starts (a file or an https address)
kiosk vnc                           Show whether remote control (VNC) is on, and how to connect
sudo kiosk vnc on|off               Allow control of the screen from the network over VNC, or stop it
sudo kiosk vnc on --allow-mac       Also allow the Mac's Screen Sharing (its picture isn't encrypted)
sudo kiosk vnc ssh-only             Allow VNC only through an SSH tunnel
sudo kiosk vnc password             Change the VNC password
kiosk status                        Show what the kiosk is doing
sudo kiosk logs                     Show recent messages
sudo kiosk update [branch or tag]    Update Kiosk to the latest release (does nothing if it's up to date)
sudo kiosk manage <rock address> <code>
                                    Let Rock manage this kiosk (see Managed by Rock)
sudo kiosk unmanage                 Stop Rock managing this kiosk
sudo kiosk uninstall                Remove Kiosk
```

To use these on a running kiosk, plug in a keyboard and press **Ctrl+Alt+F2** for a login prompt (**Ctrl+Alt+F1**
goes back), or connect over SSH if you've set it up.

## Managed by Rock

With the [**Screen Manager**](https://worksinallthings.com/plugins/screen-manager/) plugin for Rock RMS, you can
manage your kiosks from Rock instead of at each computer: see every one's health, change what it shows and when its
screen turns off, and restart or reboot it. In Rock they're called *screens*, because in Rock a kiosk means a check-in
device. Kiosk works on its own without it; managing it is optional. (The plugin was called *Kiosk Manager* until
October 2026; Kiosk works with either.)

1. In Rock, add the screen (**Admin Tools ▸ Installed Plugins ▸ Screen Manager ▸ Screens ▸ Add**). Rock shows a
   one-line command with a single-use code, which works for 24 hours.
2. On a new computer, paste the install command. It installs Kiosk without asking any questions: the address,
   time zone, rotation, screen times and nightly restart come from Rock. On a computer that already runs Kiosk, run
   `sudo kiosk manage <rock address> <code>` instead.

How it works:

- **The kiosk asks Rock; Rock never connects to the kiosk.** Once a minute (`kiosk-heartbeat.timer`) the kiosk
  sends Rock its health (Kiosk and browser versions, uptime, free disk and memory, temperature, whether the browser
  is running and the screen is on) and gets back its settings, when they've changed, and any actions. No ports are
  opened and nothing changes on the network.
- **Rock can only change the settings above and ask for five actions:** restart the browser, turn the screen off or
  on, reboot, and update Kiosk. Every setting goes through the same checks as the `kiosk` command, and anything
  else Rock sends is ignored. Nothing from Rock is ever run as a command.
- The computer proves itself with a token it got when it was linked. It's kept in `/etc/kiosk/manager.conf`,
  readable only by root, and Rock keeps only a hash of it. The Rock address must be `https://`; for a test server on
  `http://`, add `--allow-http`.
- While Rock manages a kiosk, the `kiosk` command shows its settings but won't change them (it says to change them in
  Rock). The screen on/off and restart commands still work.
- If Rock can't be reached (or something in between, such as a Wi-Fi sign-in page, answers instead of Kiosk
  Manager), the kiosk carries on with its current settings and tries again each minute. A kiosk made inactive in
  Rock is paused: it keeps reporting in, but gets no settings or actions until it's active again. If the
  kiosk is removed in Rock or given a new code, it keeps showing what it shows and stops sending heartbeats;
  `kiosk status` says so.
- `sudo kiosk unmanage` stops it: the settings stay as they are and the `kiosk` command can change them again.

## Remote control (VNC)

See and use the kiosk's screen, keyboard and mouse from another computer, as if you were standing at the TV. It's
off until you turn it on:

```bash
sudo kiosk vnc on
```

It installs **wayvnc**, asks for a password (8 or more characters), and restarts the browser. Then connect a VNC
viewer, such as [TigerVNC](https://tigervnc.org) or RealVNC Viewer, to the kiosk's IP address (port 5900; `kiosk
vnc` shows it), with the user name `kiosk` and that password. The first time, the viewer asks you to trust the
kiosk's certificate.

- **Always protected:** it asks for the password and encrypts the connection (TLS, or RSA-AES on wayvnc 0.7 and
  later). The Mac's own Screen Sharing can't encrypt the picture, so it connects through SSH (below); on a Mac,
  RealVNC Viewer or TigerVNC connect directly with full encryption.
- **Screen Sharing directly:** `sudo kiosk vnc on --allow-mac` lets the Mac's Screen Sharing connect from the
  network too (`vnc://<kiosk IP>` and the VNC password). Screen Sharing uses the old VNC password method, which
  checks only the first 8 characters and encrypts nothing, so anyone on that network could watch the picture and
  the typing. Use it on a network you trust; `sudo kiosk vnc on` turns it back off.
  - It needs wayvnc 0.10 or later. Where the distribution's is older (Ubuntu 26.04 has 0.9), Kiosk builds wayvnc
    0.10.2 from its source on GitHub, at fixed versions it checks, into `/usr/local/lib/kiosk-wayvnc` (on Debian,
    Ubuntu and Raspberry Pi OS; a minute or two, and the build tools stay installed). That copy doesn't get the
    distribution's updates; a newer Kiosk may build a newer one when you run `--allow-mac` again. Uninstall removes
    it. `kiosk vnc` shows which wayvnc runs.
- **From the network:** `on` listens on every network the kiosk is on. If a firewall is on (firewalld, as on
  Fedora, or ufw), Kiosk opens port 5900 and closes it again with `off` or uninstall.
- **Only through SSH:** `sudo kiosk vnc ssh-only` listens on the kiosk itself only. Connect with
  `ssh -L 5901:localhost:5900 you@<kiosk>`, then point the viewer at `localhost:5901`. SSH encrypts the
  connection, so here the Mac's **Screen Sharing** works too, with wayvnc 0.10 or later (for an older one, run
  `--allow-mac` once so Kiosk builds it): in the Finder, **Go ▸
  Connect to Server**, `vnc://localhost:5901`, user name `kiosk` and the VNC password.
- `sudo kiosk vnc password` changes the password; `sudo kiosk vnc off` turns it off. `kiosk status` shows it.
- It's part of the display, so it's away while the screen is off (`kiosk screen off` or the off hours), and the
  connection drops for a few seconds when the browser restarts.
- The password and keys are in `/etc/kiosk/vnc`, readable only by root and the kiosk user. A kiosk managed by Rock
  keeps VNC as set on the kiosk; Rock doesn't change it.

## Start-up screen

While the computer starts, the screen shows a logo on black, and the logo stays up until the page appears. It's the
Works In All Things logo unless you set your own:

```bash
sudo kiosk boot logo /home/me/logo.png        # or an https:// address of a PNG image
sudo kiosk boot logo default                  # back to the Works In All Things logo
```

Kiosk also hides the start-up text unless you answer no at install (`--quiet-boot no` without questions): no boot
menu and no scrolling messages. `sudo kiosk boot normal` shows them again (and `sudo kiosk boot quiet` hides them);
the logo still shows while the browser starts. Each change takes effect at the next restart, and `kiosk status`
shows which is set. A PNG with a transparent background works well; a logo bigger than half the screen is shrunk to
fit.

- **How:** quiet kernel options and a hidden boot menu, and a Plymouth start-up screen with Kiosk's theme, left on
  the screen until the browser takes over. The browser then opens a small start page with the same logo, which
  opens the address; the browser keeps the logo up until the page has something to show. On Debian, Ubuntu and
  Mint, Kiosk adds `/etc/default/grub.d/90-kiosk.cfg`; on Fedora it uses `grubby`; on a Raspberry Pi it adds
  options to `cmdline.txt` and turns off the rainbow square in `config.txt`. It only adds its own settings,
  remembers them in `/etc/kiosk/boot-state`, and `kiosk boot normal` or `kiosk uninstall` takes off exactly those.
- **The boot menu** is still there: hold **Shift** (or press **Esc**) as the computer starts.
- **No blinking cursor:** the text console's cursor is hidden too, including on Ctrl+Alt+F2. Type `setterm --cursor
  on` there to see it while you work.
- **Not changed:** the computer maker's logo before Linux starts (that's the firmware; some have a *quiet boot*
  option in their setup). On Arch and openSUSE without `grubby`, and on computers that ask for a disk password at
  start-up, Kiosk says so and leaves the start-up text as it is; the logo still shows while the browser starts.

## How it works

- **cage**, a display server that runs one app full screen with no desktop, starts **Chromium** in kiosk mode on
  the first screen. A systemd service (`kiosk.service`) starts it at boot and again within seconds if it closes.
- Chromium runs as a `kiosk` user that has no password and can't log in. Its data is kept in `/var/lib/kiosk`, so
  Signage's offline storage survives restarts: a TV that's turned on with no network still plays.
- If the display can't start with graphics acceleration, it starts again drawing in software (see
  *Troubleshooting*). Each restart of the computer tries acceleration first.
- At start-up it waits up to 90 seconds for the address to answer with a page (with the logo on the screen), so a
  server that's restarting, which answers with an error meanwhile, has time to be ready. Then it opens it
  either way.
- There are no first-run screens, "Restore pages?" bubbles, translate bars or update nags, and videos play with
  sound without a click.
- **Local network:** Chromium asks before a site reaches devices on the local network (*wants to access other
  devices on your local network*). Kiosk answers for the kiosk's own site with a Chromium policy, written each time
  the browser starts, so a page that loads something from your network never stops at that question. Other sites
  still get it. The policy is in `/var/lib/flatpak/extension/org.chromium.Chromium.Extension.kiosk` (Chromium from
  Flathub) or `/etc/chromium/policies/managed/works-in-all-things-kiosk.json` (the distribution's Chromium).
- Settings are in `/etc/kiosk/kiosk.conf`. After editing it by hand, run `sudo kiosk restart`.
- **Screen off:** stops the browser and blanks the screen, which sends most TVs and monitors to sleep. A nightly
  restart during the off hours keeps the screen off.
- **Kiosk's own updates:** `sudo kiosk update` installs the latest release, keeping the settings, and does nothing
  when the kiosk already has it. A test build installed from a branch (`KIOSK_REF=<branch>`) follows that branch
  until there's a release. Kiosk remembers where it came from in `/etc/kiosk/installed-from`.
- **Updates:** Debian, Ubuntu and Raspberry Pi OS get automatic security updates (unattended-upgrades), and Fedora
  gets dnf-automatic. A Flathub browser is updated daily. Arch and openSUSE have no standard automatic updates, so
  update those by hand now and then.

## Uninstall

```bash
sudo kiosk uninstall
```

It removes Kiosk's files, settings, timers, browser policy, VNC settings (and any firewall port it opened) and
the `kiosk` user, puts the start-up text and screen
back as they were, turns the console login (and any desktop login screen) back on, and leaves the installed packages, such as
cage, Chromium and Plymouth, in place.

## Troubleshooting

- **"sudo: command not found":** Debian doesn't install sudo when a root password is set during installation. Run
  `su -` to become root, then run the command without `sudo`. To use sudo instead, install it as root with
  `apt install sudo`, add yourself with `usermod -aG sudo yourname`, and log in again.
- **Black screen:** run `kiosk status` and `sudo kiosk logs`. Check the address opens in a normal browser.
- **VirtualBox:** give the VM **Settings ▸ Display ▸ Graphics Controller: VMSVGA**, **Enable 3D Acceleration** and
  128 MB of video memory. Without 3D acceleration the display can't use the graphics card, so Kiosk draws in
  software (`kiosk status` says *drawing without graphics acceleration*): the page shows, but video isn't smooth.
- **"drawing without graphics acceleration"** on a real computer means its graphics have no working driver. The page
  still shows; `sudo kiosk logs` has the display server's messages from the first try.
- **Changing Wi-Fi:** use the distribution's own tool, such as `sudo nmtui` where NetworkManager is installed
  (Raspberry Pi OS, Fedora and most desktops) or `sudo raspi-config` on a Raspberry Pi. Kiosk leaves the network
  settings alone.
- **No sound:** the sound goes to the HDMI output the system picks. Check the TV's volume and input.
- **Offline storage for Signage:** browsers only allow it on `https://` addresses. For an `http://` address, such
  as a test server on the local network, Kiosk tells Chromium to treat that one address as secure, so it works
  there too.
- **Black bars, or a blurry or slow picture:** the screen's resolution isn't 16:9 or is higher than needed. Run
  `sudo kiosk resolution 1920x1080` (`auto` goes back to the screen's own best). This also suits 4K TVs on small
  computers, and virtual machines such as Proxmox, whose virtual screen is often 1280×800 or 1024×768. For Signage,
  the display group's *Fill the screen* setting fills the screen instead, cutting off the edges.
- **The install stopped with an error:** the end of `/var/log/kiosk-install.log` is shown; the whole log has more.
- **Rotation or resolution doesn't work:** these need cage 0.2 or later (rotation also works on cage older than
  0.1.5). Check with `cage -v`, and see `sudo kiosk logs`: when a screen won't take the resolution, it says
  *Couldn't set … (it's …)*.
- **A virtual machine won't take the resolution**, and the log (`sudo kiosk logs`) shows *Atomic commit failed:
  Cannot allocate memory*: its virtual display has too little memory. In Proxmox, open the VM's **Hardware ▸
  Display**, set **Memory** to 64 MiB (32 at least for 1920×1080), then shut the VM down and start it again.

## Developing

- What changed in each version: [CHANGELOG.md](CHANGELOG.md).
- `shellcheck -x kiosk install.sh lib/session lib/start lib/distro.sh lib/manage.sh` must be clean.
- From a copy of this repository, `sudo ./install.sh` installs that copy.
- To install a branch for testing: `curl -fsSL … | KIOSK_REF=<branch> bash`.
- The release test is in [TESTING.md](TESTING.md).
- **Releases:** set `VERSION` and add its section to CHANGELOG.md. When that reaches `main`, the *Release* workflow
  (`.github/workflows/release.yml`) tags the merge `v<VERSION>` and publishes the release with those notes.

## License

MIT: see [LICENSE](LICENSE). You're welcome to use, change and share Kiosk, including in your own projects.

The license covers the code, not the name or the logo. "Works In All Things" and its logo (`lib/plymouth/logo.png`)
are not licensed for other projects, so a changed copy you share must use its own name, logo and installer address,
not worksinallthings.com. Kiosks running Kiosk itself may show the logo, and each church can replace it with its own.

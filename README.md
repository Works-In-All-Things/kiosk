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

With the **Kiosk Manager** plugin for Rock RMS, you can manage your kiosks from Rock instead of at each computer:
see every kiosk's health, change what it shows and when its screen turns off, and restart or reboot it. Kiosk works
on its own without it; managing it is optional.

1. In Rock, add the kiosk (**Admin Tools ▸ Installed Plugins ▸ Kiosk Manager ▸ Kiosks ▸ Add**). Rock shows a
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
- At start-up it waits up to 90 seconds for the address to answer (with the logo on the screen), then opens it
  either way.
- There are no first-run screens, "Restore pages?" bubbles, translate bars or update nags, and videos play with
  sound without a click.
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

It removes Kiosk's files, settings, timers and the `kiosk` user, puts the start-up text and screen back as they
were, turns the console login (and any desktop login screen) back on, and leaves the installed packages, such as
cage, Chromium and Plymouth, in place.

## Troubleshooting

- **"sudo: command not found":** Debian doesn't install sudo when a root password is set during installation. Run
  `su -` to become root, then run the command without `sudo`. To use sudo instead, install it as root with
  `apt install sudo`, add yourself with `usermod -aG sudo yourname`, and log in again.
- **Black screen:** run `kiosk status` and `sudo kiosk logs`. Check the address opens in a normal browser.
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

## License

MIT: see [LICENSE](LICENSE). You're welcome to use, change and share Kiosk, including in your own projects.

The license covers the code, not the name or the logo. "Works In All Things" and its logo (`lib/plymouth/logo.png`)
are not licensed for other projects, so a changed copy you share must use its own name, logo and installer address,
not worksinallthings.com. Kiosks running Kiosk itself may show the logo, and each church can replace it with its own.

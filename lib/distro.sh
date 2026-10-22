# shellcheck shell=bash
# Works In All Things Kiosk: finds the Linux distribution and installs packages with its package manager.
# Sourced by the kiosk command; it sets these:
#   DISTRO_NAME    the distribution's name, for messages ("Debian GNU/Linux 12 (bookworm)")
#   DISTRO_FAMILY  apt, dnf, pacman or zypper

# Finds the distribution and its package manager. Stops with a message on anything not supported.
detect_distro() {
    DISTRO_NAME="Linux"
    if [[ -r /etc/os-release ]]; then
        DISTRO_NAME=$(. /etc/os-release && printf '%s' "${PRETTY_NAME:-${NAME:-Linux}}")
    fi

    if command -v apt-get >/dev/null 2>&1; then
        DISTRO_FAMILY=apt
    elif command -v dnf >/dev/null 2>&1; then
        DISTRO_FAMILY=dnf
    elif command -v pacman >/dev/null 2>&1; then
        DISTRO_FAMILY=pacman
    elif command -v zypper >/dev/null 2>&1; then
        DISTRO_FAMILY=zypper
    else
        die "$DISTRO_NAME isn't supported: Kiosk needs apt, dnf, pacman or zypper to install its packages."
    fi
}

# Refreshes the package lists. On Arch this also updates the system, because Arch doesn't support partial updates.
pkg_refresh() {
    case $DISTRO_FAMILY in
        apt) DEBIAN_FRONTEND=noninteractive apt-get update -q ;;
        dnf) dnf -q makecache ;;
        pacman) pacman -Syu --noconfirm ;;
        zypper) zypper --non-interactive --quiet refresh ;;
    esac
}

# Installs packages, and stops if any of them can't be installed.
pkg_install() {
    [[ $# -gt 0 ]] || return 0
    info "Installing: $*"
    case $DISTRO_FAMILY in
        apt) quietly env DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends "$@" ;;
        dnf) quietly dnf install -y -q "$@" ;;
        pacman) quietly pacman -S --needed --noconfirm "$@" ;;
        zypper) quietly zypper --non-interactive --quiet install --no-recommends "$@" ;;
    esac || die "These packages couldn't be installed: $*"
}

# Installs whichever of the packages this distribution has, one at a time, and carries on past any it doesn't.
pkg_install_optional() {
    local package
    local -a found=()
    for package in "$@"; do
        if pkg_available "$package"; then
            found+=("$package")
        fi
    done
    [[ ${#found[@]} -gt 0 ]] || return 0
    info "Installing: ${found[*]}"
    case $DISTRO_FAMILY in
        apt) quietly env DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends "${found[@]}" ;;
        dnf) quietly dnf install -y -q --skip-broken "${found[@]}" ;;
        pacman) quietly pacman -S --needed --noconfirm "${found[@]}" ;;
        zypper) quietly zypper --non-interactive --quiet install --no-recommends "${found[@]}" ;;
    esac || warn "Some of these optional packages couldn't be installed: ${found[*]}"
}

# Succeeds if the distribution's repositories have the package.
pkg_available() {
    case $DISTRO_FAMILY in
        apt)
            local candidate
            candidate=$(apt-cache policy "$1" 2>/dev/null | sed -n 's/^ *Candidate: //p')
            [[ -n $candidate && $candidate != "(none)" ]]
            ;;
        dnf) dnf -q list --available "$1" >/dev/null 2>&1 || rpm -q "$1" >/dev/null 2>&1 ;;
        pacman) pacman -Si "$1" >/dev/null 2>&1 ;;
        zypper) zypper --non-interactive --quiet info "$1" 2>/dev/null | grep -q "^Name *: *$1\$" ;;
    esac
}

# Prints the distribution's Chromium package if it's a real package with full video support, or nothing if
# Chromium should come from Flathub instead. Ubuntu's chromium is only a link to the snap, and Fedora's and
# openSUSE's leave out the H.264 video most MP4 files use.
native_chromium_package() {
    case $DISTRO_FAMILY in
        apt)
            local package candidate
            for package in chromium chromium-browser; do
                candidate=$(apt-cache policy "$package" 2>/dev/null | sed -n 's/^ *Candidate: //p')
                if [[ -n $candidate && $candidate != "(none)" && $candidate != *snap* ]]; then
                    printf '%s' "$package"
                    return
                fi
            done
            ;;
        pacman) printf 'chromium' ;;
    esac
}

# The packages Kiosk can't work without: the cage display server, Xwayland for older apps, curl, and jq (for
# talking to Rock when the kiosk is managed by the Kiosk Manager plugin).
required_packages() {
    case $DISTRO_FAMILY in
        apt) printf '%s\n' cage xwayland curl ca-certificates jq ;;
        dnf) printf '%s\n' cage xorg-x11-server-Xwayland curl jq ;;
        pacman) printf '%s\n' cage xorg-xwayland curl jq ;;
        zypper) printf '%s\n' cage xwayland curl jq ;;
    esac
}

# Packages that make things better where the distribution has them: screen rotation, sound, video decoding,
# emoji and a session bus for the browser.
optional_packages() {
    case $DISTRO_FAMILY in
        apt) printf '%s\n' wlr-randr dbus-user-session pipewire-audio pipewire-pulse wireplumber \
            mesa-va-drivers intel-media-va-driver fonts-noto-color-emoji ;;
        dnf) printf '%s\n' wlr-randr pipewire-pulseaudio wireplumber mesa-va-drivers intel-media-driver \
            libva-intel-media-driver google-noto-color-emoji-fonts ;;
        pacman) printf '%s\n' wlr-randr pipewire pipewire-pulse wireplumber intel-media-driver libva-mesa-driver \
            noto-fonts noto-fonts-emoji ;;
        zypper) printf '%s\n' wlr-randr pipewire-pulseaudio wireplumber intel-media-driver Mesa-libva \
            noto-coloremoji-fonts ;;
    esac
}

# Turns on automatic security updates where the distribution has a standard way to. Never overwrites a
# setting that's already there.
enable_automatic_updates() {
    case $DISTRO_FAMILY in
        apt)
            pkg_install_optional unattended-upgrades
            if [[ ! -e /etc/apt/apt.conf.d/20auto-upgrades ]]; then
                printf '%s\n' 'APT::Periodic::Update-Package-Lists "1";' 'APT::Periodic::Unattended-Upgrade "1";' \
                    >/etc/apt/apt.conf.d/20auto-upgrades
            fi
            ;;
        dnf)
            pkg_install_optional dnf-automatic dnf5-plugin-automatic
            if [[ ! -e /etc/dnf/automatic.conf ]]; then
                mkdir -p /etc/dnf
                printf '%s\n' '[commands]' 'upgrade_type = security' 'apply_updates = yes' >/etc/dnf/automatic.conf
            fi
            local timer
            for timer in dnf5-automatic.timer dnf-automatic.timer; do
                if systemctl cat "$timer" >/dev/null 2>&1; then
                    systemctl enable --now "$timer" >/dev/null 2>&1 || true
                    break
                fi
            done
            ;;
        *)
            warn "$DISTRO_NAME has no standard automatic updates. Update it now and then with its package manager."
            ;;
    esac
}

# Start-up screen ---------------------------------------------------------------------------------------------
# Kiosk can hide the start-up text by adding kernel options and hiding the boot menu, and show a black screen (or
# the kiosk's logo) with Plymouth until the browser starts. How depends on the boot loader. Everything added is
# remembered in the boot state (boot_state, set_boot_state in the kiosk command), so it can be taken off again.

# The kernel options for a quiet start: no messages, no blinking text cursor, a splash screen, and the splash
# screen on the display even when there's a serial console (as on a Raspberry Pi). Hiding the cursor also hides it
# on the text consoles (Ctrl+Alt+F2); "setterm --cursor on" shows it there.
KIOSK_BOOT_ARGS="quiet splash loglevel=3 systemd.show_status=false rd.systemd.show_status=false udev.log_level=3 rd.udev.log_level=3 vt.global_cursor_default=0 plymouth.ignore-serial-consoles"
# The GRUB settings file Kiosk adds on Debian, Ubuntu and Mint.
GRUB_DROPIN=/etc/default/grub.d/90-kiosk.cfg
# Marks the lines Kiosk adds to a Raspberry Pi's config.txt.
RPI_BLOCK_START="# >>> Works In All Things Kiosk (removed by \"kiosk boot normal\")"
RPI_BLOCK_END="# <<< Works In All Things Kiosk"

# Prints the path of a file in a Raspberry Pi's boot partition (cmdline.txt or config.txt), or nothing.
boot_firmware_file() {
    local dir
    for dir in /boot/firmware /boot; do
        if [[ -f $dir/$1 ]]; then
            printf '%s' "$dir/$1"
            return
        fi
    done
}

# Prints how this computer's kernel options are set, or nothing when Kiosk doesn't know how:
#   raspberrypi  cmdline.txt and config.txt in the boot partition (Raspberry Pi OS)
#   grubby       grubby (Fedora, and others that use it)
#   grub-d       a file in /etc/default/grub.d, then update-grub (Debian, Ubuntu, Mint)
boot_method() {
    if [[ -n $(boot_firmware_file cmdline.txt) ]]; then
        echo raspberrypi
    elif command -v grubby >/dev/null 2>&1; then
        echo grubby
    elif command -v update-grub >/dev/null 2>&1 && [[ -f /etc/default/grub ]]; then
        echo grub-d
    fi
}

# Adds the kernel options for a quiet start and hides the boot menu. Only what isn't there yet is added, and that
# is remembered, so boot_args_remove takes off exactly that.
boot_args_add() {
    local arg current added missing=""
    case $1 in
        grub-d)
            local content
            content=$(cat <<GRUB
# Works In All Things Kiosk: a quiet start-up, with no boot menu or messages. "kiosk boot normal" removes this
# file. To reach the boot menu, hold Shift (or press Esc) as the computer starts.
GRUB_TIMEOUT=0
GRUB_TIMEOUT_STYLE=hidden
GRUB_CMDLINE_LINUX_DEFAULT="\$GRUB_CMDLINE_LINUX_DEFAULT $KIOSK_BOOT_ARGS"
GRUB
            )
            if [[ ! -f $GRUB_DROPIN || $(cat "$GRUB_DROPIN") != "$content" ]]; then
                mkdir -p "${GRUB_DROPIN%/*}"
                printf '%s\n' "$content" >"$GRUB_DROPIN"
                quietly update-grub || die "Couldn't update the boot menu (update-grub). Run: ${SUDO_HINT}kiosk boot normal"
            fi
            ;;
        grubby)
            current=" $(grubby --info=DEFAULT 2>/dev/null | sed -n 's/^args="\(.*\)"$/\1/p') "
            for arg in $KIOSK_BOOT_ARGS; do
                [[ $current == *" $arg "* ]] || missing+=" $arg"
            done
            if [[ -n $missing ]]; then
                quietly grubby --update-kernel=ALL --args="${missing# }" || die "Couldn't change the kernel options (grubby)."
                added=$(boot_state ARGS)
                set_boot_state ARGS "${added:+$added }${missing# }"
            fi
            if command -v grub2-editenv >/dev/null 2>&1 && ! grub2-editenv list 2>/dev/null | grep -qx 'menu_auto_hide=1'; then
                grub2-editenv - set menu_auto_hide=1 && set_boot_state MENU_AUTO_HIDE yes
            fi
            ;;
        raspberrypi)
            local cmdline config
            cmdline=$(boot_firmware_file cmdline.txt)
            current=" $(head -n 1 "$cmdline") "
            for arg in $KIOSK_BOOT_ARGS; do
                [[ $current == *" $arg "* ]] || missing+=" $arg"
            done
            if [[ -n $missing ]]; then
                printf '%s%s\n' "$(head -n 1 "$cmdline")" "$missing" >"$cmdline.new"
                mv "$cmdline.new" "$cmdline"
                added=$(boot_state ARGS)
                set_boot_state ARGS "${added:+$added }${missing# }"
            fi
            # No rainbow square at power-on. [all] makes it apply whatever section the file ends in.
            config=$(boot_firmware_file config.txt)
            if [[ -n $config ]] && ! grep -qxF "$RPI_BLOCK_START" "$config"; then
                [[ -z $(tail -c 1 "$config") ]] || echo >>"$config"
                printf '%s\n[all]\ndisable_splash=1\n%s\n' "$RPI_BLOCK_START" "$RPI_BLOCK_END" >>"$config"
            fi
            ;;
    esac
}

# Takes off what boot_args_add added, and shows the boot menu again.
boot_args_remove() {
    local arg args line
    case $1 in
        grub-d)
            if [[ -f $GRUB_DROPIN ]]; then
                rm -f "$GRUB_DROPIN"
                quietly update-grub || warn "Couldn't update the boot menu (update-grub). Run it by hand."
            fi
            ;;
        grubby)
            args=$(boot_state ARGS)
            if [[ -n $args ]]; then
                quietly grubby --update-kernel=ALL --remove-args="$args" || warn "Couldn't change the kernel options (grubby)."
                set_boot_state ARGS ""
            fi
            if [[ $(boot_state MENU_AUTO_HIDE) == yes ]]; then
                grub2-editenv - unset menu_auto_hide || true
                set_boot_state MENU_AUTO_HIDE ""
            fi
            ;;
        raspberrypi)
            local cmdline config
            cmdline=$(boot_firmware_file cmdline.txt)
            args=$(boot_state ARGS)
            if [[ -n $args && -n $cmdline ]]; then
                line=" $(head -n 1 "$cmdline") "
                for arg in $args; do
                    line=${line// "$arg" / }
                done
                line=${line# }
                printf '%s\n' "${line% }" >"$cmdline.new"
                mv "$cmdline.new" "$cmdline"
                set_boot_state ARGS ""
            fi
            config=$(boot_firmware_file config.txt)
            if [[ -n $config ]] && grep -qxF "$RPI_BLOCK_START" "$config"; then
                awk -v start="$RPI_BLOCK_START" -v end="$RPI_BLOCK_END" \
                    '$0 == start { skip = 1; next } skip { if ($0 == end) skip = 0; next } { print }' "$config" >"$config.new"
                mv "$config.new" "$config"
            fi
            ;;
    esac
}

# The packages for the start-up screen: Plymouth and its script module. Nothing on Arch, where Plymouth needs the
# start-up image settings (mkinitcpio.conf) changed by hand.
plymouth_packages() {
    case $DISTRO_FAMILY in
        apt) echo plymouth ;;
        dnf | zypper) printf '%s\n' plymouth plymouth-plugin-script ;;
    esac
}

# Succeeds if Plymouth's script module, which Kiosk's theme uses, is installed.
plymouth_has_script_module() {
    find /usr/lib /usr/lib64 -path '*plymouth/script.so' -print -quit 2>/dev/null | grep -q .
}

# Prints the start-up screen theme in use, or nothing.
plymouth_current_theme() {
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then
        plymouth-set-default-theme 2>/dev/null || true
    else
        update-alternatives --query default.plymouth 2>/dev/null | sed -n 's|^Value: .*/\([^/]*\)\.plymouth$|\1|p'
    fi
}

# Makes Kiosk's theme the start-up screen. Distributions choose it in one of two ways (Fedora and Debian with
# plymouth-set-default-theme, Ubuntu with update-alternatives), so both are set where they exist.
plymouth_use_kiosk_theme() {
    local theme=$1/kiosk.plymouth
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then
        plymouth-set-default-theme kiosk
    fi
    if command -v update-alternatives >/dev/null 2>&1 &&
        { update-alternatives --query default.plymouth >/dev/null 2>&1 || ! command -v plymouth-set-default-theme >/dev/null 2>&1; }; then
        update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$theme" 300 >/dev/null
        update-alternatives --set default.plymouth "$theme" >/dev/null
    fi
}

# Puts back the start-up screen theme that was in use before Kiosk's, or the distribution's default.
plymouth_restore_theme() {
    local before=$1 theme=$2/kiosk.plymouth
    if command -v plymouth-set-default-theme >/dev/null 2>&1; then
        if [[ -n $before && $before != kiosk && -d /usr/share/plymouth/themes/$before ]]; then
            plymouth-set-default-theme "$before" || true
        else
            plymouth-set-default-theme --reset || true
        fi
    fi
    if update-alternatives --query default.plymouth 2>/dev/null | grep -qF "$theme"; then
        update-alternatives --remove default.plymouth "$theme" >/dev/null 2>&1 || true
    fi
}

# Rebuilds the start-up image (initramfs) for the running kernel, so it has the start-up screen.
rebuild_initramfs() {
    if command -v update-initramfs >/dev/null 2>&1; then
        update-initramfs -u
    elif command -v dracut >/dev/null 2>&1; then
        dracut -f
    fi
}

# Prints the packages Kiosk needs to build wayvnc itself (when the distribution's is too old for the Mac's Screen
# Sharing), one per line, or nothing where it doesn't know how to build it.
wayvnc_build_packages() {
    case $DISTRO_FAMILY in
        apt)
            printf '%s\n' git meson ninja-build gcc pkg-config libwayland-dev wayland-protocols libpixman-1-dev \
                libxkbcommon-dev libgnutls28-dev nettle-dev libgmp-dev libjpeg-dev libdrm-dev libgbm-dev \
                libjansson-dev zlib1g-dev
            ;;
    esac
}

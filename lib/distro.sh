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
        apt) DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends "$@" ;;
        dnf) dnf install -y -q "$@" ;;
        pacman) pacman -S --needed --noconfirm "$@" ;;
        zypper) zypper --non-interactive --quiet install --no-recommends "$@" ;;
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
        apt) DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends "${found[@]}" ;;
        dnf) dnf install -y -q --skip-broken "${found[@]}" ;;
        pacman) pacman -S --needed --noconfirm "${found[@]}" ;;
        zypper) zypper --non-interactive --quiet install --no-recommends "${found[@]}" ;;
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

# The packages Kiosk can't work without: the cage display server, Xwayland for older apps, and curl.
required_packages() {
    case $DISTRO_FAMILY in
        apt) printf '%s\n' cage xwayland curl ca-certificates ;;
        dnf) printf '%s\n' cage xorg-x11-server-Xwayland curl ;;
        pacman) printf '%s\n' cage xorg-xwayland curl ;;
        zypper) printf '%s\n' cage xwayland curl ;;
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

# The NetworkManager packages, for setting up Wi-Fi.
network_manager_packages() {
    case $DISTRO_FAMILY in
        apt) printf '%s\n' network-manager ;;
        dnf) printf '%s\n' NetworkManager NetworkManager-tui NetworkManager-wifi ;;
        pacman) printf '%s\n' networkmanager ;;
        zypper) printf '%s\n' NetworkManager ;;
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

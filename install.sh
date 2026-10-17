#!/usr/bin/env bash
# Works In All Things Kiosk installer. Run it with:
#
#   curl -fsSL https://worksinallthings.com/kiosk/install.sh | bash
#
# (it asks for your password with sudo), or, without curl:
#
#   wget -qO- https://worksinallthings.com/kiosk/install.sh | bash
#
# "... | sudo bash" works too.
#
# It downloads the latest Kiosk release and runs "kiosk install", which asks for the address to show. Options
# after "bash -s --" are passed on, for example: ... | bash -s -- --url https://rock.example.org/signage/tv/abc
# To install a branch or tag instead of the latest release, set KIOSK_REF: ... | KIOSK_REF=main bash
#
# Everything is inside main(), so a download cut off part way through runs nothing.
set -euo pipefail

KIOSK_REPO=Works-In-All-Things/kiosk

# Prints an error and stops.
die() {
    printf '\033[1;31mError:\033[0m %s\n' "$*" >&2
    exit 1
}

# Downloads an address to standard output with curl or wget.
download() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$1"
    else
        die "Install curl or wget first."
    fi
}

main() {
    local -a run_as_root=()
    if [[ $EUID -ne 0 ]]; then
        command -v sudo >/dev/null 2>&1 || die "Run this as root, or install sudo first."
        run_as_root=(sudo)
    fi

    # Run from a copy of the repository: install that copy.
    local here=""
    [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]] && here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
    if [[ -n $here && -f $here/kiosk && -f $here/lib/distro.sh ]]; then
        exec "${run_as_root[@]}" bash "$here/kiosk" install "$@"
    fi

    local ref=${KIOSK_REF:-}
    if [[ -z $ref ]]; then
        ref=$(download "https://api.github.com/repos/$KIOSK_REPO/releases/latest" 2>/dev/null |
            sed -n 's/^ *"tag_name": *"\([^"]*\)".*/\1/p' || true)
        [[ -n $ref ]] || ref=main
    fi

    # The download is left in /tmp (it's small, and cleared at the next restart) because the installer below must
    # replace this process with exec: under some versions of sudo (sudo-rs on Ubuntu 25.10 and later), only the
    # process sudo started can read the keyboard when the script arrives through a pipe.
    local dir
    dir=$(mktemp -d)
    echo "Downloading Works In All Things Kiosk ($ref)"
    # A release tag, or else a branch (branch names such as "feature/x" only work in the long form).
    download "https://github.com/$KIOSK_REPO/archive/refs/tags/$ref.tar.gz" 2>/dev/null |
        tar -xz --warning=no-timestamp -C "$dir" --strip-components 1 2>/dev/null ||
        download "https://github.com/$KIOSK_REPO/archive/refs/heads/$ref.tar.gz" |
        tar -xz --warning=no-timestamp -C "$dir" --strip-components 1 ||
        die "Couldn't download Kiosk ($ref)."
    chmod -R a+rX "$dir"

    if [[ ${#run_as_root[@]} -gt 0 ]]; then
        # Not root (run as "curl ... | bash"): sudo asks for the password, reading from the keyboard rather than
        # from the pipe the script arrived on.
        exec sudo bash "$dir/kiosk" install "$@" </dev/tty
    fi
    exec bash "$dir/kiosk" install "$@"
}

main "$@"

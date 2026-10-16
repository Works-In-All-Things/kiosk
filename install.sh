#!/usr/bin/env bash
# Works In All Things Kiosk installer. Run it with:
#
#   curl -fsSL https://worksinallthings.com/kiosk/install.sh | sudo bash
#
# or, without curl:
#
#   wget -qO- https://worksinallthings.com/kiosk/install.sh | sudo bash
#
# It downloads the latest Kiosk release and runs "kiosk install", which asks for the address to show. Options
# after "bash -s --" are passed on, for example: ... | sudo bash -s -- --url https://rock.example.org/signage/tv/abc
# To install a branch or tag instead of the latest release, set KIOSK_REF: ... | sudo KIOSK_REF=main bash
#
# Everything is inside main(), so a download cut off part way through runs nothing.
set -euo pipefail

KIOSK_REPO=randyjreed/kiosk

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
    [[ $EUID -eq 0 ]] || die "Run this as root: curl -fsSL https://worksinallthings.com/kiosk/install.sh | sudo bash"

    # Run from a copy of the repository: install that copy.
    local here=""
    [[ -n ${BASH_SOURCE[0]:-} && -f ${BASH_SOURCE[0]} ]] && here=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
    if [[ -n $here && -f $here/kiosk && -f $here/lib/distro.sh ]]; then
        exec bash "$here/kiosk" install "$@"
    fi

    local ref=${KIOSK_REF:-}
    if [[ -z $ref ]]; then
        ref=$(download "https://api.github.com/repos/$KIOSK_REPO/releases/latest" 2>/dev/null |
            sed -n 's/^ *"tag_name": *"\([^"]*\)".*/\1/p' || true)
        [[ -n $ref ]] || ref=main
    fi

    local dir
    dir=$(mktemp -d)
    # shellcheck disable=SC2064 # The folder is known now and must be removed whatever happens later.
    trap "rm -rf '$dir'" EXIT
    echo "Downloading Works In All Things Kiosk ($ref)"
    # A release tag, or else a branch (branch names such as "feature/x" only work in the long form).
    download "https://github.com/$KIOSK_REPO/archive/refs/tags/$ref.tar.gz" 2>/dev/null |
        tar -xz --warning=no-timestamp -C "$dir" --strip-components 1 2>/dev/null ||
        download "https://github.com/$KIOSK_REPO/archive/refs/heads/$ref.tar.gz" |
        tar -xz --warning=no-timestamp -C "$dir" --strip-components 1 ||
        die "Couldn't download Kiosk ($ref)."
    bash "$dir/kiosk" install "$@"
}

main "$@"

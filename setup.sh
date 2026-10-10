#!/usr/bin/env bash
set -Eeuo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DRY_RUN=false
CONFIG="$ROOT/config/local.sh"
while (($#)); do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --config) (($# >= 2)) || { echo "--config needs a file" >&2; exit 2; }; CONFIG=$2; [[ -f $CONFIG ]] || { echo "Missing config: $CONFIG" >&2; exit 2; }; shift 2 ;;
        --help|-h) echo "Usage: ./setup.sh [--dry-run] [--config FILE]"; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 2 ;;
    esac
done
source "$ROOT/config/defaults.sh"
[[ ! -f $CONFIG ]] || source "$CONFIG"
source "$ROOT/scripts/common.sh"
for key in UPDATE_SYSTEM RPMFUSION CHROME NERD_FONT CLAUDE CODEX; do
    [[ ${!key} == true || ${!key} == false ]] || die "$key must be true or false"
done
[[ $NVIDIA == auto || $NVIDIA == true || $NVIDIA == false ]] || die "NVIDIA must be auto, true or false"
[[ $DESKTOP == kde || $DESKTOP == none ]] || die "DESKTOP must be kde or none"
source /etc/os-release
[[ $ID == fedora && ! -e /run/ostree-booted ]] || die "Supported target: mutable Fedora (not Atomic/Kinoite)"
[[ $(uname -m) == x86_64 || $CHROME == false ]] || die "Google Chrome RPM requires x86_64; set CHROME=false"
if [[ $NVIDIA == auto ]]; then
    NVIDIA=false
    for vendor in /sys/bus/pci/devices/*/vendor; do
        [[ -r $vendor ]] || continue
        if [[ $(<"$vendor") == 0x10de ]]; then NVIDIA=true; break; fi
    done
fi
[[ $NVIDIA == false || $RPMFUSION == true ]] || die "NVIDIA requires RPMFUSION=true"
if ! $DRY_RUN; then
    ((EUID != 0)) || die "Run as your desktop user; sudo is used only for system changes"
    command -v sudo >/dev/null || die "sudo is required"
    mkdir -p "${XDG_RUNTIME_DIR:-$HOME/.cache}/linux-dotfiles"
    exec 9>"${XDG_RUNTIME_DIR:-$HOME/.cache}/linux-dotfiles/setup.lock"
    flock -n 9 || die "Another setup is running"
    sudo -v
fi
export PATH="$HOME/.local/bin:$PATH"
source "$ROOT/scripts/fedora.sh"
source "$ROOT/scripts/user.sh"
echo "Setup complete. Log out/in for desktop changes; reboot after kernel/driver updates."

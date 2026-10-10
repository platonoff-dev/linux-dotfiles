die() { echo "Error: $*" >&2; exit 1; }
run() {
    printf '+ '; printf '%q ' "$@"; printf '\n'
    if ! $DRY_RUN; then "$@"; fi
}
fetch() { run curl --fail --location --retry 3 --proto '=https' --tlsv1.2 --output "$2" "$1"; }

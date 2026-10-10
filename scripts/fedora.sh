# Repository release RPMs own their configuration and signing keys.
if $RPMFUSION; then
    for kind in free nonfree; do
        if ! rpm -q "rpmfusion-$kind-release" >/dev/null 2>&1; then
            run sudo dnf install -y "https://mirrors.rpmfusion.org/$kind/fedora/rpmfusion-$kind-release-$VERSION_ID.noarch.rpm"
        fi
    done
fi
if $CHROME; then
    if ! cmp -s "$ROOT/repos/google-chrome.repo" /etc/yum.repos.d/google-chrome.repo; then
        run sudo install -m 0644 "$ROOT/repos/google-chrome.repo" /etc/yum.repos.d/google-chrome.repo
    fi
fi
if $UPDATE_SYSTEM; then run sudo dnf upgrade --refresh -y; fi
packages=(git curl unzip fontconfig)
if [[ $DESKTOP == kde ]]; then
    if ! rpm -q plasma-desktop >/dev/null 2>&1; then
        run sudo dnf install -y @kde-desktop-environment
    fi
    packages+=(konsole)
fi
if $CHROME; then packages+=(google-chrome-stable); fi
if $NVIDIA; then packages+=("$NVIDIA_PACKAGE" mokutil); fi
if $CODEX && ! command -v codex >/dev/null; then packages+=(nodejs npm); fi
packages+=("${EXTRA_PACKAGES[@]}")
run sudo dnf install -y "${packages[@]}"
if $NVIDIA; then
    run sudo akmods
    if ! $DRY_RUN && mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'; then
        echo "Secure Boot enabled: driver signing/enrollment may be required. See README."
    fi
fi

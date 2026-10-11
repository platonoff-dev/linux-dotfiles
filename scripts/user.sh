# User tools and fonts never run as root.
if $ZSH_SETUP; then source "$ROOT/scripts/zsh.sh"; fi
if $MODERN_TOOLS; then
    run git config --global --replace-all core.pager delta
    run git config --global --replace-all interactive.diffFilter 'delta --color-only'
fi
if $ZED && ! command -v zed >/dev/null; then
    if $DRY_RUN; then
        echo "+ Download https://zed.dev/install.sh and run as user (stable)"
    else
        installer=$(mktemp)
        trap 'rm -f -- "$installer"' EXIT
        fetch https://zed.dev/install.sh "$installer"
        run sh "$installer"
        rm -f -- "$installer"
        trap - EXIT
    fi
fi
if $NERD_FONT; then
    font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts/CaskaydiaCove"
    # Adopt an existing manual installation of this font on the first run.
    if [[ ! -f $font_dir/.version ]] && fc-match -f '%{family}' 'CaskaydiaCove Nerd Font Mono' | grep -q CaskaydiaCove; then
        echo "CaskaydiaCove already installed; keeping existing fonts."
    elif [[ ! -f $font_dir/.version ]] || [[ $(<"$font_dir/.version") != "$FONT_VERSION" ]]; then
        if $DRY_RUN; then
            echo "+ Install CascadiaCode.zip ($FONT_VERSION) into $font_dir"
        else
            temp=$(mktemp -d)
            trap 'rm -rf -- "$temp"' EXIT
            fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$FONT_VERSION/CascadiaCode.zip" "$temp/font.zip"
            unzip -q "$temp/font.zip" -d "$temp/font"
            run mkdir -p "$font_dir"
            find "$temp/font" -type f -name '*.ttf' -exec install -m 0644 '{}' "$font_dir/" \;
            printf '%s\n' "$FONT_VERSION" > "$font_dir/.version"
            run fc-cache -f "$font_dir"
            rm -rf -- "$temp"
            trap - EXIT
        fi
    fi
fi
if $CLAUDE && ! command -v claude >/dev/null; then
    if $DRY_RUN; then
        echo "+ Download https://claude.ai/install.sh and run as user ($CLAUDE_CHANNEL)"
    else
        installer=$(mktemp)
        trap 'rm -f -- "$installer"' EXIT
        fetch https://claude.ai/install.sh "$installer"
        run bash "$installer" "$CLAUDE_CHANNEL"
        rm -f -- "$installer"
        trap - EXIT
    fi
fi
if $CODEX && ! command -v codex >/dev/null; then
    run mkdir -p "$HOME/.local"
    run npm install --global --prefix "$HOME/.local" "@openai/codex@$CODEX_VERSION"
fi
if $GHOSTTY; then
    ghostty_dir="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
    ghostty_config="$ghostty_dir/config"
    # Prefer the newer filename when the user already uses it.
    [[ ! -f $ghostty_dir/config.ghostty ]] || ghostty_config="$ghostty_dir/config.ghostty"
    if $DRY_RUN; then
        echo "+ Configure $ghostty_config: command = /usr/bin/zsh; font-family = $GHOSTTY_FONT_FAMILY; font-size = $GHOSTTY_FONT_SIZE"
    else
        run mkdir -p "$ghostty_dir"
        temp=$(mktemp)
        trap 'rm -f -- "$temp"' EXIT
        if [[ -f $ghostty_config ]]; then
            awk '!/^[[:space:]]*(command|font-family|font-size)[[:space:]]*=/' "$ghostty_config" > "$temp"
        fi
        printf 'command = /usr/bin/zsh\nfont-family = %s\nfont-size = %s\n' \
            "$GHOSTTY_FONT_FAMILY" "$GHOSTTY_FONT_SIZE" >> "$temp"
        if ! cmp -s "$temp" "$ghostty_config"; then
            run install -m 0644 "$temp" "$ghostty_config"
        fi
        rm -f -- "$temp"
        trap - EXIT
    fi
fi
# Key-level changes preserve unrelated Plasma preferences.
if [[ $DESKTOP == kde ]] && $GHOSTTY; then
    if command -v kwriteconfig6 >/dev/null || $DRY_RUN; then
        run kwriteconfig6 --file kdeglobals --group General --key TerminalApplication ghostty
        run kwriteconfig6 --file kdeglobals --group General --key TerminalService com.mitchellh.ghostty.desktop
        # KGlobalAccel discovers application launchers in this directory at login.
        run mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/kglobalaccel"
        run install -m 0644 "$ROOT/config/com.mitchellh.ghostty.desktop" \
            "${XDG_DATA_HOME:-$HOME/.local/share}/kglobalaccel/com.mitchellh.ghostty.desktop"
        run kwriteconfig6 --file kglobalshortcutsrc --group com.mitchellh.ghostty.desktop \
            --key _launch 'Meta+Return,none,Ghostty'
    else
        die "kwriteconfig6 is missing after KDE installation"
    fi
fi
if [[ $DESKTOP == kde ]] && $NERD_FONT; then
    if command -v kwriteconfig6 >/dev/null || $DRY_RUN; then
        run kwriteconfig6 --file kdeglobals --group General --key fixed "$KDE_FIXED_FONT"
    else
        die "kwriteconfig6 is missing after KDE installation"
    fi
fi

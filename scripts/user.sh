# User tools and fonts never run as root.
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
# Key-level changes preserve unrelated Plasma preferences.
if [[ $DESKTOP == kde ]] && $NERD_FONT; then
    if command -v kwriteconfig6 >/dev/null || $DRY_RUN; then
        run kwriteconfig6 --file kdeglobals --group General --key fixed "$KDE_FIXED_FONT"
    else
        die "kwriteconfig6 is missing after KDE installation"
    fi
fi

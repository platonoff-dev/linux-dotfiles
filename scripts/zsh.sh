# Sourced as the desktop user, after zsh/git/curl are installed.
omz_dir="$HOME/.oh-my-zsh"
if [[ ! -f $omz_dir/oh-my-zsh.sh ]]; then
    [[ ! -e $omz_dir ]] || die "$omz_dir exists but is not a complete Oh My Zsh installation"
    run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
fi
if ! command -v starship >/dev/null; then
    if $DRY_RUN; then
        echo "+ Download https://starship.rs/install.sh and install into $HOME/.local/bin"
    else
        installer=$(mktemp)
        trap 'rm -f -- "$installer"' EXIT
        fetch https://starship.rs/install.sh "$installer"
        run mkdir -p "$HOME/.local/bin"
        run sh "$installer" --yes --bin-dir "$HOME/.local/bin"
        rm -f -- "$installer"
        trap - EXIT
    fi
fi
zshrc="${ZDOTDIR:-$HOME}/.zshrc"
if $DRY_RUN; then
    echo "+ Configure Oh My Zsh and Starship in $zshrc (preserve other settings)"
else
    run mkdir -p "$(dirname -- "$zshrc")"
    temp=$(mktemp)
    trap 'rm -f -- "$temp"' EXIT
    if [[ -f $zshrc ]]; then
        awk '
            /^# BEGIN linux-dotfiles zsh$/ { managed=1; next }
            /^# END linux-dotfiles zsh$/ { managed=0; next }
            /^# BEGIN linux-dotfiles tools$/ { managed=1; next }
            /^# END linux-dotfiles tools$/ { managed=0; next }
            !managed { print }
        ' "$zshrc" > "$temp"
    fi
    cat "$ROOT/config/zshrc" >> "$temp"
    if $MODERN_TOOLS; then cat "$ROOT/config/zsh-tools" >> "$temp"; fi
    if ! cmp -s "$temp" "$zshrc"; then
        if [[ -f $zshrc && ! -e $zshrc.pre-linux-dotfiles ]]; then
            run cp -p "$zshrc" "$zshrc.pre-linux-dotfiles"
        fi
        # Writing through an existing symlink preserves a user's dotfiles layout.
        cat "$temp" > "$zshrc"
    fi
    rm -f -- "$temp"
    trap - EXIT
fi

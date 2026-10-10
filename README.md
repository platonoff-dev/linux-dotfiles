# Linux dotfiles

A repeatable setup for desktops and laptops running mutable Fedora Linux, with KDE Plasma by default. Fedora KDE is the recommended starting image; Fedora Workstation is also supported and KDE is added when absent. Atomic desktops (Kinoite/Silverblue) and other distributions are rejected before changes.

Run from this directory as your normal desktop user:

```sh
./setup.sh
```

Sudo is requested for repositories, packages, upgrades and kernel module builds. User fonts, CLI tools and Plasma preferences are configured as your user. Preview with `./setup.sh --dry-run`; this prints planned commands without installing, downloading or writing anything. Internet access is required for a real run.

## Configuration

Edit `config/defaults.sh` for shared preferences. Copy `config/local.sh.example` to `config/local.sh` for private machine overrides, or run `./setup.sh --config /path/to/laptop.sh`. These files are trusted Bash code. A tracked machine profile can live under `config/` and be selected with `--config`.

Defaults:

- KDE Plasma; set `DESKTOP=none` to skip desktop installation/settings. Changing this does not remove an installed desktop or change the display manager/default session. Select Plasma at login on a Workstation install.
- RPM Fusion free/nonfree repositories, Google Chrome repository and stable browser.
- System upgrades on each run (`UPDATE_SYSTEM=false` to skip).
- NVIDIA detection by PCI vendor; only machines with NVIDIA hardware receive `akmod-nvidia`. Force with `NVIDIA=true` or disable with `NVIDIA=false`. `NVIDIA_PACKAGE` supports selecting a supported legacy driver package.
- CaskaydiaCove Nerd Font (CascadiaCode archive, pinned to v3.4.0) and KDE fixed-width font preference.
- Claude Code native stable installer and Codex via npm with a user-local prefix. Existing executable installations are preserved, including your standalone Codex installation. New installations use `~/.local/bin`; ensure this directory is on your shell PATH. Log into each tool separately after installation.
- Additional RPM packages via `EXTRA_PACKAGES=(zsh vim ripgrep)`.

Feature switches are `true`/`false`, except `NVIDIA=auto`. Disabling a feature skips it; it does not uninstall packages or delete repositories. Keep RPM Fusion enabled when managing NVIDIA.

## Repeat runs and recovery

DNF reconciles installed packages; repository release RPMs are installed only when missing. Chrome's tracked repository file is copied only when it differs. Existing Claude/Codex executables are skipped. Existing manually installed CaskaydiaCove fonts are adopted; fonts installed by this project record their version and are updated when `FONT_VERSION` changes. To migrate an adopted manual font to the pinned version, remove its existing installation first. Plasma updates only the fixed-font key, preserving other preferences. A lock prevents concurrent real runs by the same user.

System updates deliberately check for newer versions on every run, so repeatability means safe convergence rather than frozen package versions. If interrupted, fix the reported failure and rerun. No automated reboot is performed. Reboot after kernel/driver changes and log out/in to pick up desktop changes.

NVIDIA modules are built with `akmods` before completion. Secure Boot key enrollment requires firmware interaction and cannot be completed by a shell command alone. Follow [RPM Fusion Secure Boot](https://rpmfusion.org/Howto/Secure%20Boot) if Secure Boot is enabled. Older GPUs may require a legacy package; consult [RPM Fusion NVIDIA](https://rpmfusion.org/Howto/NVIDIA) before selecting one. The script does not disable Secure Boot or change bootloader settings.

## Previously completed setup

On the original Fedora 44 KDE machine, Google Chrome, RPM Fusion/NVIDIA repositories, `google-chrome-stable`, `akmod-nvidia`, CaskaydiaCove fonts, Claude Code and standalone Codex were already installed. These requirements are now represented by the defaults and scripts; no credentials or personal tool state are included. System updates are represented by the upgrade step. No system provisioning was executed while creating this repository.

## Validation

```sh
python3 -m unittest discover -s tests -v
for file in setup.sh scripts/*.sh config/*.sh; do bash -n "$file"; done
./setup.sh --dry-run
```

Tests use mocked system commands and a temporary home, including two consecutive setup runs. Real DNF operations and NVIDIA boot/module loading require testing on the target hardware.

Installation references: [RPM Fusion](https://rpmfusion.org/Configuration), [Google Linux repositories](https://www.google.com/linuxrepositories/), [Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases), [Claude Code setup](https://code.claude.com/docs/en/setup), [Codex CLI](https://learn.chatgpt.com/docs/codex/cli).

This is a local Git repository on `main`. Add your remote when ready with `git remote add origin <URL>` and push with `git push -u origin main`.

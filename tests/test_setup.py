import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class SetupTests(unittest.TestCase):
    def test_syntax(self):
        for path in [ROOT / 'setup.sh', *ROOT.glob('scripts/*.sh'), *ROOT.glob('config/*.sh')]:
            subprocess.run(['bash', '-n', str(path)], check=True)

    def test_repeat_and_preview(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)
            binaries = home / '.local/bin'
            binaries.mkdir(parents=True)
            log = home / 'commands'
            # Installed-state simulation: rpm succeeds; fc-match finds manual font.
            commands = {
                'sudo': 'printf "%s\\n" "$*" >> "$TEST_LOG"',
                'rpm': 'exit 0',
                'fc-match': 'echo "CaskaydiaCove Nerd Font Mono"',
                'claude': 'exit 0',
                'codex': 'exit 0',
                'zed': 'exit 0',
                'starship': 'exit 0',
                'kwriteconfig6': 'printf "%s\\n" "$*" >> "$TEST_LOG"',
                'curl': 'echo "Unexpected network request" >&2; exit 99',
                'npm': 'echo "Unexpected tool installation" >&2; exit 99',
            }
            for name, body in commands.items():
                path = binaries / name
                path.write_text('#!/usr/bin/env bash\n' + body + '\n')
                path.chmod(0o755)
            config = home / 'machine.sh'
            config.write_text('NVIDIA=false\n')
            omz = home / '.oh-my-zsh'
            omz.mkdir()
            (omz / 'oh-my-zsh.sh').write_text('')
            zshrc = home / '.zshrc'
            zshrc.write_text('export EDITOR=vim\nplugins=(git docker)\n')
            gitconfig = home / '.gitconfig'
            original_git = '[user]\n\tname = Test User\n[core]\n\tpager = less\n'
            gitconfig.write_text(original_git)
            ghostty = home / '.config/ghostty/config'
            ghostty.parent.mkdir(parents=True)
            original = 'theme = catppuccin-mocha\ncommand = /bin/bash\nfont-size = 14\n'
            ghostty.write_text(original)
            env = dict(os.environ, HOME=str(home), XDG_RUNTIME_DIR=str(home),
                       XDG_CONFIG_HOME=str(home / '.config'),
                       XDG_DATA_HOME=str(home / '.local/share'),
                       GIT_CONFIG_GLOBAL=str(gitconfig),
                       PATH=f'{binaries}:' + os.environ['PATH'], TEST_LOG=str(log))
            args = ['bash', str(ROOT / 'setup.sh'), '--config', str(config)]
            result = subprocess.run(args + ['--dry-run'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(log.exists(), 'Dry run executed a mutation')
            self.assertEqual(ghostty.read_text(), original)
            self.assertEqual(gitconfig.read_text(), original_git)
            self.assertFalse((home / '.zshrc.pre-linux-dotfiles').exists())
            previous = None
            for _ in range(2):
                result = subprocess.run(args, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
                current = ghostty.read_text()
                if previous is not None:
                    self.assertEqual(current, previous)
                previous = current
            self.assertEqual(ghostty.read_text(),
                             'theme = catppuccin-mocha\ncommand = /usr/bin/zsh\n'
                             'font-family = CaskaydiaCove Nerd Font Mono\nfont-size = 11\n')
            operations = log.read_text()
            self.assertEqual(operations.count('dnf upgrade --refresh -y'), 2)
            self.assertEqual(operations.count('--key fixed'), 2)
            self.assertNotIn('rpmfusion-free-release-', operations)
            self.assertNotIn('akmods', operations)
            self.assertIn('ghostty zsh', operations)
            self.assertIn('eza bat ripgrep fd-find fzf zoxide btop git-delta du-dust duf tealdeer', operations)
            for key, expected in [('user.name', 'Test User'), ('core.pager', 'delta'),
                                  ('interactive.diffFilter', 'delta --color-only')]:
                value = subprocess.check_output(['git', 'config', '--global', '--get', key],
                                                env=env, text=True).strip()
                self.assertEqual(value, expected)
            self.assertEqual(operations.count('--key TerminalApplication ghostty'), 2)
            self.assertEqual(operations.count('--key TerminalService com.mitchellh.ghostty.desktop'), 2)
            self.assertEqual(operations.count('--key _launch Meta+Return,none,Ghostty'), 2)
            self.assertTrue((home / '.local/share/kglobalaccel/com.mitchellh.ghostty.desktop').is_file())
            self.assertEqual(zshrc.read_text().count('# BEGIN linux-dotfiles zsh'), 1)
            self.assertTrue(zshrc.read_text().startswith('export EDITOR=vim\nplugins=(git docker)\n'))
            self.assertEqual((home / '.zshrc.pre-linux-dotfiles').read_text(),
                             'export EDITOR=vim\nplugins=(git docker)\n')
            subprocess.run(['zsh', '-n', str(zshrc)], check=True)
            self.assertEqual(zshrc.read_text().count('# BEGIN linux-dotfiles tools'), 1)
            config.write_text('NVIDIA=false\nMODERN_TOOLS=false\n')
            result = subprocess.run(args, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('# BEGIN linux-dotfiles tools', zshrc.read_text())
            self.assertTrue(zshrc.read_text().startswith('export EDITOR=vim\nplugins=(git docker)\n'))
            added_operations = log.read_text()[len(operations):]
            self.assertNotIn('eza', added_operations)

    def test_invalid_config_fails_before_mutations(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'invalid.sh'
            config.write_text('NVIDIA=true\nRPMFUSION=false\n')
            result = subprocess.run(['bash', str(ROOT / 'setup.sh'), '--dry-run',
                                     '--config', str(config)], capture_output=True, text=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('NVIDIA requires', result.stderr)
            self.assertNotIn('+ sudo', result.stdout)


if __name__ == '__main__':
    unittest.main()

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
            env = dict(os.environ, HOME=str(home), XDG_RUNTIME_DIR=str(home),
                       PATH=f'{binaries}:' + os.environ['PATH'], TEST_LOG=str(log))
            args = ['bash', str(ROOT / 'setup.sh'), '--config', str(config)]
            result = subprocess.run(args + ['--dry-run'], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(log.exists(), 'Dry run executed a mutation')
            for _ in range(2):
                result = subprocess.run(args, env=env, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
            operations = log.read_text()
            self.assertEqual(operations.count('dnf upgrade --refresh -y'), 2)
            self.assertEqual(operations.count('--key fixed'), 2)
            self.assertNotIn('rpmfusion-free-release-', operations)
            self.assertNotIn('akmods', operations)

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

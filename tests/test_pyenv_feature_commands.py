
import pytest


def pyenv_commands_help():
    return ("Usage: pyenv commands\n"
            "\n"
            "List all available pyenv commands")


def test_check_pyenv_commands_list(pyenv):
    stdout, stderr = pyenv.commands()
    assert stderr == ''
    commands = stdout.splitlines()
    for expected in ['commands', 'exec', 'global', 'help',
                     'install', 'latest', 'local', 'prefix', 'rehash',
                     'root', 'shell', 'shims', 'uninstall', 'update', 'version',
                     'versions', 'whence', 'which']:
        assert expected in commands, f"Command '{expected}' not found in commands output"


def test_check_pyenv_commands_help(pyenv):
    assert pyenv.commands("--help") == (pyenv_commands_help(), "")
    assert pyenv("--help", "commands") == (pyenv_commands_help(), "")
    assert pyenv("help", "commands") == (pyenv_commands_help(), "")

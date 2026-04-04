import pytest


def test_update_help(pyenv):
    for args in [
        ["--help", "update"],
        ["help", "update"],
        ["update", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        assert 'Usage: pyenv update' in stdout
        assert stderr == ''

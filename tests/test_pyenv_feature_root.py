import os

import pytest

S = os.sep


def pyenv_root_help():
    return "Usage: pyenv root"


def test_root_help(pyenv):
    for args in [
        ["--help", "root"],
        ["help", "root"],
        ["root", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        assert ("\n".join(stdout.splitlines()[:2]).strip(), stderr) == (pyenv_root_help(), "")


def test_root_returns_pyenv_parent(tmp_path, pyenv):
    stdout, stderr = pyenv.root()
    # PyenvRoot = Split-Path PyenvHome -Parent; PyenvHome = pyenv_path = tmp_path/'pyenv dir with spaces'
    assert stderr == ""
    assert stdout == str(tmp_path)

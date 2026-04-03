
import os
import pytest

from test_pyenv_helpers import Native
from pathlib import Path


def pyenv_duplicate_help():
    return ("Usage: pyenv duplicate <available_environment> <new_environment>\n"
            "\n"
            "Duplicate your environment.\n"
            "\n"
            "ex.) pyenv duplicate 3.5.3 myapp_env\n"
            "\n"
            "To use when you want to create a sandbox and\n"
            "the environment when building application-specific environment.")


def test_check_pyenv_duplicate_help(pyenv):
    assert pyenv.duplicate("--help") == (pyenv_duplicate_help(), "")
    assert pyenv("--help", "duplicate") == (pyenv_duplicate_help(), "")
    assert pyenv("help", "duplicate") == (pyenv_duplicate_help(), "")


def test_check_pyenv_duplicate_no_args(pyenv):
    stdout, stderr = pyenv.duplicate()
    assert 'Usage: pyenv duplicate' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_check_pyenv_duplicate(pyenv, pyenv_path):
    stdout, stderr = pyenv.duplicate(Native('3.8.9'), 'myapp_env')
    assert stderr == ''
    assert stdout == ''
    dst = Path(pyenv_path, 'versions', 'myapp_env')
    assert dst.exists()
    assert dst.joinpath('python.exe').exists()


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_check_pyenv_duplicate_src_not_found(pyenv):
    stdout, stderr = pyenv.duplicate('3.99.0', 'myapp_env')
    assert '3.99.0 does not exist' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_check_pyenv_duplicate_dst_exists(pyenv):
    stdout, stderr = pyenv.duplicate(Native('3.8.9'), Native('3.8.9'))
    assert 'already exists' in stdout

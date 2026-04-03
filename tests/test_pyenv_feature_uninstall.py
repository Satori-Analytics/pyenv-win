import pytest

from test_pyenv_helpers import Native
from pathlib import Path


def test_uninstall_help(pyenv):
    for args in [
        ["--help", "uninstall"],
        ["help", "uninstall"],
        ["uninstall", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        assert 'Usage: pyenv uninstall' in stdout
        assert stderr == ''


def test_uninstall_no_args(pyenv):
    stdout, stderr = pyenv.uninstall()
    assert 'Usage: pyenv uninstall' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9'), Native('3.9.1')],
    'global_ver': Native('3.8.9'),
}])
def test_uninstall_version(pyenv, pyenv_path):
    version_path = Path(pyenv_path, 'versions', Native('3.9.1'))
    assert version_path.exists()
    stdout, stderr = pyenv.uninstall('-f', Native('3.9.1'))
    assert stderr == ''
    assert not version_path.exists()


def test_uninstall_no_versions_installed(pyenv):
    stdout, stderr = pyenv.uninstall('-f', '3.99.0')
    assert 'No valid versions' in stdout or 'not installed' in stdout.lower()


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_uninstall_nonexistent_version(pyenv):
    stdout, stderr = pyenv.uninstall('-f', '3.99.0')
    # When versions exist but the target version doesn't, force flag silences error
    assert stderr == ''

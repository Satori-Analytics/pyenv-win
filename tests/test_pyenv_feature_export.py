import os
import pytest

from test_pyenv_helpers import Native
from pathlib import Path


def pyenv_export_help():
    return (f"Usage: pyenv export <available_environment> <destination>\r\n"
            f"\r\n"
            f"Export your environment.\r\n"
            f"\r\n"
            f"ex.) pyenv export 3.5.3 ./vendor/python\r\n"
            f"\r\n"
            f"To use when you want to build application-specific environment.")


def test_export_help(pyenv):
    assert pyenv.export("--help") == (pyenv_export_help(), "")
    assert pyenv("--help", "export") == (pyenv_export_help(), "")
    assert pyenv("help", "export") == (pyenv_export_help(), "")


def test_export_no_args(pyenv):
    stdout, stderr = pyenv.export()
    assert 'Usage: pyenv export' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_export(pyenv, pyenv_path, tmp_path):
    dst = tmp_path / 'exported_python'
    stdout, stderr = pyenv.export(Native('3.8.9'), str(dst))
    assert stderr == ''
    assert stdout == ''
    assert dst.exists()
    assert dst.joinpath('python.exe').exists()


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_export_src_not_found(pyenv):
    stdout, stderr = pyenv.export('3.99.0', './somewhere')
    assert '3.99.0 does not exist' in stdout

import os

import pytest
from test_pyenv_helpers import Native

S = os.sep


def pyenv_prefix_help():
    return "Usage: pyenv prefix [<version>...]"


def test_prefix_help(pyenv):
    for args in [
        ["--help", "prefix"],
        ["help", "prefix"],
        ["prefix", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        assert ("\n".join(stdout.splitlines()[:2]).strip(), stderr) == (
            pyenv_prefix_help(),
            "",
        )


def test_prefix_no_version_set(pyenv):
    stdout, stderr = pyenv.prefix()
    assert stdout == "pyenv: no version set"
    assert stderr == ""


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.8.5")],
            "global_ver": Native("3.8.5"),
        }
    ],
)
def test_prefix_global_version(pyenv_path, pyenv):
    stdout, stderr = pyenv.prefix()
    assert stderr == ""
    assert stdout == f"{pyenv_path}{S}versions{S}{Native('3.8.5')}"


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.9.1")],
            "local_ver": Native("3.9.1"),
        }
    ],
)
def test_prefix_local_version(pyenv_path, pyenv):
    stdout, stderr = pyenv.prefix()
    assert stderr == ""
    assert stdout == f"{pyenv_path}{S}versions{S}{Native('3.9.1')}"


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.10.2")],
        }
    ],
)
def test_prefix_shell_version(pyenv_path, pyenv):
    env = {"PYENV_VERSION": Native("3.10.2")}
    stdout, stderr = pyenv.prefix(env=env)
    assert stderr == ""
    assert stdout == f"{pyenv_path}{S}versions{S}{Native('3.10.2')}"


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.8.5")],
            "global_ver": Native("3.8.5"),
        }
    ],
)
def test_prefix_explicit_version(pyenv_path, pyenv):
    stdout, stderr = pyenv.prefix(Native("3.8.5"))
    assert stderr == ""
    assert stdout == f"{pyenv_path}{S}versions{S}{Native('3.8.5')}"


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.8.5"), Native("3.9.1")],
            "global_ver": Native("3.8.5"),
        }
    ],
)
def test_prefix_multiple_versions(pyenv_path, pyenv):
    stdout, stderr = pyenv.prefix(Native("3.8.5"), Native("3.9.1"))
    assert stderr == ""
    expected = f"{pyenv_path}{S}versions{S}{Native('3.8.5')};{pyenv_path}{S}versions{S}{Native('3.9.1')}"
    assert stdout == expected


def test_prefix_version_not_installed(pyenv):
    stdout, stderr = pyenv.prefix("3.99.0")
    assert "not installed" in stdout
    assert stderr == ""


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.8.5")],
            "global_ver": Native("3.8.5"),
        }
    ],
)
def test_prefix_one_installed_one_not(pyenv):
    stdout, stderr = pyenv.prefix(Native("3.8.5"), "3.99.0")
    assert "not installed" in stdout
    assert stderr == ""

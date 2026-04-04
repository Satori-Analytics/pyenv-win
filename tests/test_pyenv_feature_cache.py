import pytest
from test_pyenv_helpers import Native


def test_cache_empty(pyenv):
    stdout, stderr = pyenv.cache()
    assert stdout == "No cached installers."
    assert stderr == ""


def test_cache_help(pyenv):
    stdout, stderr = pyenv.cache("--help")
    assert "Usage: pyenv cache" in stdout
    assert "--clear" in stdout
    assert "--sync" in stdout
    assert stderr == ""


def test_cache_unrecognized_option(pyenv):
    stdout, stderr = pyenv.cache("--invalid")
    assert "unrecognized option" in stdout
    assert stderr == ""


def test_cache_mutually_exclusive(pyenv):
    stdout, stderr = pyenv.cache("--clear", "--sync")
    assert "mutually exclusive" in stdout
    assert stderr == ""


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.10.11"), Native("3.11.9")],
            "cache": ["3.10.11", "3.11.9", "3.12.4"],
        }
    ],
)
def test_cache_list(settings, pyenv):
    stdout, stderr = pyenv.cache()
    assert "3.10.11" in stdout
    assert "3.11.9" in stdout
    assert "3.12.4" in stdout
    assert stderr == ""


@pytest.mark.parametrize("settings", [lambda: {"cache": ["3.10.11", "3.12.4"]}])
def test_cache_clear(settings, pyenv, pyenv_path):
    cache_dir = pyenv_path / "install_cache"
    assert cache_dir.exists()

    stdout, stderr = pyenv.cache("--clear")
    assert stdout == "Cache cleared."
    assert stderr == ""
    assert not cache_dir.exists()


@pytest.mark.parametrize("settings", [lambda: {"cache": ["3.10.11", "3.12.4"]}])
def test_cache_clear_then_list(settings, pyenv, pyenv_path):
    pyenv.cache("--clear")
    stdout, stderr = pyenv.cache()
    assert stdout == "No cached installers."
    assert stderr == ""


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.10.11")],
            "cache": ["3.10.11", "3.11.9", "3.12.4"],
        }
    ],
)
def test_cache_sync(settings, pyenv, pyenv_path):
    stdout, stderr = pyenv.cache("--sync")
    assert "Removed 2 cached version(s)" in stdout
    assert stderr == ""

    cache_dir = pyenv_path / "install_cache"
    remaining = [d.name for d in cache_dir.iterdir() if d.is_dir()]
    assert "3.10.11" in remaining
    assert "3.11.9" not in remaining
    assert "3.12.4" not in remaining


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [Native("3.10.11"), Native("3.11.9")],
            "cache": ["3.10.11", "3.11.9"],
        }
    ],
)
def test_cache_sync_already_in_sync(settings, pyenv):
    stdout, stderr = pyenv.cache("--sync")
    assert "already in sync" in stdout
    assert stderr == ""

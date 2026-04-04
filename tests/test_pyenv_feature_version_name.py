import pytest

from test_pyenv_helpers import Native


def test_version_name_help(pyenv):
    for args in [
        ["--help", "version-name"],
        ["help", "version-name"],
        ["version-name", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        stdout = "\n".join(stdout.splitlines()[:2]).strip()
        assert (stdout, stderr) == ("Usage: pyenv version-name", "")


def test_no_version(pyenv):
    assert pyenv('version-name') == (
        (
            "No global/local python version has been set yet. "
            "Please set the global/local version by typing:\n"
            "pyenv global <python-version>\n"
            "pyenv global 3.8.4\n"
            "pyenv local <python-version>\n"
            "pyenv local 3.8.4"
        ),
        ""
    )


@pytest.mark.parametrize("settings", [lambda: {'global_ver': Native("3.8.4")}])
def test_global_version(pyenv):
    assert pyenv('version-name') == (Native("3.8.4"), "")


@pytest.mark.parametrize("settings", [lambda: {
        'global_ver': Native("3.8.4"),
        'local_ver': Native("3.9.1")
    }])
def test_one_local_version(pyenv):
    assert pyenv('version-name') == (Native("3.9.1"), "")


@pytest.mark.parametrize('settings', [lambda: {
        'global_ver': Native("3.8.3"),
        'local_ver': Native("3.8.6"),
    }])
def test_shell_version(pyenv):
    env = {"PYENV_VERSION": Native("3.9.2")}
    assert pyenv('version-name', env=env) == (Native("3.9.2"), "")


@pytest.mark.parametrize('settings', [lambda: {
        'global_ver': Native("3.8.4"),
        'local_ver': [Native("3.8.8"), Native("3.9.1")]
    }])
def test_many_local_versions(pyenv):
    assert pyenv('version-name') == ("\n".join([Native("3.8.8"), Native("3.9.1")]), "")

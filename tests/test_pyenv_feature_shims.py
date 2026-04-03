import pytest

from test_pyenv_helpers import Native


def pyenv_shims_help():
    return (f"Usage: pyenv shims [--short]\r\n"
            f"\r\n"
            f"List existing pyenv shims")


def test_shims_help(pyenv):
    assert pyenv.shims("--help") == (pyenv_shims_help(), "")
    assert pyenv("--help", "shims") == (pyenv_shims_help(), "")
    assert pyenv("help", "shims") == (pyenv_shims_help(), "")


def test_shims_empty(pyenv):
    stdout, stderr = pyenv.shims()
    assert stderr == ''
    assert stdout == ''


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
    'global_ver': Native('3.8.9'),
}])
def test_shims_after_rehash(pyenv):
    pyenv.rehash()
    stdout, stderr = pyenv.shims("--short")
    assert stderr == ''
    assert stdout != ''
    shim_names = stdout.splitlines()
    # After rehash, there should be shims for python executables
    assert any('python' in s for s in shim_names)

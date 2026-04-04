import pytest

from test_pyenv_helpers import Native


def pyenv_whence_usage():
    return ("Usage: pyenv whence [--path] <command>\n"
            "\n"
            "Shows the currently given executable contains path\n"
            "selected. To obtain python version of executable, use `pyenv whence pip'.")


@pytest.mark.parametrize('settings', [lambda: {'versions': [Native('3.8.1')]}])
def test_whence_no_arg(pyenv):
    assert pyenv.whence() == (pyenv_whence_usage(), "")
    assert pyenv.whence("--help") == (pyenv_whence_usage(), "")
    assert pyenv("--help", "whence") == (pyenv_whence_usage(), "")
    assert pyenv("help", "whence") == (pyenv_whence_usage(), "")


@pytest.mark.parametrize('settings',
                         [lambda: {'versions': [Native('3.8.1'), Native('3.8.2'), Native('3.8.7'), Native('3.9.1')]}])
def test_whence_major(pyenv):
    for name in ['python', 'python3', 'pip3']:
        assert pyenv.whence(name) == ("\n".join([Native('3.8.1'), Native('3.8.2'), Native('3.8.7'), Native('3.9.1')]), "")


@pytest.mark.parametrize('settings',
                         [lambda: {'versions': [Native('3.8.1'), Native('3.8.2'), Native('3.8.7'), Native('3.9.1')]}])
def test_whence_major_minor(pyenv):
    for name in ['python38', 'python3.8', 'pip3.8']:
        assert pyenv.whence(name) == ("\n".join([Native('3.8.1'), Native('3.8.2'), Native('3.8.7')]), "")


@pytest.mark.parametrize('settings',
                         [lambda: {'versions': [Native('3.8.1'), Native('3.8.2'), Native('3.8.7'), Native('3.9.1')]}])
def test_whence_not_found(pyenv):
    for name in ['unknown3.8']:
        assert pyenv.whence(name) == ("", "")

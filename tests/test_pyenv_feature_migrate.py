import pytest

from test_pyenv_helpers import Native


def pyenv_migrate_help():
    return ("Usage: pyenv migrate <from> <to>\n"
            "   ex. pyenv migrate 3.8.10 3.11.4\n"
            "\n"
            "Migrate pip packages from a Python version to another.")


def test_migrate_help(pyenv):
    assert pyenv.migrate("--help") == (pyenv_migrate_help(), "")
    assert pyenv("--help", "migrate") == (pyenv_migrate_help(), "")
    assert pyenv("help", "migrate") == (pyenv_migrate_help(), "")


def test_migrate_no_args(pyenv):
    stdout, stderr = pyenv.migrate()
    assert 'Usage: pyenv migrate' in stdout


def test_migrate_one_arg(pyenv):
    stdout, stderr = pyenv.migrate('3.8.10')
    assert 'Usage: pyenv migrate' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_migrate_src_not_found(pyenv):
    stdout, stderr = pyenv.migrate('3.99.0', Native('3.8.9'))
    assert 'does not exist' in stdout


@pytest.mark.parametrize('settings', [lambda: {
    'versions': [Native('3.8.9')],
}])
def test_migrate_dst_not_found(pyenv):
    stdout, stderr = pyenv.migrate(Native('3.8.9'), '3.99.0')
    assert 'does not exist' in stdout

def test_check_pyenv_path(bin_path, run):
    assert bin_path.exists() is True
    import os

    assert str(bin_path) in os.environ["PATH"]


def test_check_pyenv_version(src_path, pyenv):
    ver_path = str(src_path / ".version")
    version = open(ver_path).read().strip()
    stdout, stderr = pyenv()
    assert version in stdout


def test_check_pyenv_features_list(pyenv):
    result, stderr = pyenv()
    assert stderr == ""
    assert "commands" in result
    assert "local" in result
    assert "global" in result
    assert "shell" in result
    assert "install" in result
    assert "uninstall" in result
    assert "rehash" in result
    assert "version" in result
    assert "versions" in result
    assert "exec" in result
    assert "which" in result
    assert "whence" in result


def test_check_pyenv_help(pyenv):
    stdout, stderr = pyenv()
    assert stderr == ""
    assert "Usage: pyenv <command> [<args>]" in stdout
    assert "Some useful pyenv commands are:" in stdout
    assert "install" in stdout
    assert "See 'pyenv help <command>'" in stdout

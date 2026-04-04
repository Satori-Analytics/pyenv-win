import pytest

import shutil
from pathlib import Path
from test_pyenv_helpers import not_installed_output, Native, Arch


@pytest.fixture(scope="module", params=["pwsh"])
def shell(request):
    shell = request.param
    if shutil.which(shell) is None:
        pytest.skip(f"the shell '{shell}' was not found")
    return shell


def pyenv_shell_help():
    return ("Usage: pyenv shell <version>\n"
            "       pyenv shell --unset")


def test_shell_help(pyenv):
    for args in [
        ["--help", "shell"],
        ["help", "shell"],
        ["shell", "--help"],
    ]:
        stdout, stderr = pyenv(*args)
        assert ("\n".join(stdout.splitlines()[:2]), stderr) == (pyenv_shell_help(), "")


def test_no_shell_version(pyenv):
    env = {"PYENV_VERSION": ""}
    assert pyenv.shell(env=env) == ("no shell-specific version configured", "")


def test_shell_version_defined(pyenv):
    env = {"PYENV_VERSION": Native("3.9.2")}
    assert pyenv.shell(env=env) == (Native("3.9.2"), "")


@pytest.mark.parametrize('settings', [lambda: {'versions': [Native("3.9.7"), Native("3.10.9")]}])
def test_shell_set_installed_version(local_path, pyenv_file, shell, shell_ext, run):
    env = {"PYENV_VERSION": Native("3.10.9")}
    tmp_bat = str(Path(local_path, "tmp" + shell_ext))
    with open(tmp_bat, "w") as f:
        print(f'& "{pyenv_file}" shell {Arch("3.9.7")}; & "{pyenv_file}" shell', file=f)
    stdout, stderr = run(tmp_bat, env=env)
    assert (stdout, stderr) == (Native("3.9.7"), "")


@pytest.mark.parametrize('settings', [lambda: {'versions': [Native("3.10.9")]}])
def test_shell_set_unknown_version(pyenv):
    assert pyenv.shell(Native("3.9.8")) == (not_installed_output(Native("3.9.8")), "")


@pytest.mark.parametrize('settings', [lambda: {
        'versions': [Native("3.9.7"), Native("3.10.9")],
        'global_ver': Native("3.9.7"),
        'local_ver': Native("3.9.7"),
    }])
def test_shell_unset_unaffected(local_path, pyenv_file, shell, shell_ext, run):
    env = {"PYENV_VERSION": Native("3.10.9")}
    tmp_bat = str(Path(local_path, "tmp" + shell_ext))
    with open(tmp_bat, "w") as f:
        print(f'& "{pyenv_file}" global --unset; & "{pyenv_file}" local --unset; & "{pyenv_file}" shell', file=f)
    stdout, stderr = run(tmp_bat, env=env)
    assert (stdout, stderr) == (Native("3.10.9"), "")


@pytest.mark.parametrize('settings', [lambda: {'versions': [Native("3.9.7"), Native("3.10.9")]}])
def test_shell_set_many_versions(local_path, pyenv_file, shell, shell_ext, run):
    tmp_bat = str(Path(local_path, "tmp" + shell_ext))
    with open(tmp_bat, "w") as f:
        print(f'& "{pyenv_file}" shell {Arch("3.9.7")} {Arch("3.10.9")}; & "{pyenv_file}" shell', file=f)
    stdout, stderr = run(tmp_bat)
    assert (stdout, stderr) == (" ".join([Native('3.9.7'), Native('3.10.9')]), "")


@pytest.mark.parametrize('settings', [lambda: {'versions': [Native("3.9.7")]}])
def test_shell_set_many_versions_one_not_installed(pyenv):
    assert pyenv.shell(Arch("3.9.7"), Arch("3.10.9")) == (not_installed_output(Native("3.10.9")), "")


def test_shell_many_versions_defined(pyenv):
    env = {'PYENV_VERSION': " ".join([Native('3.9.7'), Native('3.10.9')])}
    assert pyenv.shell(env=env) == (" ".join([Native('3.9.7'), Native('3.10.9')]), "")

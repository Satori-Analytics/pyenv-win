import os
import subprocess
import sys
import pytest
from pathlib import Path
from tempenv import TemporaryEnvironment

from test_pyenv_helpers import Native

S = os.sep
P = os.pathsep


@pytest.fixture()
def settings():
    return lambda: {
        'versions': [Native('3.9.7'), Native('3.10.9'), Native('3.10.0')],
        'global_ver': Native('3.9.7'),
        'local_ver': [Native('3.9.7'), Native('3.10.9')]
    }


@pytest.fixture()
def env(pyenv_path):
    env = {"PATH": f"{os.path.dirname(sys.executable)}{P}" \
                     f"{str(Path(pyenv_path, 'bin'))}{P}" \
                     f"{str(Path(pyenv_path, 'shims'))}{P}" \
                     f"{os.environ['PATH']}"}
    environment = TemporaryEnvironment(env)
    with environment:
        yield env


@pytest.fixture(autouse=True)
def remove_python_exe(pyenv, pyenv_path, settings):
    """
    We do not have any python version installed.
    But we prepend the path with sys.executable dir.
    And we remote fake python.exe (empty file generated) to ensure sys.executable is found and used.
    This method allows us to execute python.exe.
    But it cannot be used to play with many python versions.
    """
    pyenv.rehash()
    for v in settings()['versions']:
        os.unlink(str(pyenv_path / 'versions' / v / 'python.exe'))


@pytest.mark.parametrize(
    "command",
    [
        lambda path: [str(path / "bin" / "pyenv.ps1"), "exec", "python"],
    ],
    ids=["pyenv exec"],
)
@pytest.mark.parametrize(
    "arg",
    [
        "Hello",
        "Hello World",
        "Hello 'World'",
        'Hello "World"',  # " is escaped as \" by python
        "Hello %World%",
        # "Hello %22World%22",
        "Hello !World!",
        "Hello #World#",
        "Hello World'",
        'Hello World"',
        "Hello ''World'",
        'Hello ""World"',
    ],
    ids=[
        "One Word",
        "Two Words",
        "Single Quote",
        "Double Quote",
        "Percentage",
        # "Escaped",
        "Exclamation Mark",
        "Pound",
        "One Single Quote",
        "One Double Quote",
        "Imbalance Single Quote",
        "Imbalance Double Quote",
    ]
)
def test_exec_arg(command, arg, env, pyenv_path, run):
    env['World'] = 'Earth'
    stdout, stderr = run(
        *command(pyenv_path),
        "-c",
        "import sys; print(sys.argv[1])",
        arg,
        env=env
    )
    assert (stdout, stderr) == (arg, "")


@pytest.mark.parametrize(
    "args",
    [
        ["--help", "exec"],
        ["help", "exec"],
        ["exec", "--help"],
    ],
    ids=[
        "--help exec",
        "help exec",
        "exec --help",
    ]
)
def test_exec_help(args, env, pyenv):
    stdout, stderr = pyenv(*args, env=env)
    assert ("\n".join(stdout.splitlines()[:1]), stderr) == (pyenv_exec_help(), "")


def test_path_not_updated(pyenv_path, local_path, env, run):
    pyenv_ps1 = str(pyenv_path / "bin" / "pyenv.ps1")
    tmp_ps1 = str(Path(local_path, "tmp.ps1"))
    with open(tmp_ps1, "w") as f:
        print('$env:PATH', file=f)
        print(f'& "{pyenv_ps1}" exec python -V 2>$null | Out-Null', file=f)
        print('$env:PATH', file=f)
    stdout, stderr = run(tmp_ps1, env=env)
    lines = stdout.strip().split("\n")
    assert stderr == ""
    assert len(lines) == 2
    assert lines[0] == lines[1]


def test_many_paths(pyenv_path, env, pyenv):
    stdout, stderr = pyenv.exec('python', '-c', "import os; print(os.environ['PATH'])", env=env)
    assert stderr == ""
    assert stdout.startswith(
        (
            f"{pyenv_path}{S}versions{S}{Native('3.9.7')}{P}"
            f"{pyenv_path}{S}versions{S}{Native('3.9.7')}{S}Scripts{P}"
            f"{pyenv_path}{S}versions{S}{Native('3.10.9')}{P}"
            f"{pyenv_path}{S}versions{S}{Native('3.10.9')}{S}Scripts{P}"
        )
    )
    assert pyenv.exec('version.bat') == ("3.9.7", "")


@pytest.mark.parametrize('settings', [lambda: {
        'versions': [],
        'local_ver': Native('3.8.5')
    }])
def test_exec_local_not_installed(pyenv):
    with pytest.raises(subprocess.CalledProcessError) as e:
        pyenv.exec('python', check=True)
    assert e.value.returncode == 1


def test_bat_shim(pyenv):
    assert pyenv.exec('hello') == ("Hello world!", "")


def test_removes_shims_from_path(pyenv):
    stdout, stderr = pyenv.exec('python310')
    assert stdout == ''
    assert 'python310' in stderr


def pyenv_exec_help():
    return "Usage: pyenv exec <command> [arg1 arg2...]"

import pytest
from test_pyenv_helpers import Arch, Native


def test_latest_help(pyenv):
    assert pyenv("latest")

    result, stderr = pyenv("latest")

    assert "Usage:" in result
    assert "--known" in result
    assert "--quiet" in result


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [
                Native("3.8.4"),
                Native("3.11.0"),
                Native("3.9.0"),
                Native("3.9.5"),
                Native("3.9.1"),
            ]
        }
    ],
)
def test_latest_edge_cases(pyenv):
    assert pyenv.latest("1") == (
        "pyenv-latest: no installed versions match the prefix '1'.",
        "",
    )
    assert pyenv.latest("-k", "1") == (
        "pyenv-latest: no known versions match the prefix '1'.",
        "",
    )
    assert pyenv.latest("-k", "3.9.16") == (
        "pyenv-latest: no known versions match the prefix '3.9.16'.",
        "",
    )
    assert pyenv.latest("3.8") == (Native("3.8.4"), "")
    assert pyenv.latest("3.9") == (Native("3.9.5"), "")
    assert pyenv.latest("3.9.5") == (Native("3.9.5"), "")


@pytest.mark.parametrize(
    "settings", [lambda: {"versions": [Native("3.8.0"), Arch("3.8.4")]}]
)
def test_latest_arch_cases(pyenv):
    assert pyenv.latest("3.8") == (Native("3.8.4"), "")


def test_latest_quiet(pyenv):
    assert pyenv.latest("-q") == ("", "")
    assert pyenv.latest("-q", "-k") == ("", "")
    assert pyenv.latest("-k", "-q") == ("", "")
    assert pyenv.latest("-q", "-k", "1.") == ("", "")
    assert pyenv.latest("-q", "-k", "www") == ("", "")


@pytest.mark.parametrize(
    "settings",
    [
        lambda: {
            "versions": [
                Native("3.9.4"),
                Native("3.8.2"),
                Native("3.8.7"),
                Native("3.9.1"),
            ]
        }
    ],
)
def test_latest_sort(pyenv):
    assert pyenv.latest("3") == (Native("3.9.4"), "")
    assert pyenv.latest("3.8") == (Native("3.8.7"), "")

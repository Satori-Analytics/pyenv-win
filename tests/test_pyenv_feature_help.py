

def test_help(pyenv):
    stdout, stderr = pyenv.help()
    lines = stdout.strip().splitlines()
    assert stderr == ""
    assert lines[0].startswith("pyenv ")
    assert lines[1] == "Usage: pyenv <command> [<args>]"

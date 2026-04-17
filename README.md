# pyenv for Windows 4.0+ (PowerShell rewrite)

[pyenv][1] is an amazing tool used to manage multiple versions of python in your machine. Originally ported to Windows by [Kiran Kumar Kotari](https://github.com/kirankotari), this fork rewrites pyenv-win entirely in PowerShell 7 for modern Windows compatibility.

[![Pester](https://github.com/satori-analytics/pyenv-win/actions/workflows/pester.yml/badge.svg)](https://github.com/satori-analytics/pyenv-win/actions/workflows/pester.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub issues open](https://img.shields.io/github/issues/satori-analytics/pyenv-win.svg?)](https://github.com/satori-analytics/pyenv-win/issues)
[![GitHub pull requests open](https://img.shields.io/github/issues-pr/satori-analytics/pyenv-win.svg?)](https://github.com/satori-analytics/pyenv-win/pulls)

- [pyenv for Windows 4.0+ (PowerShell rewrite)](#pyenv-for-windows-40-powershell-rewrite)
  - [Introduction](#introduction)
  - [pyenv](#pyenv)
  - [Quick start](#quick-start)
  - [Commands](#commands)
  - [Installation](#installation)
  - [Validate installation](#validate-installation)
    - [Manually check the settings](#manually-check-the-settings)
  - [Usage](#usage)
  - [Tab Completion](#tab-completion)
  - [How to update pyenv](#how-to-update-pyenv)
  - [FAQ](#faq)
  - [Changelog](#changelog)
  - [How to contribute](#how-to-contribute)
  - [Bug Tracker and Support](#bug-tracker-and-support)
  - [License and Copyright](#license-and-copyright)
  - [Author and Thanks](#author-and-thanks)

## Introduction

[pyenv][1] for python is a great tool but, like [rbenv][2] for ruby developers, it doesn't directly support Windows. After a bit of research and feedback from python developers, I discovered they wanted a similar feature for Windows systems.

This project was forked from [rbenv-win][3] and modified for [pyenv][1]. Version 4.0 is a complete rewrite of the original [pyenv-win][4]. All legacy VBScript and Batch files have been replaced with PowerShell 7 scripts.

## pyenv

[pyenv][1] is a simple python version management tool. It lets you easily switch between multiple versions of Python. It's simple, unobtrusive, and follows the UNIX tradition of single-purpose tools that do one thing well.

## Quick start

> **Prerequisite:** [PowerShell 7+](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) must be installed. Run `pwsh --version` to verify.

1. Install pyenv-win in PowerShell:

   ```pwsh
   irm https://raw.githubusercontent.com/satori-analytics/pyenv-win/master/pyenv-win/install.ps1 | iex
   ```

2. Reopen PowerShell
3. Run `pyenv --version` to check if the installation was successful.
4. Run `pyenv install -l` to check a list of Python versions supported by pyenv-win
5. Run `pyenv install <version>` to install the supported version
6. Run `pyenv global <version>` to set a Python version as the global version
7. Check which Python version you are using and its path:

   ```plaintext
   > pyenv version
   <version> (set by \path\to\.pyenv\pyenv-win\version)
   ```

8. Check that Python is working:

   ```plaintext
   > python -c "import sys; print(sys.executable)"
   \path\to\.pyenv\pyenv-win\versions\<version>\python.exe
   ```

## Commands

```yml
commands     List all available pyenv commands
local        Set or show the local application-specific Python version
latest       Print the latest installed or known version with the given prefix
global       Set or show the global Python version
shell        Set or show the shell-specific Python version
install      Install 1 or more versions of Python
uninstall    Uninstall a specific Python version
update       Update the cached version DB from the repository
upgrade      Update pyenv-win itself to the latest version
rehash       Rehash pyenv shims (run this after installing executables)
cache        List, clear, or sync the installer cache
root         Display the root directory where versions and shims are kept
prefix       Display the directory where a Python version is installed
version      Show the current Python version and its origin
versions     List all Python versions available to pyenv
exec         Runs an executable by first preparing PATH so that the selected
             Python version's directory is at the front
which        Display the full path to an executable
whence       List all Python versions that contain the given executable
completions  List available completions for a given command
```

## Installation

Currently we support the following ways, choose any of your comfort:

- [PowerShell](docs/installation.md#powershell) - default and easiest way
- [Pyenv-win zip](docs/installation.md#pyenv-win-zip) - manual installation
- [Git Commands](docs/installation.md#git-commands) - adding manual settings

Please see the [Installation](./docs/installation.md) page for more details.

## Validate installation

1. Reopen PowerShell and run `pyenv --version`
2. Now type `pyenv` to view its usage

If you are getting "**command not found**" error, check the note below and [manually check the settings](#manually-check-the-settings).

For Visual Studio Code or another IDE with a built in terminal, restart it and check again.

---

### Manually check the settings

The environment variables to be set:

```plaintext
C:\Users\<replace with your actual username>\.pyenv\pyenv-win\bin
C:\Users\<replace with your actual username>\.pyenv\pyenv-win\shims
```

Ensure all environment variables are properly set with high priority via the GUI:

```plaintext
This PC
   → Properties
      → Advanced system settings
         → Advanced → System Environment Variables...
            → PATH
```

> [!NOTE]
> If you are running Windows 10 1905 or newer, you might need to disable the built-in Python launcher via Start > "Manage App Execution Aliases" and turning off the "App Installer" aliases for Python.

## Usage

- To view a list of python versions supported by pyenv windows: `pyenv install -l`
- To filter the list: `pyenv install -l | Select-String 3.12`
- To install a python version: `pyenv install 3.12.4`
  - _Note: An install wizard may pop up for some non-silent installs. You'll need to click through the wizard during installation. There's no need to change any options in it, or you can use -q for quiet installation._
  - You can also install multiple versions in one command: `pyenv install 3.11.9 3.12.4`
- To set a python version as the global version: `pyenv global 3.12.4`
  - This is the version of python that will be used by default if a local version (see below) isn't set.
  - _Note: The version must first be installed._
- To set a python version as the local version: `pyenv local 3.12.4`
  - The version given will be used whenever `python` is called from within this folder. This is different than a virtual env, which needs to be explicitly activated.
  - _Note: The version must first be installed._
- After (un)installing any libraries using pip or modifying the files in a version's folder, you must run `pyenv rehash` to update pyenv with new shims for the python and libraries' executables.
  - _Note: This must be run outside of the `.pyenv` folder._
- To uninstall a python version: `pyenv uninstall 3.12.4`
- To view which python you are using and its path: `pyenv version`
- To view all the python versions installed on this system: `pyenv versions`
- Update the list of discoverable Python versions using: `pyenv update`

## Tab Completion

If you installed via the PowerShell installer, tab completion is enabled automatically. Otherwise, add this line to your `$PROFILE`:

```pwsh
. "$env:PYENV_HOME\completions\pyenv.ps1"
```

Then restart your shell. You can now press `Tab` to complete commands and flags, e.g. `pyenv inst<Tab>` → `pyenv install`, `pyenv install --l<Tab>` → `pyenv install --list`.

## How to update pyenv

The simplest way to update pyenv-win is:

```pwsh
pyenv upgrade
```

This downloads and runs the latest installer, preserving your installed Python versions, cache, and global version setting.

Alternatively:

- If installed via zip
  - Download the latest [pyenv-win.zip](https://github.com/satori-analytics/pyenv-win/releases/latest/download/pyenv-win.zip) from the [Releases](https://github.com/satori-analytics/pyenv-win/releases) page
  - Extract it and replace the `pyenv-win` folder under `%USERPROFILE%\.pyenv\`
- If installed via Git, navigate to the location where you installed pyenv, usually `%USERPROFILE%\.pyenv\pyenv-win`, and run `git pull`

> [!NOTE]
> `pyenv update` only refreshes the Python versions database. To update pyenv-win itself, use `pyenv upgrade`.

## FAQ

Please see the [FAQ](./docs/faq.md) page.

## Changelog

Please see the [Changelog](./docs/changelog.md) page.

## How to contribute

- Fork the project & clone locally.
- Create an upstream remote and sync your local copy before you branch.
- Branch for each separate piece of work using the naming convention: `feature/`, `fix/`, `ci/`, `test/`, or `doc/` prefix (e.g. `feature/add-caching`, `fix/shim-regression`).
- Do the work, write good commit messages. It's good practice to write test cases.
- Test the changes by running `Invoke-Pester ./tests`
- Push to your origin repository.
- Create a new Pull Request in GitHub.

## Bug Tracker and Support

- Please report any suggestions, bug reports, or annoyances with pyenv-win through the [GitHub bug tracker](https://github.com/satori-analytics/pyenv-win/issues).

## License and Copyright

- pyenv-win is licensed under [MIT](https://opensource.org/licenses/MIT) _2026_

## Author and Thanks

pyenv-win was originally created by [Kiran Kumar Kotari](https://github.com/kirankotari).
This fork is maintained by [Nikolas Demiridis](https://github.com/nikolasd), [Satori Analytics](https://github.com/satori-analytics) and [Contributors](https://github.com/satori-analytics/pyenv-win/graphs/contributors).

[1]: https://github.com/pyenv/pyenv
[2]: https://github.com/rbenv/rbenv
[3]: https://github.com/nak1114/rbenv-win
[4]: https://github.com/pyenv-win/pyenv-win

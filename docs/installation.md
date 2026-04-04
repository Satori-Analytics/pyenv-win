# Installation

## Prerequisites

**PowerShell 7 (pwsh) is required.** Install it from [Microsoft's official documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows) or via:

```pwsh
winget install --id Microsoft.PowerShell --source winget
```

Currently we support following ways, choose any of your comfort:

- [PowerShell](#powershell) - easiest way
- [Git Commands](#git-commands) - default way + adding manual settings
- [Pyenv-win zip](#pyenv-win-zip) - manual installation

Hurray! When you are done here are steps to [Validate installation](../README.md#validate-installation)

_NOTE:_ If you are running Windows 10 1905 or newer, you might need to disable the built-in Python launcher via Start > "Manage App Execution Aliases" and turning off the "App Installer" aliases for Python

***

## **PowerShell**

The easiest way to install pyenv-win is to run the following installation command in a PowerShell 7 (`pwsh`) terminal:

```pwsh
irm https://raw.githubusercontent.com/satori-analytics/pyenv-win/master/pyenv-win/install-pyenv-win.ps1 | iex
```

To uninstall pyenv-win (removes all installed Python versions):

```pwsh
& "${env:PYENV_HOME}install-pyenv-win.ps1" -Uninstall
```

Installation is complete!

[Return to README](../README.md#installation)

***

## **Git Commands**

The default way to install pyenv-win. Requires git to be installed.

Using command prompt:

`git clone https://github.com/satori-analytics/pyenv-win.git "%USERPROFILE%\.pyenv"`

Or using PowerShell:

`git clone https://github.com/satori-analytics/pyenv-win.git "$HOME\.pyenv"`

steps to [add System Settings](#add-system-settings)

_Note:_ Don't forget the check above link, it contains final steps to complete.

Installation is complete!

[Return to README](../README.md#installation)

***

## **Pyenv-win zip**

Manual installation steps for pyenv-win

1. Download the latest [pyenv-win.zip](https://github.com/satori-analytics/pyenv-win/releases/latest/download/pyenv-win.zip) from the [Releases](https://github.com/satori-analytics/pyenv-win/releases) page

2. Create a `.pyenv` directory if it doesn't exist:
   - Command prompt: `mkdir %USERPROFILE%\.pyenv`
   - PowerShell: `New-Item -ItemType Directory -Path "$HOME\.pyenv" -Force`

3. Extract the zip contents into `%USERPROFILE%\.pyenv\`

4. Ensure there is a `bin` folder under `%USERPROFILE%\.pyenv\pyenv-win`

steps to [add System Settings](#add-system-settings)

_Note:_ Don't forget the check above link, it contains final steps to complete.

Installation is complete!

Return to [README](../README.md#installation)

***

## **Add System Settings**

Use PowerShell to configure environment variables:

1. Adding PYENV, PYENV_HOME and PYENV_ROOT to your Environment Variables

   ```pwsh
   [System.Environment]::SetEnvironmentVariable('PYENV',$env:USERPROFILE + "\.pyenv\pyenv-win\","User")

   [System.Environment]::SetEnvironmentVariable('PYENV_ROOT',$env:USERPROFILE + "\.pyenv\pyenv-win\","User")

   [System.Environment]::SetEnvironmentVariable('PYENV_HOME',$env:USERPROFILE + "\.pyenv\pyenv-win\","User")
   ```

2. Now adding the following paths to your USER PATH variable in order to access the pyenv command

   ```pwsh
   [System.Environment]::SetEnvironmentVariable('path', $env:USERPROFILE + "\.pyenv\pyenv-win\bin;" + $env:USERPROFILE + "\.pyenv\pyenv-win\shims;" + [System.Environment]::GetEnvironmentVariable('path', "User"),"User")
   ```

If for some reason you cannot execute PowerShell commands (likely on an organization-managed device), type "environment variables for your account" in the Windows search bar and open the Environment Variables dialog.
You will need create those 3 new variables in System Variables section (bottom half). Let's assume username is `my_pc`.
|Variable|Value|
|---|---|
|PYENV|C:\Users\my_pc\\.pyenv\pyenv-win\
|PYENV_HOME|C:\Users\my_pc\\.pyenv\pyenv-win\
|PYENV_ROOT|C:\Users\my_pc\\.pyenv\pyenv-win\

And add two more lines to user variable `Path`.
```
C:\Users\my_pc\.pyenv\pyenv-win\bin
C:\Users\my_pc\.pyenv\pyenv-win\shims
```

Installation is done. Hurray!
Return to [README](../README.md#installation)

## **Usage with Git BASH**

From within Git BASH, run the following:

```sh
echo 'export PATH="$HOME/.pyenv/pyenv-win/shims:$PATH"' >> ~/.bash_profile
echo 'export PATH="$HOME/.pyenv/pyenv-win/bin:$PATH"' >> ~/.bash_profile
```

Open a new terminal, and confirm `pyenv --version` works.

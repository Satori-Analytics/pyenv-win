# FAQ

- **Question:** python --version is showing different version than expected?
  - **Answer:** Check your **Environment Variables** where pyenv paths need to have higher priority than other Python entries. You can manually move them up, save, and restart your terminal.

- **Question:** Does pyenv for windows support python2?
  - **Answer:** Yes, We support python2 from version 2.4+ until python.org officially removes it.
  - Versions below 2.4 use outdated Wise installers and have issues installing multiple patch versions, unlike Windows MSI and the new Python3 installers that support "extraction" installations.

- **Question:** Does pyenv for windows support python3?
  - **Answer:** Yes, we support python3 from version 3.8. We support it from 3.8 until python.org officially removes it.

- **Question:** I am getting the issue `batch file cannot be found.` while installing python, what should I do?
  - **Answer:** This error was common in pyenv-win versions prior to 4.0. In version 4.0+, pyenv-win uses PowerShell 7 and this error should no longer occur. If you see it, ensure you are running the latest version.

- **Question:** System is stuck while uninstalling a python version
  - **Answer:** Navigate to the location where you installed pyenv, open its 'versions' folder (usually `%USERPROFILE%\.pyenv\pyenv-win\versions`), and delete the folder of the version you want removed.

- **Question:** pyenv-win is not recognised, but I have set the ENV PATH?
  - **Answer:** According to Windows, when adding a path under the User variable you need to log out and log in again in order for the change to take effect. For System variables this is not required.

- **Question:** How do I configure my company proxy in pyenv for windows?
  - **Answer:** Set the `http_proxy` or `https_proxy` environment variable with the hostname or IP address of the proxy server in URL format, for example: `http://username:password@hostname:port/` or `http://hostname:port/`

- **Question:** pyenv is not recognised as a command, and I have PowerShell 5 / Windows PowerShell.
  - **Answer:** pyenv-win 4.0+ requires PowerShell 7 (pwsh). Install it via `winget install --id Microsoft.PowerShell` or from [Microsoft's documentation](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows). Then run `pwsh` to start a PowerShell 7 session.

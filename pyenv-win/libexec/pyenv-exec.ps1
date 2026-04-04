#Requires -Version 7
# pyenv exec: Runs an executable with the selected Python version's bin dir in PATH
# NOTE: The actual exec logic is handled inline in bin/pyenv.ps1 dispatcher.
# This script only handles --help.
param()

Write-Output "Usage: pyenv exec <command> [arg1 arg2...]"
Write-Output ""
Write-Output "Runs an executable by first preparing PATH so that the selected Python"
Write-Output "version's directory is at the front."
Write-Output ""
Write-Output "For example, if the currently selected Python version is 3.9.3:"
Write-Output "  pyenv exec pip install -r requirements.txt"
Write-Output ""
Write-Output "is equivalent to prepending the version's directory to PATH before running"
Write-Output "the command."

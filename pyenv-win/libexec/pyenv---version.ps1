#Requires -Version 7
# pyenv --version: Show pyenv-win version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv --version"
    Write-Output ""
    Write-Output "Displays the version of pyenv-win."
    exit 0
}

Write-Output "pyenv $(Get-PyenvVersion)"

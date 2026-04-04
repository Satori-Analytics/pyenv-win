#Requires -Version 7
# pyenv rehash: Rehash pyenv shims
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv rehash"
    Write-Output ""
    Write-Output "Rehash pyenv shims (run this after installing executables)"
    exit 0
}

$versions = Get-InstalledVersions
if ($versions.Count -eq 0) {
    Write-Output "No version installed. Please install one with 'pyenv install <version>'."
}
else {
    Invoke-Rehash
}

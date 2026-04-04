#Requires -Version 7
# pyenv version-name: Show the current Python version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv version-name"
    Write-Output ""
    Write-Output "Shows the currently selected Python version."
    exit 0
}

if (-not (Test-Path $script:PyenvVersions -PathType Container)) {
    New-Item -ItemType Directory -Path $script:PyenvVersions -Force | Out-Null
}

$versions = Get-CurrentVersions
foreach ($ver in $versions.Keys) {
    Write-Output $ver
}

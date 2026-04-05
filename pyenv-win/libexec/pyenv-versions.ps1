#Requires -Version 7
# pyenv versions: List all Python versions available to pyenv
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv versions [--bare]"
    Write-Output ""
    Write-Output "Lists all Python versions found in %PYENV_HOME%\versions\."
    Write-Output "The version shown with * is currently active."
    exit 0
}

$isBare = $args -contains '--bare'

if (-not (Test-Path $script:PyenvVersions -PathType Container)) {
    New-Item -ItemType Directory -Path $script:PyenvVersions -Force | Out-Null
}

$currentVersions = Get-CurrentVersionsNoError

Get-ChildItem $script:PyenvVersions -Directory | ForEach-Object {
    $ver = $_.Name
    if ($isBare) {
        Write-Output $ver
    }
    elseif ($currentVersions.Contains($ver)) {
        Write-Output "* $ver (set by $($currentVersions[$ver]))"
    }
    else {
        Write-Output "  $ver"
    }
}

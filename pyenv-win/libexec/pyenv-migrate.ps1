#Requires -Version 7
# pyenv migrate: Migrate pip packages between Python versions
param()

if ($args.Count -lt 2 -or $args -contains '--help') {
    Write-Output "Usage: pyenv migrate <from> <to>"
    Write-Output "   ex. pyenv migrate 3.8.10 3.11.4"
    Write-Output ""
    Write-Output "Migrate pip packages from a Python version to another."
    if ($args -contains '--help') { exit 0 }
    exit 1
}

$fromVersion = $args[0]
$toVersion = $args[1]

$fromPath = Join-Path $script:PyenvVersions $fromVersion
$toPath = Join-Path $script:PyenvVersions $toVersion

if (-not (Test-Path $fromPath -PathType Container)) {
    Write-Output "Python $fromVersion does not exist"
    exit 1
}
if (-not (Test-Path $toPath -PathType Container)) {
    Write-Output "Python $toVersion does not exist"
    exit 1
}

$fromPython = Join-Path $fromPath 'python.exe'
$toPython = Join-Path $toPath 'python.exe'
if (-not (Test-Path $fromPython)) {
    Write-Output "Python executable not found in $fromVersion"
    exit 1
}
if (-not (Test-Path $toPython)) {
    Write-Output "Python executable not found in $toVersion"
    exit 1
}

$tmpFile = Join-Path $env:TEMP "pyenv_requirements_$(Get-Date -Format 'HHmmss').tmp"

try {
    $savedPipRequire = $env:PIP_REQUIRE_VIRTUALENV
    $env:PIP_REQUIRE_VIRTUALENV = '0'

    # Freeze from source version
    & $fromPython -m pip freeze | Set-Content $tmpFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to freeze packages from $fromVersion"
        exit 1
    }

    # Install to target version
    & $toPython -m pip install -r $tmpFile
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Failed to install packages to $toVersion"
        exit 1
    }
}
finally {
    $env:PIP_REQUIRE_VIRTUALENV = $savedPipRequire
    if (Test-Path $tmpFile) { Remove-Item $tmpFile -Force }
}

Invoke-Rehash

#Requires -Version 7
# pyenv prefix: Display prefixes for Python versions
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv prefix [<version>...]"
    Write-Output ""
    Write-Output "Displays the directories where the given Python versions are installed."
    Write-Output "If no version is given, displays the locations of the currently selected versions."
    exit 0
}

# Determine which versions to resolve
if ($args.Count -gt 0) {
    $requestedVersions = $args
}
else {
    $versions = Get-CurrentVersionsNoError
    if ($versions.Count -eq 0) {
        Write-Output "pyenv: no version set"
        exit 1
    }
    $requestedVersions = @($versions.Keys)
}

$prefixes = @()
foreach ($ver in $requestedVersions) {
    $resolved = Resolve-VersionPrefix -Prefix $ver -Known:$false
    $versionDir = Join-Path $script:PyenvVersions $resolved
    if (-not (Test-Path $versionDir -PathType Container)) {
        Write-Output "pyenv: version '$resolved' not installed"
        exit 1
    }
    $prefixes += $versionDir
}

Write-Output ($prefixes -join ';')

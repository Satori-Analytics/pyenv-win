#Requires -Version 7
# pyenv cache: Manage the installer cache
param()

function Show-CacheHelp {
    Write-Output "Usage: pyenv cache [--clear] [--sync]"
    Write-Output ""
    Write-Output "Without arguments, lists all cached Python installers."
    Write-Output ""
    Write-Output "   --clear  Remove all cached installers"
    Write-Output "   --sync   Remove cached installers for versions that are not installed"
    exit 0
}

$optClear = $false
$optSync = $false

foreach ($arg in $args) {
    switch ($arg) {
        '--help' { Show-CacheHelp }
        '--clear' { $optClear = $true }
        '--sync' { $optSync = $true }
        default {
            Write-Output "pyenv cache: unrecognized option: $arg"
            exit 1
        }
    }
}

if ($optClear -and $optSync) {
    Write-Output "pyenv cache: --clear and --sync are mutually exclusive"
    exit 1
}

if (-not (Test-Path $script:PyenvCache -PathType Container)) {
    if (-not $optClear -and -not $optSync) {
        Write-Output "No cached installers."
    }
    exit 0
}

$cachedItems = Get-ChildItem $script:PyenvCache
if ($cachedItems.Count -eq 0) {
    if (-not $optClear -and -not $optSync) {
        Write-Output "No cached installers."
    }
    exit 0
}

if ($optClear) {
    Remove-Item $script:PyenvCache -Recurse -Force
    Write-Output "Cache cleared."
    exit 0
}

if ($optSync) {
    $installedVersions = @()
    if (Test-Path $script:PyenvVersions -PathType Container) {
        $installedVersions = (Get-ChildItem $script:PyenvVersions -Directory).Name
    }
    $removed = 0
    foreach ($item in $cachedItems) {
        # Match directory names directly, or extract version from installer filenames
        $matchesInstalled = $false
        if ($item.PSIsContainer) {
            $matchesInstalled = $item.Name -in $installedVersions
        }
        else {
            foreach ($ver in $installedVersions) {
                if ($item.Name -match [regex]::Escape($ver)) {
                    $matchesInstalled = $true
                    break
                }
            }
        }
        if (-not $matchesInstalled) {
            Remove-Item $item.FullName -Recurse -Force
            $removed++
        }
    }
    if ($removed -gt 0) {
        Write-Output "Removed $removed cached item(s) not matching installed versions."
    }
    else {
        Write-Output "Cache is already in sync with installed versions."
    }
    exit 0
}

# Default: list cached items
foreach ($item in $cachedItems) {
    Write-Output $item.Name
}

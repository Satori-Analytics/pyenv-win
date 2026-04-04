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

$cachedFiles = Get-ChildItem $script:PyenvCache -File
if ($cachedFiles.Count -eq 0) {
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
    foreach ($file in $cachedFiles) {
        $matchesInstalled = $false
        foreach ($ver in $installedVersions) {
            if ($file.Name -match [regex]::Escape($ver)) {
                $matchesInstalled = $true
                break
            }
        }
        if (-not $matchesInstalled) {
            Remove-Item $file.FullName -Force
            $removed++
        }
    }

    # Also remove any leftover v3 extraction directories
    $v3Dirs = Get-ChildItem $script:PyenvCache -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $v3Dirs) {
        Remove-Item $dir.FullName -Recurse -Force
        $removed++
    }

    if ($removed -gt 0) {
        Write-Output "Removed $removed cached item(s) not matching installed versions."
    }
    else {
        Write-Output "Cache is already in sync with installed versions."
    }
    exit 0
}

# Default: list cached installers with version and size
$totalSize = 0
foreach ($file in $cachedFiles) {
    $size = $file.Length
    $totalSize += $size
    $sizeStr = if ($size -ge 1MB) { "{0:N1} MB" -f ($size / 1MB) } else { "{0:N0} KB" -f ($size / 1KB) }
    Write-Output ("{0,-40} {1,10}" -f $file.Name, $sizeStr)
}
$totalStr = if ($totalSize -ge 1MB) { "{0:N1} MB" -f ($totalSize / 1MB) } else { "{0:N0} KB" -f ($totalSize / 1KB) }
Write-Output ""
Write-Output "$($cachedFiles.Count) installer(s), $totalStr total"

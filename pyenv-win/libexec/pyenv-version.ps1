#Requires -Version 7
# pyenv version: Show the current Python version and its origin
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv version"
    Write-Output ""
    Write-Output "Shows the currently selected Python version and how it was"
    Write-Output "selected. To obtain only the version string, use ``pyenv"
    Write-Output "version-name'."
    exit 0
}

if (-not (Test-Path $script:PyenvVersions -PathType Container)) {
    New-Item -ItemType Directory -Path $script:PyenvVersions -Force | Out-Null
}

# Check for python.exe in PATH before pyenv shims (PATH conflict detection)
$shimsNorm = $null
if (Test-Path $script:PyenvShims) {
    $shimsNorm = (Resolve-Path $script:PyenvShims).Path.TrimEnd('\', '/')
}
$pathDirs = $env:PATH -split ';'
foreach ($dir in $pathDirs) {
    $dirTrimmed = $dir.TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($dirTrimmed)) { continue }
    # Stop once we reach the shims directory
    if ($shimsNorm -and $dirTrimmed -ieq $shimsNorm) { break }
    $pythonExe = Join-Path $dir 'python.exe'
    if (Test-Path $pythonExe) {
        Write-Output "$([char]0x1b)[91mFATAL: Found $([char]0x1b)[95m${pythonExe}$([char]0x1b)[91m version before pyenv in PATH.$([char]0x1b)[0m"
        Write-Output "$([char]0x1b)[91mPlease remove $([char]0x1b)[95m${dir}\$([char]0x1b)[91m from PATH for pyenv to work properly.$([char]0x1b)[0m"
        break
    }
}

$versions = Get-CurrentVersions
foreach ($ver in $versions.Keys) {
    Write-Output "$ver (set by $($versions[$ver]))"
}

#Requires -Version 7
# pyenv install: Install Python versions
param()

function Show-InstallHelp {
    Write-Output "Usage: pyenv install [-s] [-f] <version> [<version> ...] [-r|--register]"
    Write-Output "       pyenv install [-f] [--32only|--64only] -a|--all"
    Write-Output "       pyenv install [-f] -c|--clear"
    Write-Output "       pyenv install -l|--list"
    Write-Output ""
    Write-Output "  -l/--list              List all available versions"
    Write-Output "  -a/--all               Installs all known version from the local version DB cache"
    Write-Output "  -c/--clear             Removes downloaded installers from the cache to free space"
    Write-Output "  -f/--force             Install even if the version appears to be installed already"
    Write-Output "  -s/--skip-existing     Skip the installation if the version appears to be installed already"
    Write-Output "  -r/--register          Register version for py launcher"
    Write-Output "  -q/--quiet             Install using /quiet. This does not show the UI nor does it prompt for inputs"
    Write-Output "  --32only               Installs only 32-bit Python using -a/--all switch."
    Write-Output "  --64only               Installs only 64-bit Python using -a/--all switch."
    Write-Output "  --dev                  Installs precompiled standard libraries, debug symbols, and debug binaries (only applies to web installer)."
    Write-Output "  --help                 Help, list of options allowed on pyenv install"
    exit 0
}

# Parse arguments
$optForce = $false
$optSkip = $false
$optList = $false
$optQuiet = $false
$optAll = $false
$opt32 = $false
$opt64 = $false
$optDev = $false
$optReg = $false
$optClear = $false
$installVersions = [ordered]@{}

foreach ($arg in $args) {
    switch ($arg) {
        '--help' { Show-InstallHelp }
        '-l' { $optList = $true }
        '--list' { $optList = $true }
        '-f' { $optForce = $true }
        '--force' { $optForce = $true }
        '-s' { $optSkip = $true }
        '--skip-existing' { $optSkip = $true }
        '-q' { $optQuiet = $true }
        '--quiet' { $optQuiet = $true }
        '-a' { $optAll = $true }
        '--all' { $optAll = $true }
        '-c' { $optClear = $true }
        '--clear' { $optClear = $true }
        '--32only' { $opt32 = $true }
        '--64only' { $opt64 = $true }
        '--dev' { $optDev = $true }
        '-r' { $optReg = $true }
        '--register' { $optReg = $true }
        default {
            $resolved = Resolve-VersionPrefix -Prefix $arg -Known
            $installVersions[$resolved] = $true
        }
    }
}

# Validation
if ($opt32 -and $opt64) {
    Write-Output "pyenv-install: only --32only or --64only may be specified, not both."
    exit 1
}
if ($optReg -and $opt32) {
    Write-Output "pyenv-install: --register not supported for 32 bits."
    exit 1
}
if ($optReg -and $optAll) {
    Write-Output "pyenv-install: --register not supported for all versions."
    exit 1
}

# Print mirrors
foreach ($mirror in $script:Mirrors) {
    Write-Output ":: [Info] ::  Mirror: $mirror"
}

# Load version database
$versions = Import-VersionsCache
if ($versions.Count -eq 0) {
    Write-Output "pyenv-install: no definitions in local database"
    Write-Output ""
    Write-Output "Please update the local database cache with ``pyenv update'."
    exit 1
}

# Handle --list
if ($optList) {
    foreach ($version in $versions.Keys) {
        Write-Output $version
    }
    exit 0
}

# Handle --clear
if ($optClear) {
    if (Test-Path $script:PyenvCache) {
        $exitCode = 0
        Get-ChildItem $script:PyenvCache | ForEach-Object {
            try {
                Remove-Item $_.FullName -Recurse -Force:$optForce
            }
            catch {
                Write-Output "pyenv: Error deleting $($_.Name): $_"
                $exitCode = 1
            }
        }
        exit $exitCode
    }
    exit 0
}

# Handle --all
if ($optAll) {
    $installVersions = [ordered]@{}
    foreach ($version in $versions.Keys) {
        if ($versions.Contains($version)) {
            if ($opt64 -and -not $versions[$version][$script:LV_x64]) { continue }
            if ($opt32 -and $versions[$version][$script:LV_x64]) { continue }
            $installVersions[$version] = $true
        }
    }
}

# Default: use current version if none specified
if ($installVersions.Count -eq 0 -and -not $optAll) {
    $current = Get-CurrentVersionNoError
    if ($null -ne $current) {
        $resolved = Resolve-VersionPrefix -Prefix $current[0] -Known
        $installVersions[$resolved] = $true
    }
    else {
        Show-InstallHelp
    }
}

# Pre-check all versions exist in DB
foreach ($version in @($installVersions.Keys)) {
    if (-not $versions.Contains($version)) {
        Write-Output "pyenv-install: definition not found: $version"
        Write-Output ""
        Write-Output "See all available versions with ``pyenv install --list``."
        Write-Output "Does the list seem out of date? Update it using ``pyenv update``."
        exit 1
    }
}

# Install each version
$installed = @{}
foreach ($version in @($installVersions.Keys)) {
    if ($installed.ContainsKey($version)) { continue }

    $verDef = $versions[$version]
    $installPath = Join-Path $script:PyenvVersions $verDef[$script:LV_Code]
    $installFile = Join-Path $script:PyenvCache $verDef[$script:LV_FileName]

    if ($optSkip -and (Test-Path $installPath)) {
        Write-Output ":: [Info] :: Skipping $version (already installed)"
        continue
    }

    if ($optForce) {
        Clear-InstallArtifacts -InstallPath $installPath -InstallFile $installFile
    }

    if (Test-Path $installPath) {
        Write-Output ":: [Info] :: $version is already installed"
        $installed[$version] = $true
        continue
    }

    # Ensure directories exist
    $installFileDir = Split-Path $installFile -Parent
    if (-not (Test-Path $installFileDir)) {
        New-Item -ItemType Directory -Path $installFileDir -Force | Out-Null
    }
    $installPathParent = Split-Path $installPath -Parent
    if (-not (Test-Path $installPathParent)) {
        New-Item -ItemType Directory -Path $installPathParent -Force | Out-Null
    }

    # Download if needed
    if (-not (Test-Path $installFile)) {
        Write-Output ":: [Downloading] ::  $($verDef[$script:LV_Code]) ..."
        Write-Output ":: [Downloading] ::  From $($verDef[$script:LV_URL])"
        Write-Output ":: [Downloading] ::  To   $installFile"
        Invoke-PythonDownload -Url $verDef[$script:LV_URL] -OutFile $installFile
    }

    # Install
    Write-Output ":: [Installing] ::  $($verDef[$script:LV_Code]) ..."
    $exitCode = 0

    $ext = [System.IO.Path]::GetExtension($installFile).ToLower()
    if ($verDef[$script:LV_MSI]) {
        $exitCode = Install-PythonMsi -InstallerPath $installFile -InstallPath $installPath
    }
    elseif ($ext -eq '.zip') {
        $exitCode = Install-PythonZip -ZipPath $installFile -InstallPath $installPath -ZipRootDir $verDef[$script:LV_ZipRootDir]
    }
    else {
        # EXE installer (Python 3.5+) — use silent install directly (replaces dark.exe/WiX)
        $exitCode = Install-PythonExe -InstallerPath $installFile -InstallPath $installPath `
            -Quiet:$optQuiet -Dev:$optDev
    }

    if ($exitCode -eq 0) {
        Write-Output ":: [Info] :: completed! $($verDef[$script:LV_Code])"
        New-PythonAliases -InstallPath $installPath -VersionCode $verDef[$script:LV_Code]
        if ($optReg) {
            Register-PythonVersion -Version $verDef[$script:LV_Code] -InstallPath $installPath
        }
    }
    else {
        Write-Output ":: [Error] :: couldn't install $($verDef[$script:LV_Code])"
    }

    $installed[$version] = $true
}

Invoke-Rehash

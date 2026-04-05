#Requires -Version 7
# Shared test infrastructure for Pester tests
# Replaces conftest.py + test_pyenv_helpers.py

$script:SrcRoot = Split-Path $PSScriptRoot -Parent
$script:PyenvWinSrc = Join-Path $script:SrcRoot 'pyenv-win'

function New-PyenvTestEnvironment {
    <#
    .SYNOPSIS
        Creates an isolated pyenv directory tree in $TestDrive for testing.
        Copies all .ps1 source files, creates mock versions if specified.
    .PARAMETER Versions
        Array of version strings to create as mock Python installations (e.g. '3.9.7', '3.10.1-win32')
    .PARAMETER GlobalVersion
        Version string(s) to write to the global version file
    .PARAMETER LocalVersion
        Version string(s) to write to .python-version in LocalPath
    .PARAMETER CacheFiles
        Array of installer filenames to create in install_cache
    #>
    param(
        [string[]]$Versions = @(),
        [string[]]$GlobalVersion,
        [string[]]$LocalVersion,
        [string[]]$CacheFiles = @()
    )

    $pyenvPath = Join-Path $TestDrive 'pyenv-test'
    $localPath = Join-Path $TestDrive 'local dir with spaces'

    # Clean up any previous test environment
    if (Test-Path $pyenvPath) { Remove-Item $pyenvPath -Recurse -Force }
    if (Test-Path $localPath) { Remove-Item $localPath -Recurse -Force }

    # Create directory structure
    $dirs = @('bin', 'lib', 'libexec', 'shims', 'versions', 'install_cache')
    foreach ($d in $dirs) {
        New-Item -ItemType Directory -Path (Join-Path $pyenvPath $d) -Force | Out-Null
    }
    New-Item -ItemType Directory -Path $localPath -Force | Out-Null

    # Copy source files
    $srcPyenvWin = $script:PyenvWinSrc

    # Copy lib/*.ps1
    Get-ChildItem (Join-Path $srcPyenvWin 'lib') -Filter '*.ps1' | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $pyenvPath 'lib' $_.Name)
    }

    # Copy libexec/*.ps1
    Get-ChildItem (Join-Path $srcPyenvWin 'libexec') -Filter '*.ps1' | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $pyenvPath 'libexec' $_.Name)
    }

    # Copy bin/pyenv.ps1
    Copy-Item (Join-Path $srcPyenvWin 'bin' 'pyenv.ps1') (Join-Path $pyenvPath 'bin' 'pyenv.ps1')

    # Copy .versions.xml if exists
    $xmlSrc = Join-Path $srcPyenvWin '.versions.xml'
    if (Test-Path $xmlSrc) {
        Copy-Item $xmlSrc (Join-Path $pyenvPath '.versions.xml')
    }

    # Copy ../.version
    $versionSrc = Join-Path $script:SrcRoot '.version'
    if (Test-Path $versionSrc) {
        Copy-Item $versionSrc (Join-Path $TestDrive '.version')
    }

    # Create mock Python versions
    foreach ($ver in $Versions) {
        New-MockPythonVersion -PyenvPath $pyenvPath -Version $ver
    }

    # Set global version
    if ($GlobalVersion) {
        $content = ($GlobalVersion -join "`n")
        Set-Content -Path (Join-Path $pyenvPath 'version') -Value $content -NoNewline
    }

    # Set local version
    if ($LocalVersion) {
        $content = ($LocalVersion -join "`n")
        Set-Content -Path (Join-Path $localPath '.python-version') -Value $content -NoNewline
    }

    # Create cache files
    foreach ($cf in $CacheFiles) {
        $cachePath = Join-Path $pyenvPath 'install_cache' $cf
        [byte[]]$bytes = [byte[]]::new(1024)
        [System.IO.File]::WriteAllBytes($cachePath, $bytes)
    }

    # Clear any leftover .python-version in TestDrive root
    $rootPyVer = Join-Path $TestDrive '.python-version'
    if (Test-Path $rootPyVer) { Remove-Item $rootPyVer }

    return @{
        PyenvPath  = $pyenvPath
        LocalPath  = $localPath
        BinPath    = Join-Path $pyenvPath 'bin'
        ShimsPath  = Join-Path $pyenvPath 'shims'
        VersionsPath = Join-Path $pyenvPath 'versions'
        CachePath  = Join-Path $pyenvPath 'install_cache'
        PyenvFile  = Join-Path $pyenvPath 'bin' 'pyenv.ps1'
    }
}

function New-MockPythonVersion {
    <#
    .SYNOPSIS
        Creates a mock Python version directory with executables
    #>
    param(
        [string]$PyenvPath,
        [string]$Version
    )

    # Parse version string (e.g. '3.9.7', '3.9.7-win32', '3.9.7-amd64')
    $cleanVersion = $Version -replace '-(win32|amd64|arm64)$', ''
    if ($cleanVersion -match '^(\d+)\.(\d+)\.?(\d*)') {
        $major = $Matches[1]
        $minor = $Matches[2]
        $micro = if ($Matches[3]) { $Matches[3] } else { '0' }
    }
    else {
        $major = '3'; $minor = '0'; $micro = '0'
    }

    $versionDir = Join-Path $PyenvPath 'versions' $Version
    $scriptsDir = Join-Path $versionDir 'Scripts'

    New-Item -ItemType Directory -Path $versionDir -Force | Out-Null
    New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

    # Create python executables
    $pythonSuffixes = @('', $major, "$major$minor", "$major.$minor")
    foreach ($suffix in $pythonSuffixes) {
        New-Item -ItemType File -Path (Join-Path $versionDir "python$suffix.exe") -Force | Out-Null
        New-Item -ItemType File -Path (Join-Path $versionDir "pythonw$suffix.exe") -Force | Out-Null
    }

    # Create version.bat
    Set-Content -Path (Join-Path $versionDir 'version.bat') -Value "@echo $major.$minor.$micro"

    # Create Scripts executables
    $pipSuffixes = @('', $major, "$major.$minor")
    foreach ($suffix in $pipSuffixes) {
        New-Item -ItemType File -Path (Join-Path $scriptsDir "pip$suffix.exe") -Force | Out-Null
    }
    $easyInstallSuffixes = @('', "-$major.$minor")
    foreach ($suffix in $easyInstallSuffixes) {
        New-Item -ItemType File -Path (Join-Path $scriptsDir "easy_install$suffix.exe") -Force | Out-Null
    }

    # Create helper scripts
    Set-Content -Path (Join-Path $scriptsDir 'hello.bat') -Value '@echo Hello world!'
    Set-Content -Path (Join-Path $scriptsDir 'version.bat') -Value "@echo $major.$minor.$micro"
}

function Invoke-Pyenv {
    <#
    .SYNOPSIS
        Runs pyenv dispatcher in an isolated environment, captures stdout/stderr
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Env,
        [Parameter(ValueFromRemainingArguments)]
        [string[]]$Arguments
    )

    $pyenvFile = $Env.PyenvFile
    $pyenvPath = $Env.PyenvPath

    # Build isolated environment
    $envVars = @{
        'PYENV'           = $pyenvPath
        'PYENV_ROOT'      = $pyenvPath
        'PYENV_HOME'      = $pyenvPath
        'PYENV_FORCE_ARCH' = 'AMD64'
    }

    # Build PATH: bin + shims + system (minus real python)
    $cleanPath = ($env:PATH -split ';') | Where-Object {
        $p = $_
        if ([string]::IsNullOrWhiteSpace($p)) { return $false }
        if (Test-Path (Join-Path $p 'python.exe') -ErrorAction SilentlyContinue) { return $false }
        $parent = Split-Path $p -Leaf
        if ($parent -ieq 'Scripts') {
            $parentDir = Split-Path $p -Parent
            if (Test-Path (Join-Path $parentDir 'python.exe') -ErrorAction SilentlyContinue) { return $false }
        }
        return $true
    }
    $envVars['PATH'] = (@($Env.BinPath, $Env.ShimsPath) + $cleanPath) -join ';'

    $allArgs = @('-NoProfile', '-File', $pyenvFile) + $Arguments

    $result = & {
        $proc = Start-Process -FilePath 'pwsh' -ArgumentList $allArgs -NoNewWindow -Wait -PassThru `
            -RedirectStandardOutput "$TestDrive\stdout.txt" -RedirectStandardError "$TestDrive\stderr.txt"

        # Set environment for the process
        # Note: Start-Process doesn't support custom env easily, use subprocess approach
    }

    # Use .NET Process for proper env var control
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $psi.Arguments = ($allArgs | ForEach-Object { "`"$_`"" }) -join ' '
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $Env.LocalPath
    $psi.Environment.Clear()

    # Copy current env, then override
    foreach ($key in [System.Environment]::GetEnvironmentVariables().Keys) {
        $psi.Environment[$key] = [System.Environment]::GetEnvironmentVariable($key)
    }
    foreach ($key in $envVars.Keys) {
        $psi.Environment[$key] = $envVars[$key]
    }
    # Remove VIRTUAL_ENV and PYTHONPATH
    $psi.Environment.Remove('VIRTUAL_ENV') | Out-Null
    $psi.Environment.Remove('PYTHONPATH') | Out-Null

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd().Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
    $stderr = $proc.StandardError.ReadToEnd().Replace("`r`n", "`n").Replace("`r", "`n").TrimEnd("`n")
    $proc.WaitForExit()

    return @{
        Stdout   = $stdout
        Stderr   = $stderr
        ExitCode = $proc.ExitCode
    }
}

function Initialize-PyenvLibraries {
    <#
    .SYNOPSIS
        Generates a temporary init script that dot-sources pyenv libraries.
        Returns the script path. Caller MUST dot-source the returned path:
            . (Initialize-PyenvLibraries -Env $env)
        This ensures functions are loaded into the caller's scope.
    #>
    param(
        [Parameter(Mandatory)]
        [hashtable]$Env
    )

    $pyenvPath = $Env.PyenvPath
    $libPath = Join-Path $pyenvPath 'lib'
    $initScript = Join-Path $TestDrive '_pyenv-libs-init.ps1'

    $lines = @()
    $lines += '$env:PYENV_HOME = "' + $pyenvPath + '"'
    $lines += '. "' + (Join-Path $libPath 'core.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'getopt.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'versions-db.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'versions.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'shims.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'install.ps1') + '"'
    $lines += '. "' + (Join-Path $libPath 'registry.ps1') + '"'

    Set-Content -Path $initScript -Value ($lines -join "`n")
    return $initScript
}

function Get-NativeVersion {
    <#
    .SYNOPSIS
        Returns a version string with architecture suffix based on PYENV_FORCE_ARCH.
        Equivalent to Python's Native() class.
    #>
    param([string]$Version)

    $arch = $env:PYENV_FORCE_ARCH
    if ($arch -eq 'ARM64') {
        return "$Version-arm64"
    }
    return $Version
}

function Get-VersionWithArch {
    <#
    .SYNOPSIS
        Returns version string with explicit -amd64 suffix.
        Equivalent to Python's Amd64() class.
    #>
    param([string]$Version, [string]$Arch = 'amd64')
    return "$Version-$Arch"
}

function Get-NotInstalledOutput {
    <#
    .SYNOPSIS
        Returns the expected error output for a version that is not installed.
    #>
    param([string]$Version)
    return "pyenv specific python requisite didn't meet. Project is using different version of python.`nInstall python '$Version' by typing: 'pyenv install $Version'"
}

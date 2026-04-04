#Requires -Version 7
# pyenv-win install library
# Download, extract, ensurepip, Python aliases

$script:Mirrors = @()
$customMirror = $env:PYTHON_BUILD_MIRROR_URL
if ($customMirror) {
    $script:Mirrors = @($customMirror)
}
else {
    $script:Mirrors = @(
        'https://www.python.org/ftp/python',
        'https://downloads.python.org/pypy/versions.json',
        'https://api.github.com/repos/oracle/graalpython/releases'
    )
}

function Invoke-PythonDownload {
    param(
        [string]$Url,
        [string]$OutFile
    )

    $parentDir = Split-Path $OutFile -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    try {
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    }
    catch {
        Write-PyenvError ":: [ERROR] :: $_"
        exit 1
    }
}

function Install-PythonMsi {
    param(
        [string]$InstallerPath,
        [string]$InstallPath
    )

    $exitCode = (Start-Process -FilePath 'msiexec' -ArgumentList @(
            '/quiet', '/a', "`"$InstallerPath`"", "TargetDir=`"$InstallPath`""
        ) -Wait -PassThru -NoNewWindow).ExitCode

    if ($exitCode -ne 0) { return $exitCode }

    # Remove duplicate .msi files from install path
    Get-ChildItem $InstallPath -Filter '*.msi' -File | Remove-Item -Force

    # Run ensurepip if available
    $ensurepipPath = Join-Path $InstallPath 'Lib' 'ensurepip'
    if (Test-Path $ensurepipPath) {
        $pythonExe = Join-Path $InstallPath 'python.exe'
        $pipResult = (Start-Process -FilePath $pythonExe -ArgumentList @(
                '-E', '-s', '-m', 'ensurepip', '-U', '--default-pip'
            ) -Wait -PassThru -NoNewWindow).ExitCode
        if ($pipResult -ne 0) {
            Write-PyenvError ":: [Error] :: error installing pip."
        }
    }

    return 0
}

function Install-PythonExe {
    param(
        [string]$InstallerPath,
        [string]$InstallPath,
        [switch]$Quiet,
        [switch]$Dev
    )

    $argList = @('/quiet', "TargetDir=`"$InstallPath`"", 'InstallAllUsers=0',
        'Include_launcher=0', 'Include_test=0', 'SimpleInstall=1')
    if ($Dev) {
        $argList += @('Include_debug=1', 'Include_symbols=1', 'Include_dev=1')
    }

    $exitCode = (Start-Process -FilePath $InstallerPath -ArgumentList $argList `
            -Wait -PassThru -NoNewWindow).ExitCode

    if ($exitCode -ne 0) { return $exitCode }

    # Run ensurepip if available
    $ensurepipPath = Join-Path $InstallPath 'Lib' 'ensurepip'
    if (Test-Path $ensurepipPath) {
        $pythonExe = Join-Path $InstallPath 'python.exe'
        $pipResult = (Start-Process -FilePath $pythonExe -ArgumentList @(
                '-E', '-s', '-m', 'ensurepip', '-U', '--default-pip'
            ) -Wait -PassThru -NoNewWindow).ExitCode
        if ($pipResult -ne 0) {
            Write-PyenvError ":: [Error] :: error installing pip."
        }
    }

    return 0
}

function Install-PythonZip {
    param(
        [string]$ZipPath,
        [string]$InstallPath,
        [string]$ZipRootDir
    )

    if (Test-Path $InstallPath) { return 1 }

    if ([string]::IsNullOrEmpty($ZipRootDir)) {
        Expand-Archive -Path $ZipPath -DestinationPath $InstallPath -Force
    }
    else {
        $parentDir = Split-Path $InstallPath -Parent
        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }
        Expand-Archive -Path $ZipPath -DestinationPath $parentDir -Force
        $extractedDir = Join-Path $parentDir $ZipRootDir
        if (Test-Path $extractedDir) {
            Rename-Item $extractedDir $InstallPath
        }
    }

    return 0
}

function New-PythonAliases {
    param(
        [string]$InstallPath,
        [string]$VersionCode
    )

    $parts = $VersionCode -split '\.'
    $major = $parts[0]
    $minor = if ($parts.Count -gt 1) { $parts[1] -replace '[^0-9].*$', '' } else { '' }
    $majorMinor = "$major$minor"
    $majorDotMinor = "$major.$minor"

    $pythonExe = Join-Path $InstallPath 'python.exe'
    $pythonwExe = Join-Path $InstallPath 'pythonw.exe'

    if (Test-Path $pythonExe) {
        Copy-Item $pythonExe (Join-Path $InstallPath "python$major.exe") -Force
        if ($minor) {
            Copy-Item $pythonExe (Join-Path $InstallPath "python$majorMinor.exe") -Force
            Copy-Item $pythonExe (Join-Path $InstallPath "python$majorDotMinor.exe") -Force
        }
    }

    if (Test-Path $pythonwExe) {
        Copy-Item $pythonwExe (Join-Path $InstallPath "pythonw$major.exe") -Force
        if ($minor) {
            Copy-Item $pythonwExe (Join-Path $InstallPath "pythonw$majorMinor.exe") -Force
            Copy-Item $pythonwExe (Join-Path $InstallPath "pythonw$majorDotMinor.exe") -Force
        }
    }

    # venv launcher aliases
    $venvLauncher = Join-Path $InstallPath 'Lib' 'venv' 'scripts' 'nt' 'python.exe'
    if (Test-Path $venvLauncher) {
        $venvDir = Split-Path $venvLauncher -Parent
        Copy-Item $venvLauncher (Join-Path $venvDir "python$major.exe") -Force
        if ($minor) {
            Copy-Item $venvLauncher (Join-Path $venvDir "python$majorMinor.exe") -Force
            Copy-Item $venvLauncher (Join-Path $venvDir "python$majorDotMinor.exe") -Force
            Copy-Item $venvLauncher (Join-Path $venvDir "pythonw$major.exe") -Force
            Copy-Item $venvLauncher (Join-Path $venvDir "pythonw$majorMinor.exe") -Force
            Copy-Item $venvLauncher (Join-Path $venvDir "pythonw$majorDotMinor.exe") -Force
        }
    }
}

function Clear-InstallArtifacts {
    param(
        [string]$InstallPath,
        [string]$InstallFile
    )

    if (Test-Path $InstallPath -PathType Container) {
        Remove-Item $InstallPath -Recurse -Force
    }
    if (Test-Path $InstallFile) {
        Remove-Item $InstallFile -Force
    }
}

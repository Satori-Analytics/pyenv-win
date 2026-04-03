#Requires -Version 7
# pyenv-win registry library
# Windows registry operations for PEP 514 py launcher compatibility

function Register-PythonVersion {
    param(
        [string]$Version,
        [string]$InstallPath
    )

    # Registration requires 64-bit process
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($arch -eq 'x86') {
        Write-PyenvWarn "Python registration not supported in 32 bits"
        return
    }

    if ($Version -match 'pypy') {
        Write-PyenvWarn "Registering pypy versions is not supported yet"
        return
    }

    $pythonExe = Join-Path $InstallPath 'python.exe'
    if (-not (Test-Path $pythonExe)) { return }

    $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($pythonExe)
    $major = $fileVersion.FileMajorPart
    $minor = $fileVersion.FileMinorPart
    $build = $fileVersion.FileBuildPart
    $sysVersion = "$major.$minor"
    $featureVersion = "$major.$minor.$build.0"

    if ($Version -match '-win32$') {
        $bitDepth = '32'
        $versionAttribute = $Version -replace '-win32$', ''
    }
    else {
        $bitDepth = '64'
        $versionAttribute = $Version
    }

    $baseKey = "HKCU:\SOFTWARE\Python\PythonCore\$Version"

    # Create version key with metadata
    New-Item -Path $baseKey -Force | Out-Null
    Set-ItemProperty -Path $baseKey -Name 'DisplayName' -Value "Python $sysVersion ($bitDepth-bit)"
    Set-ItemProperty -Path $baseKey -Name 'SupportUrl' -Value 'https://github.com/satori-analytics/pyenv-win/issues'
    Set-ItemProperty -Path $baseKey -Name 'SysArchitecture' -Value "${bitDepth}bit"
    Set-ItemProperty -Path $baseKey -Name 'SysVersion' -Value $sysVersion
    Set-ItemProperty -Path $baseKey -Name 'Version' -Value $versionAttribute

    # Installed features
    $featuresKey = "$baseKey\InstalledFeatures"
    New-Item -Path $featuresKey -Force | Out-Null
    foreach ($feature in @('dev', 'exe', 'lib', 'pip', 'tools')) {
        Set-ItemProperty -Path $featuresKey -Name $feature -Value $featureVersion
    }

    # Install path
    $installKey = "$baseKey\InstallPath"
    New-Item -Path $installKey -Force | Out-Null
    Set-ItemProperty -Path $installKey -Name '(default)' -Value "$InstallPath\"
    Set-ItemProperty -Path $installKey -Name 'ExecutablePath' -Value (Join-Path $InstallPath 'python.exe')
    Set-ItemProperty -Path $installKey -Name 'WindowedExecutablePath' -Value (Join-Path $InstallPath 'pythonw.exe')

    # Python path
    $pythonPathKey = "$baseKey\PythonPath"
    New-Item -Path $pythonPathKey -Force | Out-Null
    $libPath = Join-Path $InstallPath 'Lib'
    $dllsPath = Join-Path $InstallPath 'DLLs'
    Set-ItemProperty -Path $pythonPathKey -Name '(default)' -Value "$libPath;$dllsPath"
}

function Unregister-PythonVersion {
    param([string]$Version)

    $baseKey = "HKCU:\SOFTWARE\Python\PythonCore\$Version"

    if (Test-Path $baseKey) {
        Remove-Item $baseKey -Recurse -Force -ErrorAction SilentlyContinue
    }
}

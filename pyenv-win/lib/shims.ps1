#Requires -Version 7
# pyenv-win shims library
# Rehash, shim generation (.bat/.sh stubs)

function Invoke-Rehash {
    # Ensure shims directory exists
    if (-not (Test-Path $script:PyenvShims)) {
        New-Item -ItemType Directory -Path $script:PyenvShims -Force | Out-Null
    }

    # Clear all existing shims
    Get-ChildItem $script:PyenvShims -File | Remove-Item -Force

    $exts = Get-PyenvExtensionsNoPeriod -AddPy

    foreach ($version in (Get-InstalledVersions)) {
        $versionDir = Join-Path $script:PyenvVersions $version

        # Scan the version root plus \Scripts and \bin. Every runnable file
        # (extension in $exts) gets a .bat + shell shim, regardless of location
        # or extension, so console-scripts like pip are always CLI-runnable.
        foreach ($dir in @($versionDir, (Join-Path $versionDir 'Scripts'), (Join-Path $versionDir 'bin'))) {
            if (-not (Test-Path $dir)) { continue }
            Get-ChildItem $dir -File -ErrorAction SilentlyContinue | ForEach-Object {
                $ext = $_.Extension.TrimStart('.').ToLower()
                if (-not $exts.ContainsKey($ext)) { return }
                try {
                    New-BatchShim -BaseName $_.BaseName
                    New-ShellShim -BaseName $_.BaseName
                }
                catch {
                    Write-PyenvWarn "Failed to create shim for '$($_.BaseName)': $_"
                }
            }
        }
    }
}

function New-BatchShim {
    param([string]$BaseName)

    $batPath = Join-Path $script:PyenvShims "$BaseName.bat"
    if (Test-Path $batPath) { return }

    $lines = @('@echo off', 'chcp 1250 > NUL', 'call pyenv exec %~n0 %*')
    if ($BaseName -like 'pip*') {
        $lines += 'call pyenv rehash'
    }

    [System.IO.File]::WriteAllLines($batPath, $lines, [System.Text.Encoding]::ASCII)
}

function New-ShellShim {
    param([string]$BaseName)

    $shPath = Join-Path $script:PyenvShims $BaseName
    if (Test-Path $shPath) { return }

    $lines = @('#!/bin/sh', 'pyenv exec $(basename "$0") "$@"')
    if ($BaseName -like 'pip*') {
        $lines += 'pyenv rehash'
    }

    # Write with LF line endings for Unix compatibility
    $content = ($lines -join "`n") + "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    [System.IO.File]::WriteAllBytes($shPath, $bytes)
}

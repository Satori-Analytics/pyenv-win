#Requires -Version 7
# pyenv-win shims library
# Rehash, shim generation (.bat/.lnk/.sh stubs)

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

        # Scan version root directory
        if (Test-Path $versionDir) {
            Get-ChildItem $versionDir -File -ErrorAction SilentlyContinue | ForEach-Object {
                $ext = $_.Extension.TrimStart('.').ToLower()
                if ($exts.ContainsKey($ext)) {
                    $baseName = $_.BaseName
                    if ($ext -ne 'exe') {
                        New-ShortcutShim -BaseName $baseName -TargetPath $_.FullName
                        New-BatchShim -BaseName $baseName
                        New-ShellShim -BaseName $baseName
                    }
                    else {
                        New-BatchShim -BaseName $baseName
                        New-ShellShim -BaseName $baseName
                    }
                }
            }
        }

        # Scan \Scripts and \bin subdirectories
        foreach ($subDir in @('Scripts', 'bin')) {
            $subPath = Join-Path $versionDir $subDir
            if (Test-Path $subPath) {
                Get-ChildItem $subPath -File -ErrorAction SilentlyContinue | ForEach-Object {
                    $ext = $_.Extension.TrimStart('.').ToLower()
                    if ($exts.ContainsKey($ext)) {
                        $baseName = $_.BaseName
                        if ($ext -ne 'exe') {
                            New-ShortcutShim -BaseName $baseName -TargetPath $_.FullName
                        }
                        else {
                            New-BatchShim -BaseName $baseName
                            New-ShellShim -BaseName $baseName
                        }
                    }
                }
            }
        }
    }
}

function New-ShortcutShim {
    param(
        [string]$BaseName,
        [string]$TargetPath
    )

    $linkPath = Join-Path $script:PyenvShims "$BaseName.lnk"
    if (Test-Path $linkPath) { return }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($linkPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Description = $BaseName
    $shortcut.IconLocation = "$TargetPath, 2"
    $shortcut.WindowStyle = 1
    $shortcut.WorkingDirectory = Split-Path $TargetPath -Parent
    $shortcut.Save()
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

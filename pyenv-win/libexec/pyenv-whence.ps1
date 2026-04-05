#Requires -Version 7
# pyenv whence: List all Python versions that contain the given executable
param()

if ($args.Count -eq 0 -or $args[0] -eq '' -or ($args.Count -eq 1 -and $args[0] -eq '--path')) {
    if ($args -contains '--help') {
        Write-Output "Usage: pyenv whence [--path] <command>"
        Write-Output ""
        Write-Output "Shows the currently given executable contains path"
        Write-Output "selected. To obtain python version of executable, use 'pyenv whence pip'."
        exit 0
    }
    Write-Output "Usage: pyenv whence [--path] <command>"
    Write-Output ""
    Write-Output "Shows the currently given executable contains path"
    Write-Output "selected. To obtain python version of executable, use 'pyenv whence pip'."
    exit 1
}

$isPath = $false
$program = ''

if ($args[0] -eq '--help') {
    Write-Output "Usage: pyenv whence [--path] <command>"
    Write-Output ""
    Write-Output "Shows the currently given executable contains path"
    Write-Output "selected. To obtain python version of executable, use 'pyenv whence pip'."
    exit 0
}

if ($args[0] -eq '--path') {
    $isPath = $true
    if ($args.Count -lt 2 -or $args[1] -eq '') {
        Write-Output "Usage: pyenv whence [--path] <command>"
        exit 1
    }
    $program = $args[1]
}
else {
    $program = $args[0]
}

if ($program.EndsWith('.')) { $program = $program.TrimEnd('.') }

$exts = Get-PyenvExtensions -AddPy
$foundAny = $false

foreach ($dir in (Get-ChildItem $script:PyenvVersions -Directory -ErrorAction SilentlyContinue)) {
    $found = $false

    # Check root directory
    $candidate = Join-Path $dir.FullName $program
    if (Test-Path $candidate) {
        $found = $true
        $foundAny = $true
        if ($isPath) {
            Write-Output (Resolve-Path $candidate).Path
        }
        else {
            Write-Output $dir.Name
        }
    }

    if (-not $found -or $isPath) {
        foreach ($ext in $exts.Keys) {
            $candidate = Join-Path $dir.FullName "$program$ext"
            if (Test-Path $candidate) {
                $found = $true
                $foundAny = $true
                if ($isPath) {
                    Write-Output (Resolve-Path $candidate).Path
                }
                else {
                    Write-Output $dir.Name
                }
                break
            }
        }
    }

    # Check \Scripts and \bin subdirectories
    foreach ($subDir in @('Scripts', 'bin')) {
        $subPath = Join-Path $dir.FullName $subDir
        if ((-not $found -or $isPath) -and (Test-Path $subPath -PathType Container)) {
            $candidate = Join-Path $subPath $program
            if (Test-Path $candidate) {
                $found = $true
                $foundAny = $true
                if ($isPath) {
                    Write-Output (Resolve-Path $candidate).Path
                }
                else {
                    Write-Output $dir.Name
                }
            }
        }

        if ((-not $found -or $isPath) -and (Test-Path $subPath -PathType Container)) {
            foreach ($ext in $exts.Keys) {
                $candidate = Join-Path $subPath "$program$ext"
                if (Test-Path $candidate) {
                    $foundAny = $true
                    if ($isPath) {
                        Write-Output (Resolve-Path $candidate).Path
                    }
                    else {
                        Write-Output $dir.Name
                    }
                    break
                }
            }
        }
    }
}

if (-not $foundAny) { exit 1 }

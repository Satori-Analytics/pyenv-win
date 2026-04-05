#Requires -Version 7
# pyenv uninstall: Uninstall Python versions
param()

function Show-UninstallHelp {
    Write-Output "Usage: pyenv uninstall [-f|--force] <version> [<version> ...]"
    Write-Output "       pyenv uninstall [-f|--force] [-a|--all]"
    Write-Output ""
    Write-Output "   -f/--force  Attempt to remove the specified version without prompting"
    Write-Output "               for confirmation. If the version does not exist, do not"
    Write-Output "               display an error message."
    Write-Output ""
    Write-Output "   -a/--all    *Caution* Attempt to remove all installed versions."
    Write-Output ""
    Write-Output "See 'pyenv versions' for a complete list of installed versions."
    exit 0
}

if ($args.Count -eq 0) { Show-UninstallHelp }

$optForce = $false
$optAll = $false
$uninstallVersions = [ordered]@{}

foreach ($arg in $args) {
    switch ($arg) {
        '--help' { Show-UninstallHelp }
        '-f' { $optForce = $true }
        '--force' { $optForce = $true }
        '-a' { $optAll = $true }
        '--all' { $optAll = $true }
        default {
            if (-not (Test-IsVersion $arg)) {
                Write-Output "pyenv: Unrecognized python version: $arg"
                exit 1
            }
            $uninstallVersions[$arg] = $true
        }
    }
}

if (-not (Test-Path $script:PyenvVersions -PathType Container) -or
    (Get-ChildItem $script:PyenvVersions -Directory).Count -eq 0) {
    Write-Output "pyenv: No valid versions of python installed."
    exit 1
}

if ($optAll) {
    if (-not $optForce) {
        $confirm = Read-Host "pyenv: Confirm uninstall all? (Y/N)"
        if ($confirm.ToLower() -ne 'y') { exit 0 }
    }

    $uninstallVersions = [ordered]@{}
    Get-ChildItem $script:PyenvVersions -Directory | ForEach-Object {
        if (Test-IsVersion $_.Name) {
            $uninstallVersions[$_.Name] = $true
        }
    }
}

# Single version check
if ($uninstallVersions.Count -eq 1) {
    $singleVer = @($uninstallVersions.Keys)[0]
    $singlePath = Join-Path $script:PyenvVersions $singleVer
    if (-not (Test-Path $singlePath -PathType Container)) {
        Write-Output "pyenv: version '$singleVer' not installed"
        exit 0
    }
}

$uninstalled = @{}
$delError = 0

foreach ($folder in @($uninstallVersions.Keys)) {

    if ($uninstalled.ContainsKey($folder)) { continue }

    $uninstallPath = Join-Path $script:PyenvVersions $folder
    if ((Test-IsVersion $folder) -and (Test-Path $uninstallPath -PathType Container)) {
        try {
            Remove-Item $uninstallPath -Recurse -Force:$optForce
            Unregister-PythonVersion -Version $folder
            Write-Output "pyenv: Successfully uninstalled $folder"
            $uninstalled[$folder] = $true
        }
        catch {
            Write-Output "pyenv: Error uninstalling version ${folder}: $_"
            $delError = 1
        }
    }
}

if ($delError -eq 0) { Invoke-Rehash }

exit $delError

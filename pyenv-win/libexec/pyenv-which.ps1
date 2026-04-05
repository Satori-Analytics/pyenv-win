#Requires -Version 7
# pyenv which: Display the full path to an executable
param()

if ($args.Count -eq 0 -or $args[0] -eq '' -or $args -contains '--help') {
    Write-Output "Usage: pyenv which <command>"
    Write-Output ""
    Write-Output "Shows the full path of the executable"
    Write-Output "selected. To obtain the full path, use 'pyenv which pip'."
    if ($args -contains '--help') { exit 0 }
    exit 1
}

$program = $args[0]
if ($program.EndsWith('.')) { $program = $program.TrimEnd('.') }

$exts = Get-PyenvExtensions -AddPy

$versions = Get-CurrentVersions
foreach ($version in $versions.Keys) {
    $versionDir = Join-Path $script:PyenvVersions $version

    if (-not (Test-Path $versionDir -PathType Container)) {
        Write-Output "pyenv: version '$version' is not installed (set by $version)"
        exit 1
    }

    # Check root directory
    $candidate = Join-Path $versionDir $program
    if (Test-Path $candidate) {
        Write-Output (Resolve-Path $candidate).Path
        exit 0
    }
    foreach ($ext in $exts.Keys) {
        $candidate = Join-Path $versionDir "$program$ext"
        if (Test-Path $candidate) {
            Write-Output (Resolve-Path $candidate).Path
            exit 0
        }
    }

    # Check \Scripts and \bin subdirectories
    foreach ($subDir in @('Scripts', 'bin')) {
        $subPath = Join-Path $versionDir $subDir
        if (Test-Path $subPath -PathType Container) {
            $candidate = Join-Path $subPath $program
            if (Test-Path $candidate) {
                Write-Output (Resolve-Path $candidate).Path
                exit 0
            }
            foreach ($ext in $exts.Keys) {
                $candidate = Join-Path $subPath "$program$ext"
                if (Test-Path $candidate) {
                    Write-Output (Resolve-Path $candidate).Path
                    exit 0
                }
            }
        }
    }
}

Write-Output "pyenv: $($args[0]): command not found"

# Check if the command exists in other versions
$whenceOutput = @()
foreach ($dir in (Get-ChildItem $script:PyenvVersions -Directory -ErrorAction SilentlyContinue)) {
    $found = $false
    $searchDirs = @($dir.FullName)
    $scriptsDir = Join-Path $dir.FullName 'Scripts'
    $binDir = Join-Path $dir.FullName 'bin'
    if (Test-Path $scriptsDir) { $searchDirs += $scriptsDir }
    if (Test-Path $binDir) { $searchDirs += $binDir }

    foreach ($searchDir in $searchDirs) {
        if ($found) { break }
        $candidate = Join-Path $searchDir $program
        if (Test-Path $candidate) { $found = $true; break }
        foreach ($ext in $exts.Keys) {
            if (Test-Path (Join-Path $searchDir "$program$ext")) { $found = $true; break }
        }
    }

    if ($found) { $whenceOutput += $dir.Name }
}

if ($whenceOutput.Count -gt 0) {
    Write-Output ""
    Write-Output "The '$($args[0])' command exists in these Python versions:"
    foreach ($v in $whenceOutput) {
        Write-Output "  $v"
    }
    Write-Output "  "
}

exit 127

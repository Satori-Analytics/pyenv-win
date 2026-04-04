#Requires -Version 7
# pyenv latest: Print the latest installed or known version with the given prefix
param()

$optKnown = $false
$optQuiet = $false
$optPrefix = ''

foreach ($arg in $args) {
    switch ($arg) {
        '--help' { 
            Write-Output "Usage: pyenv latest [-k|--known] [-q|--quiet] <prefix>"
            Write-Output ""
            Write-Output "  -k/--known      Select from all known versions instead of installed"
            Write-Output "  -q/--quiet      Do not print an error message on resolution failure"
            exit 0
        }
        '-k' { $optKnown = $true }
        '--known' { $optKnown = $true }
        '-q' { $optQuiet = $true }
        '--quiet' { $optQuiet = $true }
        default { $optPrefix = $arg }
    }
}

if ($args.Count -eq 0) {
    if (-not $optQuiet) {
        Write-Output "Usage: pyenv latest [-k|--known] [-q|--quiet] <prefix>"
    }
    exit 1
}

if ($optPrefix -eq '') {
    if (-not $optQuiet) {
        Write-Output "pyenv-latest: missing <prefix> argument"
    }
    exit 1
}

$latest = Find-LatestVersion -Prefix $optPrefix -Known:$optKnown

if ($latest -ne '') {
    Write-Output $latest
}
else {
    if (-not $optQuiet) {
        if ($optKnown) {
            Write-Output "pyenv-latest: no known versions match the prefix '$optPrefix'."
        }
        else {
            Write-Output "pyenv-latest: no installed versions match the prefix '$optPrefix'."
        }
    }
    exit 1
}

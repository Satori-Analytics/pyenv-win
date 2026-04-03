#Requires -Version 7
# pyenv-win main dispatcher
# Routes subcommands to libexec/pyenv-*.ps1 scripts

$ErrorActionPreference = 'Stop'
$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Dot-source libraries (load order matters: core first, then deps)
. "$PSScriptRoot\..\lib\core.ps1"
. "$PSScriptRoot\..\lib\getopt.ps1"
. "$PSScriptRoot\..\lib\versions-db.ps1"
. "$PSScriptRoot\..\lib\versions.ps1"
. "$PSScriptRoot\..\lib\shims.ps1"
. "$PSScriptRoot\..\lib\install.ps1"
. "$PSScriptRoot\..\lib\registry.ps1"

# Command discovery: find all pyenv-*.ps1 in libexec/
function Get-PyenvCommands {
    $cmds = @{}
    Get-ChildItem "$script:PyenvLibexec" -Filter 'pyenv-*.ps1' -File | ForEach-Object {
        $name = $_.BaseName -replace '^pyenv-', ''
        $cmds[$name] = $_.FullName
    }
    return $cmds
}

# Extract subcommand and remaining args
$subCommand = $Args[0]
[string[]]$subArgs = @()
if ($Args.Count -gt 1) {
    $subArgs = @($Args[1..($Args.Count - 1)])
}

# Route commands
switch ($subCommand) {
    # No args
    { $_ -in @($null, '/?') } {
        . "$script:PyenvLibexec\pyenv-help.ps1"
        break
    }

    # Help flag or help command — route to specific command if given
    { $_ -in @('-h', '--help', 'help') } {
        if ($subArgs.Count -gt 0) {
            $commands = Get-PyenvCommands
            $helpTarget = $subArgs[0]
            if ($commands.ContainsKey($helpTarget)) {
                . $commands[$helpTarget] '--help'
                exit $LASTEXITCODE
            }
        }
        . "$script:PyenvLibexec\pyenv-help.ps1"
        break
    }

    # Version flag
    { $_ -in @('-v', '--version') } {
        . "$script:PyenvLibexec\pyenv---version.ps1"
        break
    }

    # Shell command — special handling for env var propagation
    'shell' {
        . "$script:PyenvLibexec\pyenv-shell.ps1" @subArgs
        break
    }

    # Exec command — special handling for PATH manipulation
    'exec' {
        if ($subArgs.Count -gt 0 -and $subArgs[0] -in @('--help', '-h')) {
            . "$script:PyenvLibexec\pyenv-exec.ps1"
            break
        }

        if ($subArgs.Count -eq 0) {
            Write-Output "Usage: pyenv exec <command> [args...]"
            exit 1
        }

        $versions = Get-CurrentVersions
        $extraPaths = @()

        foreach ($ver in $versions.Keys) {
            $verDir = Join-Path $script:PyenvVersions $ver
            if (Test-Path $verDir) {
                $extraPaths += $verDir
                $scriptsDir = Join-Path $verDir 'Scripts'
                $binDir = Join-Path $verDir 'bin'
                if (Test-Path $scriptsDir) { $extraPaths += $scriptsDir }
                if (Test-Path $binDir) { $extraPaths += $binDir }

                # Add AppData Python Scripts path
                if ($ver -match '^(\d+)\.(\d+)') {
                    $major = $Matches[1]
                    $minor = $Matches[2]
                }
                else {
                    continue
                }
                if ($ver -match '-win32$') {
                    $appDataScripts = Join-Path $env:APPDATA "Python\Python$major$minor-32\Scripts"
                }
                else {
                    $appDataScripts = Join-Path $env:APPDATA "Python\Python$major$minor\Scripts"
                }
                if (Test-Path $appDataScripts) { $extraPaths += $appDataScripts }
            }
        }

        # Build new PATH: version dirs first, then original PATH minus shims
        $shimsNorm = (Resolve-Path $script:PyenvShims -ErrorAction SilentlyContinue).Path
        $currentPath = ($env:PATH -split ';') | Where-Object {
            $p = $_.TrimEnd('\', '/')
            if ([string]::IsNullOrWhiteSpace($p)) { return $false }
            if ($shimsNorm -and $p -ieq $shimsNorm) { return $false }
            return $true
        }

        $savedPath = $env:PATH
        try {
            $env:PATH = (($extraPaths + $currentPath) -join ';')

            $execCmd = $subArgs[0]
            [string[]]$execArgs = @()
            if ($subArgs.Count -gt 1) {
                $execArgs = @($subArgs[1..($subArgs.Count - 1)])
            }
            & $execCmd @execArgs
            exit $LASTEXITCODE
        }
        finally {
            $env:PATH = $savedPath
        }
    }

    # All other commands — look up in libexec/
    default {
        $commands = Get-PyenvCommands
        if ($commands.ContainsKey($subCommand)) {
            . $commands[$subCommand] @subArgs
            exit $LASTEXITCODE
        }

        Write-PyenvError "pyenv: no such command '$subCommand'"
        exit 1
    }
}

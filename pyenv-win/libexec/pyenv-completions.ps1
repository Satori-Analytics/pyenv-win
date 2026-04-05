#Requires -Version 7
# pyenv completions: List available completions for a given pyenv command
param()

if ($args.Count -eq 0) {
    Write-Output "Usage: pyenv completions <command>"
    Write-Output ""
    Write-Output "Lists available completions for a given pyenv command."
    exit 1
}

$command = $args[0]

if ($command -eq '--help') {
    Write-Output "Usage: pyenv completions <command>"
    Write-Output ""
    Write-Output "Lists available completions for a given pyenv command."
    exit 0
}

# Meta-completion: list all command names
if ($command -eq '--complete') {
    $cmds = Get-PyenvCommands
    $cmds.Keys | Sort-Object | ForEach-Object { Write-Output $_ }
    exit 0
}

# Verify the command exists
$scriptPath = Join-Path $script:PyenvLibexec "pyenv-$command.ps1"
if (-not (Test-Path $scriptPath)) {
    exit 1
}

# Always provide --help
Write-Output '--help'

# Command-specific flags
switch ($command) {
    'cache' { '--clear'; '--sync' }
    'global' { '--unset' }
    'install' { '--list'; '--all'; '--clear'; '--force'; '--skip-existing'; '--register'; '--quiet'; '--32only'; '--64only'; '--dev' }
    'latest' { '--known'; '--quiet' }
    'local' { '--unset' }
    'shell' { '--unset' }
    'shims' { '--short' }
    'uninstall' { '--force'; '--all' }
    'version' { '--bare' }
    'versions' { '--bare' }
    'whence' { '--path' }
}

# Commands that accept installed version names
if ($command -in @('global', 'local', 'prefix', 'shell', 'uninstall')) {
    if (Test-Path $script:PyenvVersions) {
        Get-ChildItem $script:PyenvVersions -Directory | ForEach-Object { Write-Output $_.Name }
    }
}

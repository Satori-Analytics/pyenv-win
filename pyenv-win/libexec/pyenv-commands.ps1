#Requires -Version 7
# pyenv commands: List all available pyenv commands
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv commands"
    Write-Output ""
    Write-Output "List all available pyenv commands"
    exit 0
}

$commands = Get-PyenvCommands
foreach ($cmd in ($commands.Keys | Sort-Object)) {
    Write-Output $cmd
}

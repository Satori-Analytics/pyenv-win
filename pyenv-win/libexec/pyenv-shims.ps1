#Requires -Version 7
# pyenv shims: List shim scripts
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv shims [--short]"
    Write-Output ""
    Write-Output "List existing pyenv shims"
    exit 0
}

if (-not (Test-Path $script:PyenvShims)) { exit 0 }

if ($args -contains '--short') {
    Get-ChildItem $script:PyenvShims -File | ForEach-Object { Write-Output $_.Name }
}
else {
    Get-ChildItem $script:PyenvShims -File -Recurse | ForEach-Object { Write-Output $_.FullName }
}

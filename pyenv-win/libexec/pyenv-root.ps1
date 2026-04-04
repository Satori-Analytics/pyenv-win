#Requires -Version 7
# pyenv root: Display the root directory where versions and shims are kept
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv root"
    Write-Output ""
    Write-Output "Displays the root directory where versions and shims are kept."
    exit 0
}

Write-Output $script:PyenvRoot

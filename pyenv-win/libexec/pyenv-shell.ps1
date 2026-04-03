#Requires -Version 7
# pyenv shell: Set or show the shell-specific Python version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv shell <version>"
    Write-Output "       pyenv shell --unset"
    Write-Output ""
    Write-Output "Sets a shell-specific Python version by setting the ``PYENV_VERSION'"
    Write-Output "environment variable in your shell. This version overrides local"
    Write-Output "application-specific versions and the global version."
    exit 0
}

if ($args.Count -eq 0) {
    if ([string]::IsNullOrEmpty($env:PYENV_VERSION)) {
        Write-Output "no shell-specific version configured"
    }
    else {
        Write-Output $env:PYENV_VERSION
    }
}
elseif ($args[0] -eq '--unset') {
    if (Test-Path Env:PYENV_VERSION) {
        Remove-Item Env:PYENV_VERSION
    }
}
else {
    # Validate all versions exist
    $shellVersions = @()
    foreach ($ver in $args) {
        $resolved = Resolve-32Bit $ver
        $dir = Join-Path $script:PyenvVersions $resolved
        if (-not (Test-IsVersion $resolved) -or -not (Test-Path $dir -PathType Container)) {
            Write-Output "pyenv specific python requisite didn't meet. Project is using different version of python."
            Write-Output "Install python '$resolved' by typing: 'pyenv install $resolved'"
            exit 1
        }
        $shellVersions += $resolved
    }

    $env:PYENV_VERSION = $shellVersions -join ' '
}

#Requires -Version 7
# pyenv global: Set or show the global Python version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv global <version>"
    Write-Output "       pyenv global --unset"
    Write-Output ""
    Write-Output "Sets the global Python version. You can override the global version at"
    Write-Output "any time by setting a directory-specific version with 'pyenv local'"
    Write-Output "or by setting the PYENV_VERSION environment variable."
    exit 0
}

if ($args.Count -eq 0) {
    $currentVersions = Get-CurrentVersionsGlobal
    if ($null -eq $currentVersions) {
        Write-Output "no global version configured"
    }
    else {
        foreach ($v in $currentVersions) {
            Write-Output $v[0]
        }
    }
}
else {
    if ($args[0] -eq '--unset') {
        $globalFile = Join-Path $script:PyenvHome 'version'
        if (Test-Path $globalFile) { Remove-Item $globalFile -Force }
        return
    }

    # Validate all versions exist
    $globalVersions = @()
    foreach ($ver in $args) {
        $resolved = Resolve-VersionPrefix -Prefix $ver -Known:$false
        $dir = Join-Path $script:PyenvVersions $resolved
        if (-not (Test-IsVersion $resolved) -or -not (Test-Path $dir -PathType Container)) {
            Write-Output "pyenv specific python requisite didn't meet. Project is using different version of python."
            Write-Output "Install python '$ver' by typing: 'pyenv install $ver'"
            exit 1
        }
        $globalVersions += $ver
    }

    # Write version file
    $globalFile = Join-Path $script:PyenvHome 'version'
    $globalVersions | Set-Content $globalFile
}

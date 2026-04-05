#Requires -Version 7
# pyenv local: Set or show the local application-specific Python version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv local <version> <version2> <..>"
    Write-Output "       pyenv local --unset"
    Write-Output ""
    Write-Output "Sets the local application-specific Python version by writing the"
    Write-Output "version name to a file named .python-version."
    Write-Output ""
    Write-Output "When you run a Python command, pyenv will look for a .python-version"
    Write-Output "file in the current directory and each parent directory. If no such"
    Write-Output "file is found in the tree, pyenv will use the global Python version"
    Write-Output "specified with 'pyenv global'. A version specified with the"
    Write-Output "PYENV_VERSION environment variable takes precedence over local"
    Write-Output "and global versions."
    Write-Output ""
    Write-Output "<version> can be specified multiple times and should be a version"
    Write-Output "tag known to pyenv. The special version string 'system' will use"
    Write-Output "your default system Python. Run 'pyenv versions' for a list of"
    Write-Output "available Python versions."
    Write-Output ""
    Write-Output "Example: To enable the python2.7 and python3.7 shims to find their"
    Write-Output "         respective executables you could set both versions with:"
    Write-Output ""
    Write-Output "'pyenv local 3.10.0 3.9.5'"
    exit 0
}

$currentDir = (Get-Location).Path

if ($args.Count -eq 0) {
    $currentVersions = Get-CurrentVersionsLocal -SearchPath $currentDir
    if ($null -eq $currentVersions) {
        Write-Output "no local version configured for this directory"
    }
    else {
        foreach ($v in $currentVersions) {
            Write-Output $v[0]
        }
    }
}
else {
    if ($args[0] -eq '--unset') {
        $versionFile = Join-Path $currentDir $script:PyenvVersionFile
        if (Test-Path $versionFile) { Remove-Item $versionFile -Force }
        return
    }

    # Validate all versions exist
    $localVersions = @()
    foreach ($ver in $args) {
        $resolved = Resolve-VersionPrefix -Prefix $ver -Known:$false
        $dir = Join-Path $script:PyenvVersions $resolved
        if (-not (Test-IsVersion $resolved) -or -not (Test-Path $dir -PathType Container)) {
            Write-Output "pyenv specific python requisite didn't meet. Project is using different version of python."
            Write-Output "Install python '$ver' by typing: 'pyenv install $ver'"
            exit 1
        }
        $localVersions += $ver
    }

    # Write version file
    $versionFile = Join-Path $currentDir $script:PyenvVersionFile
    $localVersions | Set-Content $versionFile
}

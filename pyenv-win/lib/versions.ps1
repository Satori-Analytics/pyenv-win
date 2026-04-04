#Requires -Version 7
# pyenv-win version resolution library
# Shell → Local → Global version precedence

function Get-CurrentVersionsGlobal {
    $fname = Join-Path $script:PyenvHome 'version'
    if (-not (Test-Path $fname)) { return $null }

    $versions = @()
    foreach ($line in (Get-Content $fname)) {
        $line = $line.Trim()
        if ($line -ne '') {
            $versions += , @($line, $fname)
        }
    }

    if ($versions.Count -gt 0) { return , $versions }
    return $null
}

function Get-CurrentVersionsLocal {
    param([string]$SearchPath)

    if ([string]::IsNullOrEmpty($SearchPath)) {
        $SearchPath = (Get-Location).Path
    }

    while ($SearchPath -ne '') {
        $fname = Join-Path $SearchPath $script:PyenvVersionFile
        if (Test-Path $fname) {
            $versions = @()
            foreach ($line in (Get-Content $fname)) {
                $line = $line.Trim()
                if ($line -ne '') {
                    $versions += , @($line, $fname)
                }
            }
            if ($versions.Count -gt 0) { return , $versions }
            break
        }
        $parent = Split-Path $SearchPath -Parent
        if ($parent -eq $SearchPath) { break }
        $SearchPath = $parent
    }

    return $null
}

function Get-CurrentVersionsShell {
    $pyenvVersion = $env:PYENV_VERSION
    if ([string]::IsNullOrWhiteSpace($pyenvVersion)) { return $null }

    $versions = @()
    foreach ($ver in ($pyenvVersion -split '\s+')) {
        if ($ver -ne '') {
            $versions += , @($ver, '%PYENV_VERSION%')
        }
    }

    if ($versions.Count -gt 0) { return , $versions }
    return $null
}

function Get-CurrentVersionsNoError {
    $versions = [ordered]@{}

    $str = Get-CurrentVersionsShell
    if ($null -ne $str) {
        foreach ($v in $str) {
            $versions[$v[0]] = $v[1]
        }
    }
    else {
        $str = Get-CurrentVersionsLocal
        if ($null -ne $str) {
            foreach ($v in $str) {
                $resolved = Resolve-VersionPrefix -Prefix $v[0] -Known:$false
                if ($resolved -eq '') { $resolved = $v[0] }
                $versions[$resolved] = $v[1]
            }
        }
    }

    if ($null -eq $str) {
        $str = Get-CurrentVersionsGlobal
        if ($null -ne $str) {
            foreach ($v in $str) {
                $resolved = Resolve-VersionPrefix -Prefix $v[0] -Known:$false
                if ($resolved -eq '') { $resolved = $v[0] }
                $versions[$resolved] = $v[1]
            }
        }
    }

    return $versions
}

function Get-CurrentVersions {
    $versions = Get-CurrentVersionsNoError
    if ($versions.Count -eq 0) {
        Write-Output "No global/local python version has been set yet. Please set the global/local version by typing:"
        Write-Output "pyenv global <python-version>"
        Write-Output "pyenv global 3.8.4"
        Write-Output "pyenv local <python-version>"
        Write-Output "pyenv local 3.8.4"
        exit 1
    }
    return $versions
}

function Get-CurrentVersionNoError {
    $shell = Get-CurrentVersionsShell
    if ($null -ne $shell) { return $shell[0] }

    $local_ = Get-CurrentVersionsLocal
    if ($null -ne $local_) { return $local_[0] }

    $global_ = Get-CurrentVersionsGlobal
    if ($null -ne $global_) { return $global_[0] }

    return $null
}

function Get-InstalledVersions {
    if (-not (Test-Path $script:PyenvVersions -PathType Container)) {
        return @()
    }
    return @(Get-ChildItem $script:PyenvVersions -Directory | ForEach-Object { $_.Name })
}

function Resolve-VersionPrefix {
    param(
        [string]$Prefix,
        [switch]$Known
    )

    # Delegates to Find-LatestVersion in versions-db.ps1
    $result = Find-LatestVersion -Prefix $Prefix -Known:$Known
    if ($result -eq '') { return $Prefix }
    return $result
}

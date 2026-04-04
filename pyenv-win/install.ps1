<#
    .SYNOPSIS
    Installs pyenv-win

    .DESCRIPTION
    Installs pyenv-win to $HOME\.pyenv
    If pyenv-win is already installed, try to update to the latest version.
    Requires PowerShell 7 or later.

    .PARAMETER Uninstall
    Uninstall pyenv-win. Note that this uninstalls any Python versions that were installed with pyenv-win.

    .INPUTS
    None.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> install.ps1

    .LINK
    Online version: https://pyenv-win.github.io/pyenv-win/
#>

#Requires -Version 7
    
param (
    [Switch] $Uninstall = $False
)
    
$PyEnvDir = "${env:USERPROFILE}\.pyenv"
$PyEnvWinDir = "${PyEnvDir}\pyenv-win"
$BinPath = "${PyEnvWinDir}\bin"
$ShimsPath = "${PyEnvWinDir}\shims"
    
Function Remove-PyEnvVars() {
    $PathParts = [System.Environment]::GetEnvironmentVariable('PATH', "User") -Split ";"
    $NewPathParts = $PathParts.Where{ $_ -ne $BinPath }.Where{ $_ -ne $ShimsPath }
    $NewPath = $NewPathParts -Join ";"
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, "User")

    [System.Environment]::SetEnvironmentVariable('PYENV', $null, "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_ROOT', $null, "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_HOME', $null, "User")
}

Function Remove-PyEnv() {
    Write-Host "Removing $PyEnvDir..."
    If (Test-Path $PyEnvDir) {
        Remove-Item -Path $PyEnvDir -Recurse
    }
    Write-Host "Removing environment variables..."
    Remove-PyEnvVars
}

Function Get-CurrentVersion() {
    $VersionFilePath = "$PyEnvDir\.version"
    If (Test-Path $VersionFilePath) {
        $CurrentVersion = Get-Content $VersionFilePath
    }
    Else {
        $CurrentVersion = ""
    }

    Return $CurrentVersion
}

Function Get-LatestVersion() {
    $LatestVersionFilePath = "$PyEnvDir\latest.version"
    (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/satori-analytics/pyenv-win/master/.version", $LatestVersionFilePath)
    $LatestVersion = Get-Content $LatestVersionFilePath

    Remove-Item -Path $LatestVersionFilePath

    Return $LatestVersion
}

Function Main() {
    # #Requires -Version 7 is bypassed when run via irm | iex, so check manually
    If ($PSVersionTable.PSVersion.Major -lt 7) {
        Write-Host "ERROR: pyenv-win 4.0+ requires PowerShell 7. Current version: $($PSVersionTable.PSVersion)"
        Write-Host "Install PowerShell 7: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows"
        exit 1
    }

    If ($Uninstall) {
        Remove-PyEnv
        If ($? -eq $True) {
            Write-Host "pyenv-win successfully uninstalled."
        }
        Else {
            Write-Host "Uninstallation failed."
        }
        exit
    }

    $BackupDir = "${env:Temp}/pyenv-win-backup"
    
    $CurrentVersion = Get-CurrentVersion
    If ($CurrentVersion) {
        Write-Host "pyenv-win $CurrentVersion installed."
        $LatestVersion = Get-LatestVersion
        If ($CurrentVersion -eq $LatestVersion) {
            Write-Host "No updates available."
            exit
        }
        Else {
            Write-Host "New version available: $LatestVersion. Updating..."
            
            If (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir | Out-Null
            }

            If (Test-Path "${PyEnvWinDir}/install_cache") {
                Write-Host "Backing up install cache..."
                Move-Item -Path "${PyEnvWinDir}/install_cache" -Destination $BackupDir
            }

            $VersionsDir = "${PyEnvWinDir}/versions"
            If (Test-Path $VersionsDir) {
                $Versions = Get-ChildItem -Directory $VersionsDir
                If ($Versions.Count -gt 0) {
                    New-Item -ItemType Directory -Path "$BackupDir/versions" | Out-Null
                    $i = 0
                    ForEach ($Ver in $Versions) {
                        $i++
                        $Pct = [int](($i / $Versions.Count) * 100)
                        Write-Progress -Activity "Backing up Python installations" -Status "Python $($Ver.Name)" -PercentComplete $Pct
                        Move-Item -Path $Ver.FullName -Destination "$BackupDir/versions"
                    }
                    Write-Progress -Activity "Backing up Python installations" -Completed
                }
            }
            
            Write-Host "Removing $PyEnvDir..."
            Remove-Item -Path $PyEnvDir -Recurse
        }   
    }

    New-Item -Path $PyEnvDir -ItemType Directory

    $DownloadPath = "$PyEnvDir\pyenv-win.zip"
    $fromMaster = $false

    try {
        (New-Object System.Net.WebClient).DownloadFile("https://github.com/satori-analytics/pyenv-win/releases/latest/download/pyenv-win.zip", $DownloadPath)
    }
    catch {
        Write-Host "Release zip not available, falling back to master..." -ForegroundColor Yellow
        try {
            (New-Object System.Net.WebClient).DownloadFile("https://github.com/satori-analytics/pyenv-win/archive/master.zip", $DownloadPath)
            $fromMaster = $true
        }
        catch {
            Write-Host "ERROR: Failed to download pyenv-win: $_" -ForegroundColor Red
            Write-Host "Check your internet connection or visit https://github.com/satori-analytics/pyenv-win"
            exit 1
        }
    }

    if (-not (Test-Path $DownloadPath) -or (Get-Item $DownloadPath).Length -eq 0) {
        Write-Host "ERROR: Download failed — file is missing or empty." -ForegroundColor Red
        exit 1
    }

    Expand-Archive -Path $DownloadPath -DestinationPath $PyEnvDir -Force

    if ($fromMaster) {
        Move-Item -Path "$PyEnvDir\pyenv-win-master\*" -Destination "$PyEnvDir"
        Remove-Item -Path "$PyEnvDir\pyenv-win-master" -Recurse
    }

    Remove-Item -Path $DownloadPath

    # Update env vars
    [System.Environment]::SetEnvironmentVariable('PYENV', "${PyEnvWinDir}\", "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_ROOT', "${PyEnvWinDir}\", "User")
    [System.Environment]::SetEnvironmentVariable('PYENV_HOME', "${PyEnvWinDir}\", "User")

    $PathParts = [System.Environment]::GetEnvironmentVariable('PATH', "User") -Split ";"

    # Remove existing paths, so we don't add duplicates
    $NewPathParts = $PathParts.Where{ $_ -ne $BinPath }.Where{ $_ -ne $ShimsPath }
    $NewPathParts = ($BinPath, $ShimsPath) + $NewPathParts
    $NewPath = $NewPathParts -Join ";"
    [System.Environment]::SetEnvironmentVariable('PATH', $NewPath, "User")

    If (Test-Path $BackupDir) {
        If (Test-Path "$BackupDir/install_cache") {
            Write-Host "Restoring install cache..."
            Move-Item -Path "$BackupDir/install_cache" -Destination $PyEnvWinDir
        }

        $BackupVersionsDir = "$BackupDir/versions"
        If (Test-Path $BackupVersionsDir) {
            $Versions = Get-ChildItem -Directory $BackupVersionsDir
            If ($Versions.Count -gt 0) {
                New-Item -ItemType Directory -Path "$PyEnvWinDir/versions" -ErrorAction SilentlyContinue | Out-Null
                $i = 0
                ForEach ($Ver in $Versions) {
                    $i++
                    $Pct = [int](($i / $Versions.Count) * 100)
                    Write-Progress -Activity "Restoring Python installations" -Status "Python $($Ver.Name)" -PercentComplete $Pct
                    Move-Item -Path $Ver.FullName -Destination "$PyEnvWinDir/versions"
                }
                Write-Progress -Activity "Restoring Python installations" -Completed
            }
        }

        Remove-Item -Path $BackupDir -Recurse -ErrorAction SilentlyContinue
    }

    # Regenerate shims for all installed versions
    $PyenvBin = Join-Path $PyEnvWinDir "bin\pyenv.ps1"
    If (Test-Path $PyenvBin) {
        Write-Host "Regenerating shims..."
        & pwsh -NoProfile -File $PyenvBin rehash

        Write-Host "Updating Python versions cache..."
        & pwsh -NoProfile -File $PyenvBin update
    }
    
    If ($? -eq $True) {
        Write-Host "pyenv-win is successfully installed. You may need to close and reopen your terminal before using it."
    }
    Else {
        Write-Host "pyenv-win was not installed successfully. If this issue persists, please open a ticket: https://github.com/satori-analytics/pyenv-win/issues."
    }
}

Main

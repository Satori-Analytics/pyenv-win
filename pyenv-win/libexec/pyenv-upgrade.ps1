#Requires -Version 7
# pyenv upgrade: Update pyenv-win itself to the latest version
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv upgrade"
    Write-Output ""
    Write-Output "Updates pyenv-win to the latest version by downloading and running"
    Write-Output "the installer. Preserves installed Python versions and cache."
    exit 0
}

$localVersion = Get-PyenvVersion
Write-Host ":: [Info] :: Current pyenv-win version: $localVersion" -ForegroundColor Green

# Check if upgrade is needed
$repoBase = "https://raw.githubusercontent.com/satori-analytics/pyenv-win/master"
try {
    $remoteVersion = (Invoke-WebRequest -Uri "$repoBase/.version" -UseBasicParsing -ErrorAction Stop).Content.Trim()
    if ($remoteVersion -eq $localVersion) {
        Write-Host ":: [Info] :: Already up to date." -ForegroundColor Green
        exit 0
    }
    Write-Host ":: [Info] :: Upgrading to $remoteVersion..." -ForegroundColor Green
}
catch {
    Write-Host ":: [Warn] :: Could not check remote version, proceeding with upgrade..." -ForegroundColor Yellow
}

# Download and run install.ps1 from the repo
$installUrl = "$repoBase/pyenv-win/install.ps1"
try {
    $installScript = (Invoke-WebRequest -Uri $installUrl -UseBasicParsing -ErrorAction Stop).Content

    # Run in a child process so it can replace our files safely
    & pwsh -NoProfile -Command $installScript
}
catch {
    Write-Host ":: [Error] :: Failed to download installer: $_" -ForegroundColor Red
    exit 1
}

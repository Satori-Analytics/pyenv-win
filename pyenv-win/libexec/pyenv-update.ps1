#Requires -Version 7
# pyenv update: Download the latest versions database from the repository
param()

if ($args -contains '--help') {
    Write-Output "Usage: pyenv update"
    Write-Output ""
    Write-Output "Downloads the latest Python versions database from the pyenv-win repository."
    Write-Output "If a newer version of pyenv-win is available, prints an upgrade notice."
    Write-Output ""
    Write-Output "See also: 'pyenv upgrade' to update pyenv-win itself."
    exit 0
}

$repoBase = "https://raw.githubusercontent.com/satori-analytics/pyenv-win/master"

Write-Host ":: [Info] :: Updating versions database..." -ForegroundColor Green

# Download .versions.xml
$xmlUrl = "$repoBase/pyenv-win/.versions.xml"
$cachePath = $script:PyenvDBFile
if (-not $cachePath) {
    $cachePath = Join-Path $script:PyenvHome '.versions.xml'
}

try {
    $response = Invoke-WebRequest -Uri $xmlUrl -UseBasicParsing -ErrorAction Stop
    $response.Content | Set-Content -Path $cachePath -Encoding UTF8
    Write-Host ":: [Info] :: Versions database updated." -ForegroundColor Green
}
catch {
    Write-Host ":: [Error] :: Failed to download versions database: $_" -ForegroundColor Red
    Write-Host "Falling back to local database." -ForegroundColor Yellow
    exit 1
}

# Check for newer pyenv-win version
$versionUrl = "$repoBase/.version"
try {
    $remoteVersion = (Invoke-WebRequest -Uri $versionUrl -UseBasicParsing -ErrorAction Stop).Content.Trim()
    $localVersion = Get-PyenvVersion

    if ($remoteVersion -and $localVersion -and $remoteVersion -ne $localVersion) {
        Write-Host ""
        Write-Host ":: [Info] :: pyenv-win $remoteVersion is available (current: $localVersion)." -ForegroundColor Yellow
        Write-Host ":: [Info] :: Run 'pyenv upgrade' to update pyenv-win." -ForegroundColor Yellow
    }
}
catch {
    # Non-fatal — version check is best-effort
}

#Requires -Version 7
# pyenv-win core library
# Path constants, environment, logging, architecture detection

# Resolve PyenvHome: env var → parent of lib/ directory
if ($env:PYENV_HOME) {
    $script:PyenvHome = $env:PYENV_HOME.TrimEnd('\', '/')
}
elseif ($env:PYENV_ROOT) {
    $script:PyenvHome = $env:PYENV_ROOT.TrimEnd('\', '/')
}
elseif ($env:PYENV) {
    $script:PyenvHome = $env:PYENV.TrimEnd('\', '/')
}
else {
    $script:PyenvHome = Split-Path $PSScriptRoot -Parent
}
$script:PyenvRoot = Split-Path $script:PyenvHome -Parent
$script:PyenvVersions = Join-Path $script:PyenvHome 'versions'
$script:PyenvShims = Join-Path $script:PyenvHome 'shims'
$script:PyenvLibexec = Join-Path $script:PyenvHome 'libexec'
$script:PyenvCache = Join-Path $script:PyenvHome 'install_cache'
$script:PyenvDBFile = Join-Path $script:PyenvHome '.versions_cache.xml'
$script:PyenvVersionFile = '.python-version'

function Get-PyenvVersion {
    $versionFile = Join-Path $script:PyenvRoot '.version'
    if (Test-Path $versionFile) {
        return (Get-Content $versionFile -Raw).Trim()
    }
    return 'unknown'
}

function Test-IsVersion {
    param([string]$Version)
    return $Version -match '^[a-zA-Z_0-9\-.]+$'
}

function Get-ArchPostfix {
    $arch = $env:PYENV_FORCE_ARCH
    if ([string]::IsNullOrEmpty($arch)) {
        $arch = [System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
    }

    switch ($arch.ToUpper()) {
        'AMD64' { return '' }
        'X86' { return '-win32' }
        'ARM64' { return '-arm64' }
        default { return '' }
    }
}

function Test-Is32Bit {
    $arch = $env:PYENV_FORCE_ARCH
    if ([string]::IsNullOrEmpty($arch)) {
        $arch = [System.Environment]::GetEnvironmentVariable('PROCESSOR_ARCHITECTURE', 'Machine')
    }
    return ($arch.ToUpper() -eq 'X86')
}

function Resolve-32Bit {
    param([string]$Version)
    if ((Test-Is32Bit) -and $Version.ToLower() -notmatch '-win32$') {
        return "$Version-win32"
    }
    return $Version
}

function Set-PyenvProxy {
    $proxyUrl = $env:http_proxy
    if ([string]::IsNullOrEmpty($proxyUrl)) {
        $proxyUrl = $env:https_proxy
    }
    if ([string]::IsNullOrEmpty($proxyUrl)) { return }

    $proxyUrl = $proxyUrl -replace '^https?://', ''
    $proxyUrl = $proxyUrl.TrimEnd('/')

    if ($proxyUrl -match '@') {
        $proxyUrl = ($proxyUrl -split '@')[-1]
    }

    $proxy = [System.Net.WebProxy]::new("http://$proxyUrl")
    [System.Net.WebRequest]::DefaultWebProxy = $proxy
}

function Write-PyenvInfo {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Gray
}

function Write-PyenvError {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Red
}

function Write-PyenvWarn {
    param([string]$Message)
    Write-Host $Message -ForegroundColor Yellow
}

function Get-PyenvExtensions {
    param([switch]$AddPy)

    $exts = @{}
    $pathExt = $env:PATHEXT
    if ([string]::IsNullOrEmpty($pathExt)) {
        $pathExt = '.COM;.EXE;.BAT;.CMD'
    }

    foreach ($ext in ($pathExt -split ';')) {
        $ext = $ext.Trim()
        if ($ext) { $exts[$ext.ToLower()] = $true }
    }

    if ($AddPy) {
        if (-not $exts.ContainsKey('.py')) { $exts['.py'] = $true }
        if (-not $exts.ContainsKey('.pyw')) { $exts['.pyw'] = $true }
    }

    return $exts
}

function Get-PyenvExtensionsNoPeriod {
    param([switch]$AddPy)

    $result = @{}
    $exts = Get-PyenvExtensions -AddPy:$AddPy

    foreach ($key in $exts.Keys) {
        if ($key.StartsWith('.')) {
            $result[$key.Substring(1).ToLower()] = $true
        }
        else {
            $result[$key.ToLower()] = $true
        }
    }

    return $result
}

function Get-BinDir {
    param([string]$Version)
    $dir = Join-Path $script:PyenvVersions $Version
    if (-not (Test-IsVersion $Version) -or -not (Test-Path $dir -PathType Container)) {
        Write-Output "pyenv specific python requisite didn't meet. Project is using different version of python."
        Write-Output "Install python '$Version' by typing: 'pyenv install $Version'"
        exit 1
    }
    return $dir
}

# Initialize proxy on load
Set-PyenvProxy

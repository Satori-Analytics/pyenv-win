#Requires -Version 7
# pyenv-win version database library
# XML load/save, semantic version comparison, version resolution

# Regex patterns matching pyenv-install-lib.vbs
$script:RegexVer = [regex]::new(
    '^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:([a-z]+)(\d*))?$',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$script:RegexVerArch = [regex]::new(
    '^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:([a-z]+)(\d*))?([\.\-](?:amd64|arm64|win32))?$',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$script:RegexFile = [regex]::new(
    '^python-(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:([a-z]+)(\d*))?([\.\-]amd64)?([\.\-]arm64)?(-webinstall)?\.(exe|msi)$',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)
$script:RegexJsonUrl = [regex]::new(
    'download_url"": ?""(https://[^\s""]+/(((?:pypy\d+\.\d+-v|graalpy-)(\d+)(?:\.(\d+))?(?:\.(\d+))?-(win64|windows-amd64)?(windows-aarch64)?).zip))""',
    [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
)

# Version component indices (matching VBS constants)
$script:VRX_Major = 0
$script:VRX_Minor = 1
$script:VRX_Patch = 2
$script:VRX_Release = 3
$script:VRX_RelNumber = 4
$script:VRX_x64 = 5
$script:VRX_ARM = 6
$script:VRX_Web = 7
$script:VRX_Ext = 8
$script:VRX_Arch = 5
$script:VRX_ZipRoot = 9

# LoadVersionsXML output indices
$script:LV_Code = 0
$script:LV_FileName = 1
$script:LV_URL = 2
$script:LV_x64 = 3
$script:LV_Web = 4
$script:LV_MSI = 5
$script:LV_ZipRootDir = 6

# Install params extension indices
$script:IP_InstallPath = 7
$script:IP_InstallFile = 8
$script:IP_Quiet = 9
$script:IP_Dev = 10

function Import-VersionsCache {
    param([string]$XmlPath)

    if ([string]::IsNullOrEmpty($XmlPath)) {
        $XmlPath = $script:PyenvDBFile
    }

    $result = [ordered]@{}
    if (-not (Test-Path $XmlPath)) { return $result }

    try {
        [xml]$doc = Get-Content $XmlPath -Raw
    }
    catch {
        Write-PyenvError "Error reading version cache: $_"
        exit 1
    }

    foreach ($version in $doc.versions.version) {
        $code = $version.code
        $zipRootDir = ''
        if ($version.zipRootDir) {
            $zipRootDir = $version.zipRootDir
        }

        $x64 = $false
        if ($version.x64 -eq 'true') { $x64 = $true }

        $web = $false
        if ($version.webInstall -eq 'true') { $web = $true }

        $msi = $true
        if ($version.msi -eq 'false') { $msi = $false }

        $result[$code] = @(
            $code,
            $version.file,
            $version.URL,
            $x64,
            $web,
            $msi,
            $zipRootDir
        )
    }

    return $result
}

function Join-Win32String {
    param([array]$Pieces)

    $result = ''
    if ($Pieces[$script:VRX_Major]) { $result += $Pieces[$script:VRX_Major] }
    if ($Pieces[$script:VRX_Minor]) { $result += '.' + $Pieces[$script:VRX_Minor] }
    if ($Pieces[$script:VRX_Patch]) { $result += '.' + $Pieces[$script:VRX_Patch] }
    if ($Pieces[$script:VRX_Release]) { $result += $Pieces[$script:VRX_Release] }
    if ($Pieces[$script:VRX_RelNumber]) { $result += $Pieces[$script:VRX_RelNumber] }
    if ($Pieces[$script:VRX_ARM]) {
        $result += '-arm'
    }
    elseif (-not $Pieces[$script:VRX_x64]) {
        $result += '-win32'
    }
    return $result
}

function Join-InstallString {
    param([array]$Pieces)

    $result = ''
    if ($Pieces[$script:VRX_Major]) { $result += $Pieces[$script:VRX_Major] }
    if ($Pieces[$script:VRX_Minor]) { $result += '.' + $Pieces[$script:VRX_Minor] }
    if ($Pieces[$script:VRX_Patch]) { $result += '.' + $Pieces[$script:VRX_Patch] }
    if ($Pieces[$script:VRX_Release]) { $result += $Pieces[$script:VRX_Release] }
    if ($Pieces[$script:VRX_RelNumber]) { $result += $Pieces[$script:VRX_RelNumber] }
    if ($Pieces[$script:VRX_x64]) { $result += $Pieces[$script:VRX_x64] }
    if ($Pieces[$script:VRX_ARM]) { $result += $Pieces[$script:VRX_ARM] }
    if ($Pieces[$script:VRX_Web]) { $result += $Pieces[$script:VRX_Web] }
    if ($Pieces[$script:VRX_Ext]) { $result += '.' + $Pieces[$script:VRX_Ext] }
    return $result
}

function Join-VersionString {
    param([array]$Pieces)

    $result = ''
    if ($Pieces[$script:VRX_Major]) { $result += $Pieces[$script:VRX_Major] }
    if ($Pieces[$script:VRX_Minor]) { $result += '.' + $Pieces[$script:VRX_Minor] }
    if ($Pieces[$script:VRX_Patch]) { $result += '.' + $Pieces[$script:VRX_Patch] }
    if ($Pieces[$script:VRX_Release]) { $result += $Pieces[$script:VRX_Release] }
    if ($Pieces[$script:VRX_RelNumber]) { $result += $Pieces[$script:VRX_RelNumber] }
    if ($Pieces[$script:VRX_Arch]) { $result += $Pieces[$script:VRX_Arch] }
    return $result
}

function Compare-SemanticVersion {
    <#
    .SYNOPSIS
        Returns $true if ver1 < ver2 (same logic as VBS SymanticCompare)
    #>
    param([array]$Ver1, [array]$Ver2)

    # Major
    $c1 = if ($Ver1[$script:VRX_Major]) { [long]$Ver1[$script:VRX_Major] } else { 0 }
    $c2 = if ($Ver2[$script:VRX_Major]) { [long]$Ver2[$script:VRX_Major] } else { 0 }
    if ($c1 -ne $c2) { return $c1 -lt $c2 }

    # Minor
    $c1 = if ($Ver1[$script:VRX_Minor]) { [long]$Ver1[$script:VRX_Minor] } else { 0 }
    $c2 = if ($Ver2[$script:VRX_Minor]) { [long]$Ver2[$script:VRX_Minor] } else { 0 }
    if ($c1 -ne $c2) { return $c1 -lt $c2 }

    # Patch
    $c1 = if ($Ver1[$script:VRX_Patch]) { [long]$Ver1[$script:VRX_Patch] } else { 0 }
    $c2 = if ($Ver2[$script:VRX_Patch]) { [long]$Ver2[$script:VRX_Patch] } else { 0 }
    if ($c1 -ne $c2) { return $c1 -lt $c2 }

    # Release (alpha/beta/rc — presence means pre-release, absence means stable)
    $r1 = $Ver1[$script:VRX_Release]
    $r2 = $Ver2[$script:VRX_Release]
    if (-not $r1 -and $r2) { return $false }  # stable > pre-release
    if ($r1 -and -not $r2) { return $true }   # pre-release < stable
    if ($r1 -ne $r2) { return $r1 -lt $r2 }

    # Release Number
    $c1 = if ($Ver1[$script:VRX_RelNumber]) { [long]$Ver1[$script:VRX_RelNumber] } else { 0 }
    $c2 = if ($Ver2[$script:VRX_RelNumber]) { [long]$Ver2[$script:VRX_RelNumber] } else { 0 }
    if ($c1 -ne $c2) { return $c1 -lt $c2 }

    # x64
    if ($Ver1[$script:VRX_x64] -ne $Ver2[$script:VRX_x64]) {
        return $Ver1[$script:VRX_x64] -lt $Ver2[$script:VRX_x64]
    }

    # ARM
    if ($Ver1[$script:VRX_ARM] -ne $Ver2[$script:VRX_ARM]) {
        return $Ver1[$script:VRX_ARM] -lt $Ver2[$script:VRX_ARM]
    }

    # Web
    if ($Ver1[$script:VRX_Web] -ne $Ver2[$script:VRX_Web]) {
        return $Ver1[$script:VRX_Web] -lt $Ver2[$script:VRX_Web]
    }

    # Ext
    if ($Ver1[$script:VRX_Ext] -ne $Ver2[$script:VRX_Ext]) {
        return $Ver1[$script:VRX_Ext] -lt $Ver2[$script:VRX_Ext]
    }

    return $false
}

function Find-LatestVersion {
    param(
        [string]$Prefix,
        [switch]$Known
    )

    if ($Known) {
        $cachedVersions = Import-VersionsCache
        $candidates = @($cachedVersions.Keys)
    }
    else {
        $candidates = Get-InstalledVersions
    }

    $arch = Get-ArchPostfix
    $bestMatch = $null

    foreach ($candidate in $candidates) {
        # startswith check
        if (-not $candidate.StartsWith($Prefix)) { continue }

        # Full match OR prefix plus '.'
        if ($candidate -ne "$Prefix$arch" -and $candidate.Substring($Prefix.Length, [math]::Min(1, $candidate.Length - $Prefix.Length)) -ne '.') {
            continue
        }

        $match = $script:RegexVerArch.Match($candidate)
        if (-not $match.Success) { continue }

        $groups = @(
            $match.Groups[1].Value,  # Major
            $match.Groups[2].Value,  # Minor
            $match.Groups[3].Value,  # Patch
            $match.Groups[4].Value,  # Release
            $match.Groups[5].Value,  # RelNumber
            $match.Groups[6].Value   # Arch
        )

        # Skip dev builds / releases
        if ($groups[3] -ne '') { continue }
        if ($groups[5] -ne $arch) { continue }

        if ($null -eq $bestMatch) {
            $bestMatch = $groups
        }
        else {
            if (Compare-SemanticVersion $bestMatch $groups) {
                $bestMatch = $groups
            }
        }
    }

    if ($null -eq $bestMatch) { return '' }
    return Join-VersionString $bestMatch
}

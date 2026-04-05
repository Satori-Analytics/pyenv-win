#Requires -Version 7

<#
.SYNOPSIS
    Updates the internal database of Python installer URLs for pyenv-win
.DESCRIPTION
    This PowerShell script replaces the VBScript version for better Windows 11 compatibility
.PARAMETER Ignore
    Ignores any HTTP errors that occur during downloads
.PARAMETER Help
    Shows help information
#>

[CmdletBinding()]
param(
    [switch]$Ignore,
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Remaining
)

# Manual --help check — PS can't bind --help to -Help via splatted arrays
if ($Help -or '--help' -in $Remaining) {
    Write-Output "Usage: pyenv update-ci [--verbose] [-Ignore]"
    Write-Output ""
    Write-Output "  -Ignore   Ignores any HTTP errors that occur during downloads."
    Write-Output ""
    Write-Output "Updates the internal database of python installer URL's."
    exit 0
}

# Configuration
$mirrors = @(
    "https://www.python.org/ftp/python/",
    "https://downloads.python.org/pypy/versions.json",
    "https://api.github.com/repos/oracle/graalpython/releases"
)

# Regex patterns
$regexVer = [regex]'(\d+)\.(\d+)(?:\.(\d+))?'
$regexFile = [regex]'python-(\d+)\.(\d+)(?:\.(\d+))?(?:([a-z]+)(\d+))?(?:-(amd64|win32|arm64))?(?:-(web)installer)?\.(.+)'
$regexJsonUrl = [regex]'"url":\s*"([^"]+/([^/]+\.zip))"[^}]*"extract_dir":\s*"([^"]*)"[^}]*"version":\s*"([^"]+)"'

Write-Host ":: [Info] :: Updating versions cache..." -ForegroundColor Green

foreach ($mirror in $mirrors) {
    Write-Verbose "Mirror: $mirror"
}

function Get-WebContent {
    param(
        [string]$Url,
        [bool]$IgnoreErrors = $false
    )
    
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -ErrorAction Stop
        return $response.Content
    }
    catch {
        $errorMsg = "HTTP Error downloading from $Url : $($_.Exception.Message)"
        Write-Host $errorMsg
        if (-not $IgnoreErrors) {
            exit 1
        }
        return $null
    }
}

function Parse-PythonOrgPage {
    param(
        [string]$Content,
        [string]$BaseUrl
    )
    
    $versions = @{}
    
    # Extract version links from HTML
    $linkPattern = @'
<a\s+[^>]*href\s*=\s*["']([^"']+)["'][^>]*>([^<>]+)</a>
'@
    $linkMatches = [regex]::Matches($Content, $linkPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $linkMatches) {
        $href = $match.Groups[1].Value
        $linkText = $match.Groups[2].Value.Trim()
        
        # Skip parent directory links
        if ($linkText -eq "../" -or $linkText -eq "..") {
            continue
        }
        
        # Clean version name
        $versionName = $linkText.TrimEnd('/')
        
        # Check if it matches version pattern
        $versionMatch = $regexVer.Match($versionName)
        if ($versionMatch.Success) {
            $major = [int]$versionMatch.Groups[1].Value
            $minor = [int]$versionMatch.Groups[2].Value
            
            # Only process Python >= 2.4
            if ($major -gt 2 -or ($major -eq 2 -and $minor -ge 4)) {
                Write-Verbose "     Processing Python $versionName..."
                    
                # Build full URL
                if (-not $href.StartsWith("http")) {
                    $href = $BaseUrl.TrimEnd('/') + '/' + $href.TrimStart('./')
                }
                    
                # Scan version subdirectory
                $subContent = Get-WebContent -Url $href -IgnoreErrors $Ignore
                if ($subContent) {
                    $subVersions = Parse-VersionSubdirectory -Content $subContent -BaseUrl $href
                    Write-Verbose "        Found $($subVersions.Count) installers"
                    foreach ($key in $subVersions.Keys) {
                        $versions[$key] = $subVersions[$key]
                    }
                }
                else {
                    Write-Verbose "        Failed to get content"
                }
            }
        }
    }
    
    return $versions
}

function Parse-VersionSubdirectory {
    param(
        [string]$Content,
        [string]$BaseUrl
    )
    
    $installers = @{}
    
    $linkPattern = @'
<a\s+[^>]*href\s*=\s*["']([^"']+)["'][^>]*>([^<>]+)</a>
'@
    $linkMatches = [regex]::Matches($Content, $linkPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    
    foreach ($match in $linkMatches) {
        $href = $match.Groups[1].Value
        $fileName = $match.Groups[2].Value.Trim()
        
        # Check if filename matches installer pattern
        $fileMatch = $regexFile.Match($fileName)
        if ($fileMatch.Success) {
            # Extract extension for filtering
            $ext = $fileMatch.Groups[8].Value
            
            # Skip non-installer files (signatures, checksums, certificates, etc.)
            if ($ext -match '\.(asc|sig|crt|sigstore|spdx\.json)$') {
                continue
            }
            
            # Skip non-Windows files (macOS, Linux, source code)
            if ($fileName -match '\.(dmg|pkg|tgz|tar\.gz|tar\.bz2|tar\.xz)$') {
                continue
            }
            
            # Skip test files, embed files, and debug files that aren't useful for installation
            if ($fileName -match '-(test|embed|docs)-' -or $fileName -match '-embeddable-' -or $fileName -match '\d+t-') {
                continue
            }
            
            # Build full URL
            if (-not $href.StartsWith("http")) {
                $href = $BaseUrl.TrimEnd('/') + '/' + $href.TrimStart('./')
            }
            
            # Extract version components
            $versionInfo = @(
                $fileMatch.Groups[1].Value,  # major
                $fileMatch.Groups[2].Value,  # minor
                $fileMatch.Groups[3].Value,  # patch
                $fileMatch.Groups[4].Value,  # release (a, b, rc)
                $fileMatch.Groups[5].Value,  # release number
                $fileMatch.Groups[6].Value,  # architecture (amd64, win32, arm64)
                "",                          # ARM (legacy)
                $fileMatch.Groups[7].Value,  # web installer
                $fileMatch.Groups[8].Value,  # extension
                ""                           # ziproot (for pypy)
            )
            
            $installers[$fileName] = @($fileName, $href, $versionInfo)
        }
    }
    
    return $installers
}

function Parse-JsonVersions {
    param(
        [string]$Content,
        [string]$Type
    )
    
    $installers = @{}
    
    if ($Type -eq "pypy") {
        # Parse PyPy JSON format
        try {
            $json = ConvertFrom-Json $Content
            foreach ($version in $json) {
                foreach ($file in $version.files) {
                    if ($file.platform -eq "win64" -and $file.download_url) {
                        $fileName = Split-Path $file.download_url -Leaf
                        if ($fileName -match '(\d+)\.(\d+)\.(\d+)') {
                            $versionInfo = @($matches[1], $matches[2], $matches[3], "", "", "amd64", "", "", "zip", "")
                            $installers[$fileName] = @($fileName, $file.download_url, $versionInfo)
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Error parsing PyPy JSON: $($_.Exception.Message)"
        }
    }
    elseif ($Type -eq "graalpy") {
        # Parse GraalPy releases
        try {
            $releases = ConvertFrom-Json $Content
            foreach ($release in $releases) {
                foreach ($asset in $release.assets) {
                    if ($asset.name -match 'graalpy.*win.*\.zip$') {
                        $fileName = $asset.name
                        if ($release.tag_name -match '(\d+)\.(\d+)\.(\d+)') {
                            $versionInfo = @($matches[1], $matches[2], $matches[3], "", "", "amd64", "", "", "zip", "")
                            $installers[$fileName] = @($fileName, $asset.browser_download_url, $versionInfo)
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Error parsing GraalPy JSON: $($_.Exception.Message)"
        }
    }
    
    return $installers
}

function Compare-UpdateVersion {
    param(
        [array]$Version1,
        [array]$Version2
    )
    
    # Compare major.minor.patch.release.releaseNum.x64.web.ext
    for ($i = 0; $i -lt 8; $i++) {
        $v1 = if ($Version1[$i] -and $Version1[$i] -ne "") { $Version1[$i] } else { if ($i -lt 3) { 0 } else { "" } }
        $v2 = if ($Version2[$i] -and $Version2[$i] -ne "") { $Version2[$i] } else { if ($i -lt 3) { 0 } else { "" } }
        
        if ($i -lt 3 -or $i -eq 4) {
            # Numeric comparison for major, minor, patch, release number
            $v1 = [int]$v1
            $v2 = [int]$v2
            if ($v1 -lt $v2) { return $true }
            if ($v1 -gt $v2) { return $false }
        }
        else {
            # String comparison for others
            if ($v1 -lt $v2) { return $true }
            if ($v1 -gt $v2) { return $false }
        }
    }
    
    return $false  # Equal
}

function Save-VersionsXml {
    param(
        [array]$Installers
    )
    
    $xml = '<?xml version="1.0" encoding="utf-8" standalone="no"?>' + "`n"
    $xml += '<versions>' + "`n"
    
    foreach ($installer in $Installers) {
        $fileName = $installer[0]
        $url = $installer[1]
        $version = $installer[2]
        
        # Extract version info for the code
        $major = $version[0]
        $minor = $version[1]
        $patch = $version[2]
        $release = $version[3]
        $relnum = $version[4]
        $arch = $version[5]
        $webInstall = $version[7]
        $ext = $version[8]
        
        # Determine attributes
        $x64 = if ($arch -eq "amd64") { "true" } else { "false" }
        $isWebInstall = if ($webInstall -eq "web") { "true" } else { "false" }
        $isMsi = if ($ext -eq "msi") { "true" } else { "false" }
        
        # Build version code
        $code = "$major.$minor"
        if ($patch) { $code += ".$patch" }
        if ($release -and $relnum) { $code += "$release$relnum" }
        elseif ($release) { $code += $release }
        
        # Add architecture suffix for win32
        if ($arch -eq "win32" -or (-not $arch -and $x64 -eq "false")) {
            $code += "-win32"
        }
        elseif ($arch -eq "arm64") {
            $code += "-arm64"
        }

        $xml += "`t<version x64=`"$x64`" webInstall=`"$isWebInstall`" msi=`"$isMsi`">`n"
        $xml += "`t`t<code>$code</code>`n"
        $xml += "`t`t<file>$fileName</file>`n"
        $xml += "`t`t<URL>$([System.Net.WebUtility]::HtmlEncode($url))</URL>`n"
        $xml += "`t</version>`n"
    }
    
    $xml += '</versions>'
    
    $cachePath = $script:PyenvDBFile
    if (-not $cachePath) {
        $cachePath = Join-Path $PSScriptRoot "..\.versions.xml"
    }
    $xml | Set-Content -Path $cachePath -Encoding UTF8
}

# Main execution
$pageCount = 0
$allInstallers = @{}

foreach ($mirror in $mirrors) {
    Write-Verbose "Processing mirror: $mirror"
    Write-Verbose "   Downloading content..."
    
    $content = Get-WebContent -Url $mirror -IgnoreErrors $Ignore
    if (-not $content) { 
        Write-Host "   -> Failed to get content from $mirror, skipping..." -ForegroundColor Red
        continue 
    }
    
    Write-Verbose "   Content downloaded, parsing..."
    $pageCount++
    
    $mirrorName = ""
    if ($mirror.EndsWith(".json") -or $mirror.Contains("graalpython")) {
        if ($mirror.Contains("pypy")) {
            $mirrorName = "PyPy"
            Write-Verbose "   Parsing PyPy JSON data..."
            $installers = Parse-JsonVersions -Content $content -Type "pypy"
        }
        elseif ($mirror.Contains("graalpython")) {
            $mirrorName = "GraalPy"
            Write-Verbose "   Parsing GraalPy JSON data..."
            $installers = Parse-JsonVersions -Content $content -Type "graalpy"
        }
    }
    else {
        $mirrorName = "python.org"
        Write-Verbose "   Parsing Python.org HTML page..."
        $installers = Parse-PythonOrgPage -Content $content -BaseUrl $mirror
    }
    
    Write-Host "   -> ${mirrorName}: $($installers.Count) installers" -ForegroundColor Cyan
    
    foreach ($key in $installers.Keys) {
        $allInstallers[$key] = $installers[$key]
    }
}

Write-Verbose "Processing $($allInstallers.Count) total installers..."
Write-Verbose "   Filtering versions >= 2.4 and deduplicating..."

# Remove versions < 2.4 and deduplicate web vs offline installers
$filteredInstallers = @{}
$minVersion = @("2", "4", "", "", "", "", "", "", "")

foreach ($key in $allInstallers.Keys) {
    $installer = $allInstallers[$key]
    $version = $installer[2]
    
    # Skip versions < 2.4
    if (Compare-UpdateVersion -Version1 $version -Version2 $minVersion) {
        continue
    }
    
    # Prefer offline installers over web installers
    if ($version[7] -eq "web") {
        # This is a web installer
        $offlineFileName = $key -replace "-webinstaller", ""
        if ($allInstallers.ContainsKey($offlineFileName)) {
            continue  # Skip web installer if offline version exists
        }
    }
    
    $filteredInstallers[$key] = $installer
}

Write-Verbose "Filtered to $($filteredInstallers.Count) installers"
Write-Verbose "Sorting by semantic version..."

# Sort by semantic version, then by filename for deterministic output
$sortedInstallers = $filteredInstallers.Values | Sort-Object { 
    $v = $_[2]
    if ($v -and $v.Count -ge 3) {
        $major = if ($v[0]) { $v[0] } else { "0" }
        $minor = if ($v[1]) { $v[1] } else { "0" }
        $patch = if ($v[2]) { $v[2] } else { "0" }
        try {
            [version]"$major.$minor.$patch"
        }
        catch {
            # If version parsing fails, use string comparison
            "$major.$minor.$patch"
        }
    }
    else {
        # Fallback for malformed version arrays
        $_[0]  # Sort by filename
    }
}, { $_[0] }

Write-Verbose "Saving XML cache file..."

# Save to XML
Save-VersionsXml -Installers $sortedInstallers

Write-Host ":: [Info] :: Saved $($filteredInstallers.Count) versions to .versions.xml" -ForegroundColor Green

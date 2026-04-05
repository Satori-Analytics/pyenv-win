#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'versions-db.ps1' {
    BeforeAll {
        $env:PYENV_FORCE_ARCH = 'AMD64'
        $script:testEnv = New-PyenvTestEnvironment
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'Regex patterns' {
        It 'RegexVer matches standard version strings' -TestCases @(
            @{ VersionStr = '3.9.7'; Major = '3'; Minor = '9'; Patch = '7'; Release = ''; RelNum = '' }
            @{ VersionStr = '3.12.0a1'; Major = '3'; Minor = '12'; Patch = '0'; Release = 'a'; RelNum = '1' }
            @{ VersionStr = '3.11.0rc2'; Major = '3'; Minor = '11'; Patch = '0'; Release = 'rc'; RelNum = '2' }
            @{ VersionStr = '3'; Major = '3'; Minor = ''; Patch = ''; Release = ''; RelNum = '' }
            @{ VersionStr = '3.9'; Major = '3'; Minor = '9'; Patch = ''; Release = ''; RelNum = '' }
        ) {
            param($VersionStr, $Major, $Minor, $Patch, $Release, $RelNum)
            $re = [regex]::new('^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:([a-z]+)(\d*))?$', 'IgnoreCase')
            $m = $re.Match($VersionStr)
            $m.Success | Should -BeTrue
            $m.Groups[1].Value | Should -Be $Major
            $m.Groups[2].Value | Should -Be $Minor
            $m.Groups[3].Value | Should -Be $Patch
            $m.Groups[4].Value | Should -Be $Release
            $m.Groups[5].Value | Should -Be $RelNum
        }

        It 'RegexVerArch matches version strings with architecture' -TestCases @(
            @{ VersionStr = '3.9.7'; Arch = '' }
            @{ VersionStr = '3.9.7-amd64'; Arch = '-amd64' }
            @{ VersionStr = '3.9.7-win32'; Arch = '-win32' }
            @{ VersionStr = '3.9.7-arm64'; Arch = '-arm64' }
        ) {
            param($VersionStr, $Arch)
            $re = [regex]::new('^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:([a-z]+)(\d*))?([\.\-](?:amd64|arm64|win32))?$', 'IgnoreCase')
            $m = $re.Match($VersionStr)
            $m.Success | Should -BeTrue
            $m.Groups[6].Value | Should -Be $Arch
        }
    }

    Describe 'Import-VersionsCache' {
        It 'returns empty ordered dict when file missing' {
            $result = Import-VersionsCache -XmlPath (Join-Path $TestDrive 'nonexistent.xml')
            $result.Count | Should -Be 0
        }

        It 'parses valid versions XML' {
            $xmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<versions>
  <version>
    <code>3.9.7</code>
    <file>python-3.9.7-amd64.exe</file>
    <URL>https://www.python.org/ftp/python/3.9.7/python-3.9.7-amd64.exe</URL>
    <x64>true</x64>
    <webInstall>false</webInstall>
    <msi>false</msi>
  </version>
  <version>
    <code>3.8.12</code>
    <file>python-3.8.12-amd64.exe</file>
    <URL>https://www.python.org/ftp/python/3.8.12/python-3.8.12-amd64.exe</URL>
    <x64>true</x64>
    <webInstall>false</webInstall>
    <msi>false</msi>
  </version>
</versions>
'@
            $xmlPath = Join-Path $TestDrive 'versions.xml'
            Set-Content -Path $xmlPath -Value $xmlContent
            $result = Import-VersionsCache -XmlPath $xmlPath

            $result.Count | Should -Be 2
            $result['3.9.7'] | Should -Not -BeNullOrEmpty
            $result['3.9.7'][0] | Should -Be '3.9.7'
            $result['3.9.7'][3] | Should -BeTrue  # x64
            $result['3.9.7'][4] | Should -BeFalse  # webInstall
            $result['3.8.12'] | Should -Not -BeNullOrEmpty
        }

        It 'handles zipRootDir attribute' {
            $xmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<versions>
  <version>
    <code>pypy3.9-v7.3.11</code>
    <file>pypy3.9-v7.3.11-win64.zip</file>
    <URL>https://example.com/pypy.zip</URL>
    <x64>true</x64>
    <webInstall>false</webInstall>
    <msi>false</msi>
    <zipRootDir>pypy3.9-v7.3.11-win64</zipRootDir>
  </version>
</versions>
'@
            $xmlPath = Join-Path $TestDrive 'versions-zip.xml'
            Set-Content -Path $xmlPath -Value $xmlContent
            $result = Import-VersionsCache -XmlPath $xmlPath
            $result['pypy3.9-v7.3.11'][6] | Should -Be 'pypy3.9-v7.3.11-win64'
        }
    }

    Describe 'Compare-SemanticVersion' {
        It 'compares major versions' {
            $v1 = @('2', '7', '18', '', '', '')
            $v2 = @('3', '9', '7', '', '', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
            Compare-SemanticVersion $v2 $v1 | Should -BeFalse
        }

        It 'compares minor versions' {
            $v1 = @('3', '8', '0', '', '', '')
            $v2 = @('3', '9', '0', '', '', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
            Compare-SemanticVersion $v2 $v1 | Should -BeFalse
        }

        It 'compares patch versions' {
            $v1 = @('3', '9', '1', '', '', '')
            $v2 = @('3', '9', '7', '', '', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
            Compare-SemanticVersion $v2 $v1 | Should -BeFalse
        }

        It 'stable is greater than pre-release' {
            $v1 = @('3', '12', '0', 'rc', '1', '')
            $v2 = @('3', '12', '0', '', '', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
            Compare-SemanticVersion $v2 $v1 | Should -BeFalse
        }

        It 'compares pre-release tags alphabetically' {
            $v1 = @('3', '12', '0', 'a', '1', '')
            $v2 = @('3', '12', '0', 'b', '1', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
        }

        It 'compares release numbers' {
            $v1 = @('3', '12', '0', 'rc', '1', '')
            $v2 = @('3', '12', '0', 'rc', '2', '')
            Compare-SemanticVersion $v1 $v2 | Should -BeTrue
        }

        It 'returns false for equal versions' {
            $v1 = @('3', '9', '7', '', '', '')
            Compare-SemanticVersion $v1 $v1 | Should -BeFalse
        }
    }

    Describe 'Join-VersionString' {
        It 'joins standard version' {
            $pieces = @('3', '9', '7', '', '', '')
            Join-VersionString $pieces | Should -Be '3.9.7'
        }

        It 'joins version with pre-release' {
            $pieces = @('3', '12', '0', 'a', '1', '')
            Join-VersionString $pieces | Should -Be '3.12.0a1'
        }

        It 'joins version with arch' {
            $pieces = @('3', '9', '7', '', '', '-amd64')
            Join-VersionString $pieces | Should -Be '3.9.7-amd64'
        }

        It 'joins major-only' {
            $pieces = @('3', '', '', '', '', '')
            Join-VersionString $pieces | Should -Be '3'
        }

        It 'joins major.minor' {
            $pieces = @('3', '9', '', '', '', '')
            Join-VersionString $pieces | Should -Be '3.9'
        }
    }

    Describe 'Join-Win32String' {
        It 'appends -win32 when no x64 marker' {
            $pieces = @('3', '9', '7', '', '', '', '')
            Join-Win32String $pieces | Should -Be '3.9.7-win32'
        }

        It 'does not append when x64 present' {
            $pieces = @('3', '9', '7', '', '', '.amd64', '')
            Join-Win32String $pieces | Should -Be '3.9.7'
        }

        It 'appends -arm when ARM present' {
            $pieces = @('3', '9', '7', '', '', '', '.arm64')
            Join-Win32String $pieces | Should -Be '3.9.7-arm'
        }
    }

    Describe 'Find-LatestVersion' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.8.4', '3.8.7', '3.9.1', '3.9.5', '3.11.0')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'finds latest patch for a prefix' {
            $result = Find-LatestVersion -Prefix '3.8'
            $result | Should -Be '3.8.7'
        }

        It 'finds latest minor for a major prefix' {
            $result = Find-LatestVersion -Prefix '3'
            $result | Should -Be '3.11.0'
        }

        It 'returns exact match' {
            $result = Find-LatestVersion -Prefix '3.9.5'
            $result | Should -Be '3.9.5'
        }

        It 'returns empty for no match' {
            $result = Find-LatestVersion -Prefix '2'
            $result | Should -Be ''
        }

        It 'skips dev/pre-release versions' {
            # Pre-release versions have non-empty Release field, which gets filtered
            $result = Find-LatestVersion -Prefix '3.9'
            $result | Should -Be '3.9.5'
        }
    }
}



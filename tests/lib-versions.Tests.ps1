#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'versions.ps1' {
    BeforeAll {
        $env:PYENV_FORCE_ARCH = 'AMD64'
    }

    Describe 'Get-CurrentVersionsGlobal' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -GlobalVersion @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'returns version from global version file' {
            $result = Get-CurrentVersionsGlobal
            $result | Should -Not -BeNullOrEmpty
            $result[0][0] | Should -Be '3.9.7'
        }

        It 'returns null when no global version file' {
            $versionFile = Join-Path $script:testEnv.PyenvPath 'version'
            if (Test-Path $versionFile) { Remove-Item $versionFile }
            $result = Get-CurrentVersionsGlobal
            $result | Should -BeNullOrEmpty
        }

        It 'returns multiple versions from global file' {
            $versionFile = Join-Path $script:testEnv.PyenvPath 'version'
            Set-Content -Path $versionFile -Value "3.9.7`n3.10.1"
            $result = Get-CurrentVersionsGlobal
            $result | Should -HaveCount 2
            $result[0][0] | Should -Be '3.9.7'
            $result[1][0] | Should -Be '3.10.1'
        }
    }

    Describe 'Get-CurrentVersionsLocal' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -LocalVersion @('3.10.1')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'returns version from .python-version file' {
            Push-Location $script:testEnv.LocalPath
            try {
                $result = Get-CurrentVersionsLocal
                $result | Should -Not -BeNullOrEmpty
                $result[0][0] | Should -Be '3.10.1'
            }
            finally {
                Pop-Location
            }
        }

        It 'traverses parent directories to find .python-version' {
            $childDir = Join-Path $script:testEnv.LocalPath 'subdir' 'nested'
            New-Item -ItemType Directory -Path $childDir -Force | Out-Null
            Push-Location $childDir
            try {
                $result = Get-CurrentVersionsLocal
                $result | Should -Not -BeNullOrEmpty
                $result[0][0] | Should -Be '3.10.1'
            }
            finally {
                Pop-Location
            }
        }

        It 'returns null when no .python-version found' {
            Push-Location $TestDrive
            try {
                # Ensure no .python-version in TestDrive
                $pvFile = Join-Path $TestDrive '.python-version'
                if (Test-Path $pvFile) { Remove-Item $pvFile }
                $result = Get-CurrentVersionsLocal -SearchPath $TestDrive
                $result | Should -BeNullOrEmpty
            }
            finally {
                Pop-Location
            }
        }
    }

    Describe 'Get-CurrentVersionsShell' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'returns version from PYENV_VERSION env var' {
            $env:PYENV_VERSION = '3.9.7'
            try {
                $result = Get-CurrentVersionsShell
                $result | Should -Not -BeNullOrEmpty
                $result[0][0] | Should -Be '3.9.7'
            }
            finally {
                $env:PYENV_VERSION = $null
            }
        }

        It 'returns multiple versions from space-separated PYENV_VERSION' {
            $env:PYENV_VERSION = '3.9.7 3.10.1'
            try {
                $result = Get-CurrentVersionsShell
                $result | Should -HaveCount 2
                $result[0][0] | Should -Be '3.9.7'
                $result[1][0] | Should -Be '3.10.1'
            }
            finally {
                $env:PYENV_VERSION = $null
            }
        }

        It 'returns null when PYENV_VERSION unset' {
            $env:PYENV_VERSION = $null
            $result = Get-CurrentVersionsShell
            $result | Should -BeNullOrEmpty
        }

        It 'returns null when PYENV_VERSION is empty' {
            $env:PYENV_VERSION = ''
            $result = Get-CurrentVersionsShell
            $result | Should -BeNullOrEmpty
        }
    }

    Describe 'Get-CurrentVersionsNoError' {
        It 'prefers shell over local and global' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.8.0', '3.9.7', '3.10.1') `
                -GlobalVersion @('3.8.0') -LocalVersion @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            $env:PYENV_VERSION = '3.10.1'
            Push-Location $script:testEnv.LocalPath
            try {
                $result = Get-CurrentVersionsNoError
                $result.Keys | Should -Contain '3.10.1'
            }
            finally {
                Pop-Location
                $env:PYENV_VERSION = $null
            }
        }

        It 'prefers local over global when no shell' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.8.0', '3.9.7') `
                -GlobalVersion @('3.8.0') -LocalVersion @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            $env:PYENV_VERSION = $null
            Push-Location $script:testEnv.LocalPath
            try {
                $result = Get-CurrentVersionsNoError
                $result.Keys | Should -Contain '3.9.7'
            }
            finally {
                Pop-Location
            }
        }

        It 'returns empty when no version source configured' {
            $script:testEnv = New-PyenvTestEnvironment
            . (Initialize-PyenvLibraries -Env $script:testEnv)
            $env:PYENV_VERSION = $null
            Push-Location $TestDrive
            try {
                $pvFile = Join-Path $TestDrive '.python-version'
                if (Test-Path $pvFile) { Remove-Item $pvFile }
                $result = Get-CurrentVersionsNoError
                $result.Count | Should -Be 0
            }
            finally {
                Pop-Location
            }
        }
    }

    Describe 'Get-InstalledVersions' {
        It 'returns installed version names' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
            $result = Get-InstalledVersions
            $result | Should -Contain '3.9.7'
            $result | Should -Contain '3.10.1'
        }

        It 'returns empty when no versions installed' {
            $script:testEnv = New-PyenvTestEnvironment
            . (Initialize-PyenvLibraries -Env $script:testEnv)
            $result = Get-InstalledVersions
            $result | Should -HaveCount 0
        }
    }
}



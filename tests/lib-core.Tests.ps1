#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'core.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'Get-PyenvVersion' {
        It 'reads version from .version file' {
            $versionFile = Join-Path $TestDrive '.version'
            Set-Content -Path $versionFile -Value '4.0.0' -NoNewline
            Get-PyenvVersion | Should -Be '4.0.0'
        }

        It 'returns unknown when .version file missing' {
            $versionFile = Join-Path $TestDrive '.version'
            if (Test-Path $versionFile) { Remove-Item $versionFile }
            Get-PyenvVersion | Should -Be 'unknown'
        }
    }

    Describe 'Test-IsVersion' {
        It 'accepts valid version strings' -TestCases @(
            @{ V = '3.9.7' }
            @{ V = '3.10.1-win32' }
            @{ V = '3.10.1-amd64' }
            @{ V = 'pypy3.9-v7.3.11' }
            @{ V = '3.12.0a1' }
            @{ V = '3' }
        ) {
            param($V)
            Test-IsVersion $V | Should -BeTrue
        }

        It 'rejects invalid version strings' -TestCases @(
            @{ V = '' }
            @{ V = 'hello world' }
            @{ V = '3.9/7' }
            @{ V = '../escape' }
        ) {
            param($V)
            Test-IsVersion $V | Should -BeFalse
        }
    }

    Describe 'Get-ArchPostfix' {
        It 'returns empty string for AMD64' {
            $env:PYENV_FORCE_ARCH = 'AMD64'
            Get-ArchPostfix | Should -BeExactly ''
        }

        It 'returns -arm64 for ARM64' {
            $env:PYENV_FORCE_ARCH = 'ARM64'
            Get-ArchPostfix | Should -BeExactly '-arm64'
        }

        AfterEach {
            $env:PYENV_FORCE_ARCH = 'AMD64'
        }
    }

    Describe 'Set-PyenvProxy' {
        BeforeEach {
            $savedHttp = $env:http_proxy
            $savedHttps = $env:https_proxy
        }

        It 'sets proxy from http_proxy' {
            $env:http_proxy = 'http://proxy.example.com:8080'
            $env:https_proxy = $null
            Set-PyenvProxy
            [System.Net.WebRequest]::DefaultWebProxy | Should -Not -BeNullOrEmpty
        }

        It 'sets proxy from https_proxy when http_proxy unset' {
            $env:http_proxy = $null
            $env:https_proxy = 'https://proxy.example.com:8080'
            Set-PyenvProxy
            [System.Net.WebRequest]::DefaultWebProxy | Should -Not -BeNullOrEmpty
        }

        It 'does nothing when no proxy env set' {
            $env:http_proxy = $null
            $env:https_proxy = $null
            { Set-PyenvProxy } | Should -Not -Throw
        }

        It 'strips credentials from proxy URL' {
            $env:http_proxy = 'http://user:pass@proxy.example.com:8080'
            Set-PyenvProxy
            [System.Net.WebRequest]::DefaultWebProxy | Should -Not -BeNullOrEmpty
        }

        AfterEach {
            $env:http_proxy = $savedHttp
            $env:https_proxy = $savedHttps
        }
    }

    Describe 'Write-Pyenv* logging functions' {
        It 'Write-PyenvInfo does not throw' {
            { Write-PyenvInfo 'test info message' } | Should -Not -Throw
        }

        It 'Write-PyenvError does not throw' {
            { Write-PyenvError 'test error message' } | Should -Not -Throw
        }

        It 'Write-PyenvWarn does not throw' {
            { Write-PyenvWarn 'test warn message' } | Should -Not -Throw
        }
    }

    Describe 'Get-PyenvExtensions' {
        It 'returns hashtable with executable extensions' {
            $exts = Get-PyenvExtensions
            $exts | Should -BeOfType [hashtable]
            $exts.ContainsKey('.exe') | Should -BeTrue
        }

        It 'includes .py and .pyw when -AddPy specified' {
            $exts = Get-PyenvExtensions -AddPy
            $exts.ContainsKey('.py') | Should -BeTrue
            $exts.ContainsKey('.pyw') | Should -BeTrue
        }
    }

    Describe 'Get-PyenvExtensionsNoPeriod' {
        It 'returns extensions without leading period' {
            $exts = Get-PyenvExtensionsNoPeriod
            $exts.ContainsKey('exe') | Should -BeTrue
            $exts.Keys | Where-Object { $_.StartsWith('.') } | Should -HaveCount 0
        }

        It 'includes py/pyw when -AddPy specified' {
            $exts = Get-PyenvExtensionsNoPeriod -AddPy
            $exts.ContainsKey('py') | Should -BeTrue
            $exts.ContainsKey('pyw') | Should -BeTrue
        }
    }

    Describe 'Get-BinDir' {
        It 'returns path for installed version' {
            $result = Get-BinDir -Version '3.9.7'
            $result | Should -Be (Join-Path $testEnv.PyenvPath 'versions' '3.9.7')
        }

        It 'exits with error for missing version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'which' 'python99'
            $result.ExitCode | Should -Not -Be 0
        }
    }
}


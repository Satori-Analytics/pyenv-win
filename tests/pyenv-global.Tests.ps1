#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-global.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1', '3.11.0')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'reading global version' {
        It 'shows no global when version file missing' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global'
            $result.Stdout | Should -Match 'no global version configured'
        }

        It 'shows global version when set' {
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            Set-Content $globalFile -Value '3.9.7'
            $result = Invoke-Pyenv -Env $script:testEnv 'global'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
        }

        It 'shows multiple global versions' {
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            Set-Content $globalFile -Value "3.9.7`n3.10.1"
            $result = Invoke-Pyenv -Env $script:testEnv 'global'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
            $result.Stdout | Should -Match '3\.10\.1'
        }
    }

    Describe 'setting global version' {
        BeforeEach {
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            if (Test-Path $globalFile) { Remove-Item $globalFile -Force }
        }

        It 'sets a single global version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global' '3.9.7'
            $result.ExitCode | Should -Be 0
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            $content = Get-Content $globalFile
            $content | Should -Contain '3.9.7'
        }

        It 'sets multiple global versions' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global' '3.9.7' '3.10.1'
            $result.ExitCode | Should -Be 0
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            $content = Get-Content $globalFile
            $content | Should -Contain '3.9.7'
            $content | Should -Contain '3.10.1'
        }

        It 'errors on uninstalled version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global' '9.9.9'
            $result.ExitCode | Should -Not -Be 0
            $result.Stdout | Should -Match "Install python '9\.9\.9'"
        }
    }

    Describe '--unset' {
        It 'removes the global version file' {
            $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
            Set-Content $globalFile -Value '3.9.7'
            $result = Invoke-Pyenv -Env $script:testEnv 'global' '--unset'
            $result.ExitCode | Should -Be 0
            Test-Path $globalFile | Should -BeFalse
        }
    }

    Describe 'help' {
        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv global'
        }
    }
}

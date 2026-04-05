#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-local.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1', '3.11.0')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'reading local version' {
        It 'shows no local when .python-version missing' {
            $result = Invoke-Pyenv -Env $script:testEnv 'local'
            $result.Stdout | Should -Match 'no local version configured'
        }

        It 'shows local version when set' {
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            Set-Content $localVersionFile -Value '3.10.1'
            $result = Invoke-Pyenv -Env $script:testEnv 'local'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.10\.1'
        }

        It 'shows multiple local versions' {
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            Set-Content $localVersionFile -Value "3.9.7`n3.10.1"
            $result = Invoke-Pyenv -Env $script:testEnv 'local'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
            $result.Stdout | Should -Match '3\.10\.1'
        }
    }

    Describe 'setting local version' {
        BeforeEach {
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            if (Test-Path $localVersionFile) { Remove-Item $localVersionFile -Force }
        }

        It 'sets a single local version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'local' '3.9.7'
            $result.ExitCode | Should -Be 0
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            $content = Get-Content $localVersionFile
            $content | Should -Contain '3.9.7'
        }

        It 'sets multiple local versions' {
            $result = Invoke-Pyenv -Env $script:testEnv 'local' '3.9.7' '3.10.1'
            $result.ExitCode | Should -Be 0
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            $content = Get-Content $localVersionFile
            $content | Should -Contain '3.9.7'
            $content | Should -Contain '3.10.1'
        }

        It 'errors on uninstalled version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'local' '9.9.9'
            $result.ExitCode | Should -Not -Be 0
            $result.Stdout | Should -Match "Install python '9\.9\.9'"
        }
    }

    Describe '--unset' {
        It 'removes the .python-version file' {
            $localVersionFile = Join-Path $script:testEnv.LocalPath '.python-version'
            Set-Content $localVersionFile -Value '3.9.7'
            $result = Invoke-Pyenv -Env $script:testEnv 'local' '--unset'
            $result.ExitCode | Should -Be 0
            Test-Path $localVersionFile | Should -BeFalse
        }
    }

    Describe 'help' {
        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'local' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv local'
        }
    }
}

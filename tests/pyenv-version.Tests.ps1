#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-version.ps1 / pyenv-version-name.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -GlobalVersion '3.9.7'
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'pyenv version' {
        It 'shows current version with origin' {
            $result = Invoke-Pyenv -Env $script:testEnv 'version'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
            $result.Stdout | Should -Match 'set by'
        }

        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'version' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv version'
        }
    }

    Describe 'pyenv version-name' {
        It 'shows current version name only' {
            $result = Invoke-Pyenv -Env $script:testEnv 'version-name'
            $result.ExitCode | Should -Be 0
            $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
            $lines | Should -Contain '3.9.7'
        }

        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'version-name' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv version-name'
        }
    }

    Describe 'pyenv --version' {
        It 'displays pyenv-win version number' {
            $result = Invoke-Pyenv -Env $script:testEnv '--version'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'pyenv \d+\.\d+\.\d+'
        }

        It 'displays version via -v flag' {
            $result = Invoke-Pyenv -Env $script:testEnv '-v'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'pyenv \d+\.\d+\.\d+'
        }
    }
}

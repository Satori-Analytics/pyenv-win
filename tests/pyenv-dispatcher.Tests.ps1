#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv.ps1 dispatcher' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -GlobalVersion '3.9.7'
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'command routing' {
        It 'routes to global command' {
            $result = Invoke-Pyenv -Env $script:testEnv 'global'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
        }

        It 'routes to versions command' {
            $result = Invoke-Pyenv -Env $script:testEnv 'versions'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
        }

        It 'routes to version command' {
            $result = Invoke-Pyenv -Env $script:testEnv 'version'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match '3\.9\.7'
        }
    }

    Describe 'help routing' {
        It 'shows help with /? flag' {
            $result = Invoke-Pyenv -Env $script:testEnv '/?'
            $result.Stdout | Should -Match 'Usage: pyenv <command>'
        }

        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv <command>'
        }

        It 'shows command-specific help via help <command>' {
            $result = Invoke-Pyenv -Env $script:testEnv 'help' 'versions'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv versions'
        }
    }

    Describe 'version flags' {
        It 'shows version with --version' {
            $result = Invoke-Pyenv -Env $script:testEnv '--version'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'pyenv \d+\.\d+\.\d+'
        }

        It 'shows version with -v' {
            $result = Invoke-Pyenv -Env $script:testEnv '-v'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'pyenv \d+\.\d+\.\d+'
        }
    }

    Describe 'exec command' {
        It 'shows usage when no command to exec given' {
            $result = Invoke-Pyenv -Env $script:testEnv 'exec'
            $result.ExitCode | Should -Be 1
            $result.Stdout | Should -Match 'Usage: pyenv exec'
        }

        It 'shows exec help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'exec' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv exec'
        }
    }

    Describe 'unknown command' {
        It 'errors on unknown command' {
            $result = Invoke-Pyenv -Env $script:testEnv 'nonexistent'
            $result.ExitCode | Should -Be 1
        }
    }
}

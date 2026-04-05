#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-prefix.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -GlobalVersion '3.9.7'
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'shows prefix for current version' {
        $result = Invoke-Pyenv -Env $script:testEnv 'prefix'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
    }

    It 'shows prefix for specified version' {
        $result = Invoke-Pyenv -Env $script:testEnv 'prefix' '3.10.1'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.10\.1'
    }

    It 'errors for uninstalled version' {
        $result = Invoke-Pyenv -Env $script:testEnv 'prefix' '9.9.9'
        $result.ExitCode | Should -Not -Be 0
        $result.Stdout | Should -Match 'not installed'
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'prefix' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv prefix'
    }
}

Describe 'pyenv-root.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'displays the pyenv root directory' {
        $result = Invoke-Pyenv -Env $script:testEnv 'root'
        $result.ExitCode | Should -Be 0
        $result.Stdout.Trim() | Should -Not -BeNullOrEmpty
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'root' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv root'
    }
}

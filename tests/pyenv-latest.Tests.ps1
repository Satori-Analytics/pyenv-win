#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-latest.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.5', '3.9.7', '3.10.1', '3.11.0')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'finds latest installed version matching prefix' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest' '3.9'
        $result.ExitCode | Should -Be 0
        $result.Stdout.Trim() | Should -Be '3.9.7'
    }

    It 'finds latest installed version with major prefix' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest' '3'
        $result.ExitCode | Should -Be 0
        $result.Stdout.Trim() | Should -Be '3.11.0'
    }

    It 'returns error for no matching prefix' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest' '2.7'
        $result.ExitCode | Should -Be 1
        $result.Stdout | Should -Match 'no installed versions match'
    }

    It 'quiet mode suppresses error messages' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest' '-q' '2.7'
        $result.ExitCode | Should -Be 1
        $result.Stdout.Trim() | Should -BeNullOrEmpty
    }

    It 'shows usage when no prefix given' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest'
        $result.ExitCode | Should -Be 1
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'latest' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv latest'
    }
}

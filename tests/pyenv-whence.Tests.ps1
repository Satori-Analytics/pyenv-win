#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-whence.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'lists versions containing python executable' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' 'python'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
        $result.Stdout | Should -Match '3\.10\.1'
    }

    It 'lists versions containing pip' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' 'pip'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
        $result.Stdout | Should -Match '3\.10\.1'
    }

    It 'returns versioned python results' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' 'python39'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
    }

    It 'returns exit 1 for nonexistent command' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' 'nonexistent'
        $result.ExitCode | Should -Be 1
    }

    It 'shows paths with --path flag' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' '--path' 'python'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'python\.exe'
        $result.Stdout | Should -Match '3\.9\.7'
        $result.Stdout | Should -Match '3\.10\.1'
    }

    It 'shows usage when no command given' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence'
        $result.ExitCode | Should -Be 1
        $result.Stdout | Should -Match 'Usage: pyenv whence'
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'whence' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv whence'
    }
}

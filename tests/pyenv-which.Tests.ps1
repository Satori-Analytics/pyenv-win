#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-which.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') -GlobalVersion '3.9.7'
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'finds python executable' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'python'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
        $result.Stdout | Should -Match 'python\.exe'
    }

    It 'finds python3 executable' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'python3'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
    }

    It 'finds pip in Scripts directory' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'pip'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Scripts'
        $result.Stdout | Should -Match 'pip'
    }

    It 'finds versioned pip executable' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'pip3.9'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'pip3\.9'
    }

    It 'returns exit code 127 for missing command' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'nonexistent'
        $result.ExitCode | Should -Be 127
        $result.Stdout | Should -Match 'command not found'
    }

    It 'suggests other versions when command not found but exists elsewhere' {
        # python39.exe only exists in 3.9.7; set global to 3.10.1 so it is not found
        $globalFile = Join-Path $script:testEnv.PyenvPath 'version'
        Set-Content $globalFile -Value '3.10.1'

        $result = Invoke-Pyenv -Env $script:testEnv 'which' 'python39'
        $result.ExitCode | Should -Be 127
        $result.Stdout | Should -Match 'command not found'
        $result.Stdout | Should -Match '3\.9\.7'

        # Restore
        Set-Content $globalFile -Value '3.9.7'
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv which'
    }

    It 'shows usage with no arguments' {
        $result = Invoke-Pyenv -Env $script:testEnv 'which'
        $result.ExitCode | Should -Be 1
        $result.Stdout | Should -Match 'Usage: pyenv which'
    }
}

#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-help.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'displays help text with version' {
        $result = Invoke-Pyenv -Env $script:testEnv 'help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv <command>'
        $result.Stdout | Should -Match 'pyenv \d+\.\d+\.\d+'
    }

    It 'lists available commands' {
        $result = Invoke-Pyenv -Env $script:testEnv 'help'
        $result.Stdout | Should -Match 'global'
        $result.Stdout | Should -Match 'local'
        $result.Stdout | Should -Match 'install'
        $result.Stdout | Should -Match 'versions'
        $result.Stdout | Should -Match 'which'
    }

    It 'shows help via --help flag' {
        $result = Invoke-Pyenv -Env $script:testEnv '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv <command>'
    }

    It 'shows help via -h flag' {
        $result = Invoke-Pyenv -Env $script:testEnv '-h'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv <command>'
    }

    It 'shows help when called with /? flag' {
        $result = Invoke-Pyenv -Env $script:testEnv '/?'
        $result.Stdout | Should -Match 'Usage: pyenv <command>'
    }

    It 'displays documentation link' {
        $result = Invoke-Pyenv -Env $script:testEnv 'help'
        $result.Stdout | Should -Match 'https://github.com/satori-analytics/pyenv-win'
    }

    It 'shows command-specific help via help <command>' {
        $result = Invoke-Pyenv -Env $script:testEnv 'help' 'global'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv global'
    }
}

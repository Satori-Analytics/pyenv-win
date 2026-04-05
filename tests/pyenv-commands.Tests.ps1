#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-commands.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'lists available commands' {
        $result = Invoke-Pyenv -Env $script:testEnv 'commands'
        $result.ExitCode | Should -Be 0
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $lines | Should -Contain 'global'
        $lines | Should -Contain 'local'
        $lines | Should -Contain 'install'
        $lines | Should -Contain 'versions'
        $lines | Should -Contain 'which'
        $lines | Should -Contain 'whence'
        $lines | Should -Contain 'shell'
        $lines | Should -Contain 'exec'
        $lines | Should -Contain 'rehash'
        $lines | Should -Contain 'help'
    }

    It 'outputs commands in sorted order' {
        $result = Invoke-Pyenv -Env $script:testEnv 'commands'
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $sorted = $lines | Sort-Object
        $lines | Should -Be $sorted
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'commands' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv commands'
    }

    It 'does not list hidden commands' {
        $result = Invoke-Pyenv -Env $script:testEnv 'commands'
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $lines | Should -Not -Contain 'version-name'
        $lines | Should -Not -Contain 'update-ci'
    }
}

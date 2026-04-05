#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-versions.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1', '3.11.0') -GlobalVersion '3.10.1'
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'lists all installed versions' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '3\.9\.7'
        $result.Stdout | Should -Match '3\.10\.1'
        $result.Stdout | Should -Match '3\.11\.0'
    }

    It 'marks current version with asterisk' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match '\* 3\.10\.1'
    }

    It 'shows set-by info for current version' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions'
        $result.Stdout | Should -Match '3\.10\.1 \(set by'
    }

    It 'does not mark non-current versions' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions'
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $v397line = $lines | Where-Object { $_ -match '3\.9\.7' }
        $v397line | Should -Match '^\s+3\.9\.7'
    }

    It 'lists bare version names with --bare' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions' '--bare'
        $result.ExitCode | Should -Be 0
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $lines | Should -Contain '3.9.7'
        $lines | Should -Contain '3.10.1'
        $lines | Should -Contain '3.11.0'
        # Bare should not have asterisks
        $result.Stdout | Should -Not -Match '\*'
    }

    It 'shows empty output when no versions installed' {
        $emptyEnv = New-PyenvTestEnvironment
        $result = Invoke-Pyenv -Env $emptyEnv 'versions'
        $result.ExitCode | Should -Be 0
        $trimmed = $result.Stdout.Trim()
        $trimmed | Should -BeNullOrEmpty
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'versions' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv versions'
    }
}

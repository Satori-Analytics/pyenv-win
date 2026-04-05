#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-rehash.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    It 'creates shims when versions are installed' {
        $result = Invoke-Pyenv -Env $script:testEnv 'rehash'
        $result.ExitCode | Should -Be 0
        # Shims directory should contain files
        $shimsDir = $script:testEnv.ShimsPath
        $shimFiles = Get-ChildItem $shimsDir -File -ErrorAction SilentlyContinue
        $shimFiles.Count | Should -BeGreaterThan 0
    }

    It 'creates python shim' {
        Invoke-Pyenv -Env $script:testEnv 'rehash' | Out-Null
        $shimsDir = $script:testEnv.ShimsPath
        $pythonShim = Get-ChildItem $shimsDir -File | Where-Object { $_.BaseName -ieq 'python' }
        $pythonShim | Should -Not -BeNullOrEmpty
    }

    It 'shows message when no versions installed' {
        $emptyEnv = New-PyenvTestEnvironment
        $result = Invoke-Pyenv -Env $emptyEnv 'rehash'
        $result.Stdout | Should -Match 'No version installed'
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'rehash' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv rehash'
    }
}

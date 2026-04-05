#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-shims.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
        # Create some mock shim files
        $shimsDir = $script:testEnv.ShimsPath
        Set-Content (Join-Path $shimsDir 'python.bat') -Value '@echo off'
        Set-Content (Join-Path $shimsDir 'pip.bat') -Value '@echo off'
        Set-Content (Join-Path $shimsDir 'python') -Value '#!/bin/sh'
    }

    It 'lists shim files with full paths' {
        $result = Invoke-Pyenv -Env $script:testEnv 'shims'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'python'
        $result.Stdout | Should -Match 'pip'
    }

    It 'lists shim files with short names' {
        $result = Invoke-Pyenv -Env $script:testEnv 'shims' '--short'
        $result.ExitCode | Should -Be 0
        $lines = $result.Stdout -split "`n" | Where-Object { $_ -ne '' }
        $lines | Should -Contain 'python.bat'
        $lines | Should -Contain 'pip.bat'
    }

    It 'returns empty output when no shims exist' {
        $emptyEnv = New-PyenvTestEnvironment
        $result = Invoke-Pyenv -Env $emptyEnv 'shims'
        $result.ExitCode | Should -Be 0
    }

    It 'shows help with --help' {
        $result = Invoke-Pyenv -Env $script:testEnv 'shims' '--help'
        $result.ExitCode | Should -Be 0
        $result.Stdout | Should -Match 'Usage: pyenv shims'
    }
}

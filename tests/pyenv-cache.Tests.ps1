#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-cache.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1') `
            -CacheFiles @('python-3.9.7-amd64.exe', 'python-3.10.1-amd64.exe', 'python-2.7.18.msi')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'list (default)' {
        It 'lists cached installers' {
            $result = Invoke-Pyenv -Env $script:testEnv 'cache'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'python 3\.9\.7'
            $result.Stdout | Should -Match 'python 3\.10\.1'
            $result.Stdout | Should -Match 'installer\(s\)'
        }

        It 'shows no-cache message when cache empty' {
            $emptyEnv = New-PyenvTestEnvironment
            $result = Invoke-Pyenv -Env $emptyEnv 'cache'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'No cached installers'
        }
    }

    Describe '--clear' {
        It 'removes all cached files' {
            $clearEnv = New-PyenvTestEnvironment -CacheFiles @('python-3.9.7-amd64.exe')
            # Verify cache file exists before clear
            $cacheFile = Join-Path $clearEnv.CachePath 'python-3.9.7-amd64.exe'
            Test-Path $cacheFile | Should -BeTrue

            $result = Invoke-Pyenv -Env $clearEnv 'cache' '--clear'
            $result.ExitCode | Should -Be 0
            # Cache directory should be removed
            Test-Path $clearEnv.CachePath | Should -BeFalse
        }
    }

    Describe '--sync' {
        It 'removes installers for uninstalled versions' {
            $syncEnv = New-PyenvTestEnvironment -Versions @('3.9.7') `
                -CacheFiles @('python-3.9.7-amd64.exe', 'python-3.10.1-amd64.exe')
            # Verify both cache files exist
            Test-Path (Join-Path $syncEnv.CachePath 'python-3.9.7-amd64.exe') | Should -BeTrue
            Test-Path (Join-Path $syncEnv.CachePath 'python-3.10.1-amd64.exe') | Should -BeTrue

            $result = Invoke-Pyenv -Env $syncEnv 'cache' '--sync'
            $result.ExitCode | Should -Be 0
            # 3.9.7 cache should still exist, 3.10.1 should be removed
            $remaining = Get-ChildItem $syncEnv.CachePath -File -ErrorAction SilentlyContinue
            $remainingNames = @($remaining.Name)
            $remainingNames | Should -Contain 'python-3.9.7-amd64.exe'
            $remainingNames | Should -Not -Contain 'python-3.10.1-amd64.exe'
        }

        It 'reports already in sync when no orphans' {
            $syncEnv = New-PyenvTestEnvironment -Versions @('3.9.7') `
                -CacheFiles @('python-3.9.7-amd64.exe')
            $result = Invoke-Pyenv -Env $syncEnv 'cache' '--sync'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'already in sync'
        }
    }

    Describe 'error handling' {
        It 'rejects --clear and --sync together' {
            $result = Invoke-Pyenv -Env $script:testEnv 'cache' '--clear' '--sync'
            $result.ExitCode | Should -Not -Be 0
            $result.Stdout | Should -Match 'mutually exclusive'
        }

        It 'rejects unrecognized options' {
            $result = Invoke-Pyenv -Env $script:testEnv 'cache' '--invalid'
            $result.ExitCode | Should -Not -Be 0
            $result.Stdout | Should -Match 'unrecognized option'
        }
    }

    Describe 'help' {
        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'cache' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv cache'
        }
    }
}

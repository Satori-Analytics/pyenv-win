#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-shell.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7', '3.10.1')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'reading shell version' {
        It 'shows no shell version when PYENV_VERSION not set' {
            $result = Invoke-Pyenv -Env $script:testEnv 'shell'
            $result.Stdout | Should -Match 'no shell-specific version configured'
        }
    }

    Describe 'setting shell version' {
        It 'errors on uninstalled version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'shell' '9.9.9'
            $result.Stdout | Should -Match "Install python '9\.9\.9'"
        }

        It 'accepts installed version without error' {
            $result = Invoke-Pyenv -Env $script:testEnv 'shell' '3.9.7'
            $result.Stdout | Should -Not -Match 'Install python'
        }
    }

    Describe 'help' {
        It 'shows help with --help' {
            $result = Invoke-Pyenv -Env $script:testEnv 'shell' '--help'
            $result.ExitCode | Should -Be 0
            $result.Stdout | Should -Match 'Usage: pyenv shell'
        }
    }

    Describe 'unit tests (dot-sourced)' {
        BeforeAll {
            $script:shellScript = Join-Path $script:testEnv.PyenvPath 'libexec' 'pyenv-shell.ps1'
        }

        It 'reports no version when PYENV_VERSION empty' {
            $savedPyenvVersion = $env:PYENV_VERSION
            try {
                if (Test-Path Env:PYENV_VERSION) { Remove-Item Env:PYENV_VERSION }
                $output = & $script:shellScript 2>&1
                ($output -join "`n") | Should -Match 'no shell-specific version configured'
            } finally {
                if ($savedPyenvVersion) { $env:PYENV_VERSION = $savedPyenvVersion }
            }
        }

        It 'reports current PYENV_VERSION when set' {
            $savedPyenvVersion = $env:PYENV_VERSION
            try {
                $env:PYENV_VERSION = '3.9.7'
                $output = & $script:shellScript 2>&1
                ($output -join "`n") | Should -Match '3\.9\.7'
            } finally {
                if ($savedPyenvVersion) { $env:PYENV_VERSION = $savedPyenvVersion }
                else { if (Test-Path Env:PYENV_VERSION) { Remove-Item Env:PYENV_VERSION } }
            }
        }

        It 'unsets PYENV_VERSION with --unset' {
            $savedPyenvVersion = $env:PYENV_VERSION
            try {
                $env:PYENV_VERSION = '3.9.7'
                & $script:shellScript '--unset' 2>&1 | Out-Null
                (Test-Path Env:PYENV_VERSION) | Should -BeFalse
            } finally {
                if ($savedPyenvVersion) { $env:PYENV_VERSION = $savedPyenvVersion }
            }
        }
    }
}

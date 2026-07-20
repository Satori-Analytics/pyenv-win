#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'shims.ps1' {
    BeforeAll {
        $env:PYENV_FORCE_ARCH = 'AMD64'
    }

    Describe 'New-BatchShim' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'creates a .bat shim file' {
            New-BatchShim -BaseName 'python'
            $batPath = Join-Path $script:testEnv.ShimsPath 'python.bat'
            Test-Path $batPath | Should -BeTrue
        }

        It 'shim contains correct content' {
            $batPath = Join-Path $script:testEnv.ShimsPath 'python.bat'
            $content = Get-Content $batPath -Raw
            $content | Should -Match '@echo off'
            $content | Should -Match 'pyenv exec'
        }

        It 'does not overwrite existing shim' {
            $batPath = Join-Path $script:testEnv.ShimsPath 'test-no-overwrite.bat'
            Set-Content -Path $batPath -Value 'original'
            New-BatchShim -BaseName 'test-no-overwrite'
            Get-Content $batPath -Raw | Should -Match 'original'
        }

        It 'adds rehash call for pip shims' {
            New-BatchShim -BaseName 'pip3'
            $batPath = Join-Path $script:testEnv.ShimsPath 'pip3.bat'
            $content = Get-Content $batPath -Raw
            $content | Should -Match 'pyenv rehash'
        }
    }

    Describe 'New-ShellShim' {
        BeforeAll {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
        }

        It 'creates a shell shim file (no extension)' {
            New-ShellShim -BaseName 'python'
            $shPath = Join-Path $script:testEnv.ShimsPath 'python'
            Test-Path $shPath | Should -BeTrue
        }

        It 'shim contains correct shebang and exec call' {
            $shPath = Join-Path $script:testEnv.ShimsPath 'python'
            $bytes = [System.IO.File]::ReadAllBytes($shPath)
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            $content | Should -Match '#!/bin/sh'
            $content | Should -Match 'pyenv exec'
        }

        It 'uses LF line endings' {
            $shPath = Join-Path $script:testEnv.ShimsPath 'python'
            $bytes = [System.IO.File]::ReadAllBytes($shPath)
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            $content | Should -Not -Match "`r`n"
        }

        It 'adds rehash call for pip shims' {
            New-ShellShim -BaseName 'pip'
            $shPath = Join-Path $script:testEnv.ShimsPath 'pip'
            $bytes = [System.IO.File]::ReadAllBytes($shPath)
            $content = [System.Text.Encoding]::UTF8.GetString($bytes)
            $content | Should -Match 'pyenv rehash'
        }
    }

    Describe 'Invoke-Rehash' {
        It 'creates shims for all installed versions' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.8.6', '3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            Invoke-Rehash

            # Should have python.bat, python shims
            $shimsPath = $script:testEnv.ShimsPath
            Test-Path (Join-Path $shimsPath 'python.bat') | Should -BeTrue
            Test-Path (Join-Path $shimsPath 'python') | Should -BeTrue
        }

        It 'creates the pip shim family from the Scripts scan' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            Invoke-Rehash

            # Scripts fixture ships pip.exe, pip3.exe, pip3.9.exe (TestHelper.ps1),
            # so every member of the pip family must get a .bat and shell shim.
            $shimsPath = $script:testEnv.ShimsPath
            foreach ($name in @('pip', 'pip3', 'pip3.9')) {
                Test-Path (Join-Path $shimsPath "$name.bat") | Should -BeTrue
                Test-Path (Join-Path $shimsPath $name) | Should -BeTrue
            }
        }

        It 'creates real shims for non-exe Scripts entries' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            Invoke-Rehash

            # hello.bat is a non-.exe console script in Scripts (TestHelper.ps1);
            # it must get a runnable .bat + shell shim, not be skipped.
            $shimsPath = $script:testEnv.ShimsPath
            Test-Path (Join-Path $shimsPath 'hello.bat') | Should -BeTrue
            Test-Path (Join-Path $shimsPath 'hello') | Should -BeTrue
        }

        It 'continues past a failing file and still creates pip shims' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            # Force one basename to throw; Invoke-Rehash must isolate it and
            # keep going so a single bad file can never block pip. The default
            # mock stands in for the real shim write (Pester does not fall back
            # to the original when a -ParameterFilter mock is present).
            Mock New-BatchShim -MockWith {
                New-Item -ItemType File -Path (Join-Path $script:testEnv.ShimsPath "$BaseName.bat") -Force | Out-Null
            }
            Mock New-BatchShim -ParameterFilter { $BaseName -eq 'python' } -MockWith { throw 'boom' }

            { Invoke-Rehash } | Should -Not -Throw

            $shimsPath = $script:testEnv.ShimsPath
            Test-Path (Join-Path $shimsPath 'pip.bat') | Should -BeTrue
        }

        It 'clears existing shims before regenerating' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)

            # Create stale shim
            Set-Content -Path (Join-Path $script:testEnv.ShimsPath 'stale.bat') -Value 'stale'
            Invoke-Rehash
            Test-Path (Join-Path $script:testEnv.ShimsPath 'stale.bat') | Should -BeFalse
        }

        It 'creates shims directory if missing' {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
            . (Initialize-PyenvLibraries -Env $script:testEnv)
            Remove-Item $script:testEnv.ShimsPath -Recurse -Force
            Invoke-Rehash
            Test-Path $script:testEnv.ShimsPath | Should -BeTrue
        }
    }
}



#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'install.ps1' {
    BeforeAll {
        $env:PYENV_FORCE_ARCH = 'AMD64'
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'Invoke-PythonDownload' {
        It 'downloads file to specified path' {
            Mock Invoke-WebRequest -MockWith {}
            $outFile = Join-Path $TestDrive 'download' 'test.exe'
            Invoke-PythonDownload -Url 'https://example.com/test.exe' -OutFile $outFile
            Should -Invoke Invoke-WebRequest -Times 1
        }

        It 'creates parent directory if missing' {
            Mock Invoke-WebRequest -MockWith {}
            $outFile = Join-Path $TestDrive 'new-dir' 'subdir' 'test.exe'
            Invoke-PythonDownload -Url 'https://example.com/test.exe' -OutFile $outFile
            Test-Path (Split-Path $outFile -Parent) | Should -BeTrue
        }
    }

    Describe 'Install-PythonZip' {
        It 'extracts zip to install path' {
            # Create a test zip
            $srcDir = Join-Path $TestDrive 'zip-src'
            New-Item -ItemType Directory -Path $srcDir -Force | Out-Null
            Set-Content -Path (Join-Path $srcDir 'python.exe') -Value 'fake'
            $zipPath = Join-Path $TestDrive 'test.zip'
            Compress-Archive -Path "$srcDir\*" -DestinationPath $zipPath -Force

            $installPath = Join-Path $TestDrive 'install-zip-test'
            $result = Install-PythonZip -ZipPath $zipPath -InstallPath $installPath
            $result | Should -Be 0
            Test-Path (Join-Path $installPath 'python.exe') | Should -BeTrue
        }

        It 'returns 1 if install path already exists' {
            $installPath = Join-Path $TestDrive 'existing-dir'
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            $zipPath = Join-Path $TestDrive 'dummy.zip'
            $result = Install-PythonZip -ZipPath $zipPath -InstallPath $installPath
            $result | Should -Be 1
        }

        It 'renames zip root dir when specified' {
            $srcDir = Join-Path $TestDrive 'zip-root-src'
            $rootDir = Join-Path $srcDir 'pypy-root'
            New-Item -ItemType Directory -Path $rootDir -Force | Out-Null
            Set-Content -Path (Join-Path $rootDir 'python.exe') -Value 'fake'
            $zipPath = Join-Path $TestDrive 'test-root.zip'
            Compress-Archive -Path "$srcDir\*" -DestinationPath $zipPath -Force

            $parentDir = Join-Path $TestDrive 'install-root-test-parent'
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            $installPath = Join-Path $parentDir 'final-name'
            Install-PythonZip -ZipPath $zipPath -InstallPath $installPath -ZipRootDir 'pypy-root'
        }
    }

    Describe 'New-PythonAliases' {
        It 'creates versioned python aliases' {
            $installPath = Join-Path $TestDrive 'alias-test'
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $installPath 'python.exe') -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $installPath 'pythonw.exe') -Force | Out-Null

            New-PythonAliases -InstallPath $installPath -VersionCode '3.9.7'

            Test-Path (Join-Path $installPath 'python3.exe') | Should -BeTrue
            Test-Path (Join-Path $installPath 'python39.exe') | Should -BeTrue
            Test-Path (Join-Path $installPath 'python3.9.exe') | Should -BeTrue
            Test-Path (Join-Path $installPath 'pythonw3.exe') | Should -BeTrue
            Test-Path (Join-Path $installPath 'pythonw39.exe') | Should -BeTrue
            Test-Path (Join-Path $installPath 'pythonw3.9.exe') | Should -BeTrue
        }

        It 'creates major-only aliases for single-segment version' {
            $installPath = Join-Path $TestDrive 'alias-major'
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            New-Item -ItemType File -Path (Join-Path $installPath 'python.exe') -Force | Out-Null

            New-PythonAliases -InstallPath $installPath -VersionCode '3'

            Test-Path (Join-Path $installPath 'python3.exe') | Should -BeTrue
        }
    }

    Describe 'Clear-InstallArtifacts' {
        It 'removes install directory and installer file' {
            $installPath = Join-Path $TestDrive 'clear-test-dir'
            $installFile = Join-Path $TestDrive 'clear-test.exe'
            New-Item -ItemType Directory -Path $installPath -Force | Out-Null
            New-Item -ItemType File -Path $installFile -Force | Out-Null

            Clear-InstallArtifacts -InstallPath $installPath -InstallFile $installFile

            Test-Path $installPath | Should -BeFalse
            Test-Path $installFile | Should -BeFalse
        }

        It 'handles nonexistent paths gracefully' {
            { Clear-InstallArtifacts -InstallPath (Join-Path $TestDrive 'nope') -InstallFile (Join-Path $TestDrive 'nope.exe') } |
                Should -Not -Throw
        }
    }
}



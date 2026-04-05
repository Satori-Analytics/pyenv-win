#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'registry.ps1' {
    BeforeAll {
        $env:PYENV_FORCE_ARCH = 'AMD64'
        $script:testEnv = New-PyenvTestEnvironment -Versions @('3.9.7')
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'Register-PythonVersion' {
        It 'skips pypy versions with warning' {
            Mock Write-PyenvWarn -MockWith {}
            Register-PythonVersion -Version 'pypy3.9-v7.3.11' -InstallPath (Join-Path $TestDrive 'pypy')
            Should -Invoke Write-PyenvWarn -Times 1
        }

        It 'skips when python.exe not found' {
            Mock New-Item -MockWith {}
            $emptyDir = Join-Path $TestDrive 'empty-version'
            New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null
            # Should not throw, just return
            { Register-PythonVersion -Version '3.9.7' -InstallPath $emptyDir } | Should -Not -Throw
        }
    }

    Describe 'Unregister-PythonVersion' {
        It 'does not throw when key does not exist' {
            { Unregister-PythonVersion -Version '3.99.0' } | Should -Not -Throw
        }

        It 'removes registry key when it exists' {
            $testKey = "HKCU:\SOFTWARE\Python\PythonCore\test-pester-3.9.7"
            New-Item -Path $testKey -Force | Out-Null
            Unregister-PythonVersion -Version 'test-pester-3.9.7'
            Test-Path $testKey | Should -BeFalse
        }
    }
}



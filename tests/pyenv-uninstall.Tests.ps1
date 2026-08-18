#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'pyenv-uninstall.ps1' {
    Describe 'version argument resolution' {
        BeforeEach {
            $script:testEnv = New-PyenvTestEnvironment -Versions @('3.11.9-arm64')
            # On an ARM64 machine, 'pyenv install 3.11.9' resolves (via
            # Get-ArchPostfix) to the '3.11.9-arm64' folder. Uninstall must
            # accept the same bare version back to remove what install created.
            $env:PYENV_FORCE_ARCH = 'ARM64'
        }

        AfterEach {
            $env:PYENV_FORCE_ARCH = 'AMD64'
        }

        It 'resolves a bare version to the installed arch-suffixed folder, same as install/global/local' {
            $result = Invoke-Pyenv -Env $script:testEnv 'uninstall' '-f' '3.11.9'

            $result.Stdout | Should -Match 'Successfully uninstalled 3\.11\.9-arm64'
            Test-Path (Join-Path $script:testEnv.VersionsPath '3.11.9-arm64') | Should -BeFalse
        }

        It 'succeeds when given the full arch-suffixed version' {
            $result = Invoke-Pyenv -Env $script:testEnv 'uninstall' '-f' '3.11.9-arm64'

            $result.Stdout | Should -Match 'Successfully uninstalled 3\.11\.9-arm64'
            Test-Path (Join-Path $script:testEnv.VersionsPath '3.11.9-arm64') | Should -BeFalse
        }

        It 'still reports not installed for a version that has no installed match' {
            $result = Invoke-Pyenv -Env $script:testEnv 'uninstall' '-f' '4.0.0'

            $result.Stdout | Should -Match "not installed"
            Test-Path (Join-Path $script:testEnv.VersionsPath '3.11.9-arm64') | Should -BeTrue
        }
    }
}

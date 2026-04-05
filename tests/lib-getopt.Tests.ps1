#Requires -Version 7
BeforeAll {
    . "$PSScriptRoot\TestHelper.ps1"
}

Describe 'getopt.ps1' {
    BeforeAll {
        $script:testEnv = New-PyenvTestEnvironment
        . (Initialize-PyenvLibraries -Env $script:testEnv)
    }

    Describe 'Get-ParsedOptions' {
        It 'parses long flags' {
            $result = Get-ParsedOptions -Arguments @('--verbose', '--force') -LongFlags @('verbose', 'force')
            $result.Options['verbose'] | Should -BeTrue
            $result.Options['force'] | Should -BeTrue
            $result.Remaining | Should -HaveCount 0
        }

        It 'parses --option=value syntax' {
            $result = Get-ParsedOptions -Arguments @('--name=hello', '--count=5')
            $result.Options['name'] | Should -Be 'hello'
            $result.Options['count'] | Should -Be '5'
        }

        It 'parses long options with separate value' {
            $result = Get-ParsedOptions -Arguments @('--output', '/tmp/file') -LongOptions @('output')
            $result.Options['output'] | Should -Be '/tmp/file'
            $result.Remaining | Should -HaveCount 0
        }

        It 'parses short flags with mapping' {
            $result = Get-ParsedOptions -Arguments @('-v', '-f') -ShortFlags @{ 'v' = 'verbose'; 'f' = 'force' }
            $result.Options['verbose'] | Should -BeTrue
            $result.Options['force'] | Should -BeTrue
        }

        It 'treats unknown short flags as raw keys' {
            $result = Get-ParsedOptions -Arguments @('-x')
            $result.Options['x'] | Should -BeTrue
        }

        It 'treats unknown long flags as boolean true' {
            $result = Get-ParsedOptions -Arguments @('--unknown')
            $result.Options['unknown'] | Should -BeTrue
        }

        It 'collects positional arguments' {
            $result = Get-ParsedOptions -Arguments @('3.9.7', '3.10.1') -LongFlags @()
            $result.Remaining | Should -Be @('3.9.7', '3.10.1')
            $result.Options.Count | Should -Be 0
        }

        It 'stops parsing after --' {
            $result = Get-ParsedOptions -Arguments @('--verbose', '--', '--not-a-flag', 'positional') `
                -LongFlags @('verbose')
            $result.Options['verbose'] | Should -BeTrue
            $result.Options.ContainsKey('not-a-flag') | Should -BeFalse
            $result.Remaining | Should -Be @('--not-a-flag', 'positional')
        }

        It 'handles mixed flags, options, and positional args' {
            $result = Get-ParsedOptions `
                -Arguments @('--force', '--output', 'file.txt', 'arg1', 'arg2') `
                -LongFlags @('force') `
                -LongOptions @('output')
            $result.Options['force'] | Should -BeTrue
            $result.Options['output'] | Should -Be 'file.txt'
            $result.Remaining | Should -Be @('arg1', 'arg2')
        }

        It 'handles empty arguments' {
            $result = Get-ParsedOptions -Arguments @()
            $result.Options.Count | Should -Be 0
            $result.Remaining | Should -HaveCount 0
        }

        It 'handles long option at end without value' {
            $result = Get-ParsedOptions -Arguments @('--output') -LongOptions @('output')
            $result.Options.ContainsKey('output') | Should -BeFalse
        }
    }
}


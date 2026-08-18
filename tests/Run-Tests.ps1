#Requires -Version 7
# Pester test runner with code coverage configuration

Import-Module Pester -MinimumVersion 5.0.0

$config = New-PesterConfiguration

# Test discovery
$config.Run.Path = Join-Path $PSScriptRoot '.'
$config.Run.Exit = $true

# Code coverage
# Scoped to lib/ only: bin/pyenv.ps1 and libexec/*.ps1 are exercised almost
# exclusively through Invoke-Pyenv, which runs the CLI in a separate pwsh.exe
# process (tests/TestHelper.ps1). Pester's coverage tracer only observes
# execution within its own process, so those files can never register a hit
# here regardless of tracer mode — including them just drags the percentage
# toward 0 without measuring anything real. Revisit if the dispatcher/libexec
# tests are ever refactored to run in-process.
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    (Join-Path $PSScriptRoot '..' 'pyenv-win' 'lib')
)
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'coverage.xml'
$config.CodeCoverage.CoveragePercentTarget = 75

# Test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $PSScriptRoot 'TestResults.xml'

# Output
$config.Output.Verbosity = 'Detailed'
$config.Output.CIFormat = 'GithubActions'

Invoke-Pester -Configuration $config

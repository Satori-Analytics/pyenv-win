#Requires -Version 7
# Pester test runner with code coverage configuration

Import-Module Pester -MinimumVersion 5.0.0

$config = New-PesterConfiguration

# Test discovery
$config.Run.Path = Join-Path $PSScriptRoot '.'
$config.Run.Exit = $true

# Code coverage
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(
    (Join-Path $PSScriptRoot '..' 'pyenv-win' 'bin')
    (Join-Path $PSScriptRoot '..' 'pyenv-win' 'lib')
    (Join-Path $PSScriptRoot '..' 'pyenv-win' 'libexec')
)
$config.CodeCoverage.OutputFormat = 'JaCoCo'
$config.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'coverage.xml'
$config.CodeCoverage.CoveragePercentTarget = 100

# Test results
$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $PSScriptRoot 'TestResults.xml'

# Output
$config.Output.Verbosity = 'Detailed'
$config.Output.CIFormat = 'GithubActions'

Invoke-Pester -Configuration $config

#Requires -Version 7
<#
.SYNOPSIS
    Build script for pyenv-win C# shim.
.DESCRIPTION
    Compiles src/shim.cs into bin/pyenv.exe using dotnet publish.
#>
param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$srcDir = Join-Path $PSScriptRoot 'pyenv-win' 'src'
$binDir = Join-Path $PSScriptRoot 'pyenv-win' 'bin'
$projectFile = Join-Path $srcDir 'shim.csproj'

if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Error "dotnet SDK is required to build the shim. Install from https://dot.net"
    exit 1
}

if ($Clean) {
    $publishDir = Join-Path $srcDir 'bin'
    if (Test-Path $publishDir) { Remove-Item $publishDir -Recurse -Force }
    $objDir = Join-Path $srcDir 'obj'
    if (Test-Path $objDir) { Remove-Item $objDir -Recurse -Force }
    Write-Host "Clean complete."
    exit 0
}

Write-Host "Building pyenv shim..."
dotnet publish $projectFile -c Release -o $binDir --nologo -v quiet

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed."
    exit 1
}

Write-Host "Built: $binDir\pyenv.exe"

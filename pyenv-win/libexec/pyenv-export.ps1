#Requires -Version 7
# pyenv export: Export a python environment to an external path
param()

if ($args.Count -lt 2 -or $args -contains '--help') {
    Write-Output "Usage: pyenv export <available_environment> <destination>"
    Write-Output ""
    Write-Output "Export your environment."
    Write-Output ""
    Write-Output "ex.) pyenv export 3.5.3 ./vendor/python"
    Write-Output ""
    Write-Output "To use when you want to build application-specific environment."
    if ($args -contains '--help') { exit 0 }
    exit 1
}

$src = $args[0] -replace '\\', '_'
$dst = $args[1]

$srcPath = Join-Path $script:PyenvVersions $src

if (-not (Test-Path $srcPath -PathType Container)) {
    Write-Output "$src does not exist"
    exit 1
}
if ([string]::IsNullOrEmpty($src) -or $src -in @('.', '..')) {
    Write-Output "available_environment `"$src`" is illegal env name"
    exit 1
}

Copy-Item -Path $srcPath -Destination $dst -Recurse -Force

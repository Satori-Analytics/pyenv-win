#Requires -Version 7
# pyenv duplicate: Creates a duplicate python environment
param()

if ($args.Count -eq 0 -or $args -contains '--help') {
    Write-Output "Usage: pyenv duplicate <available_environment> <new_environment>"
    Write-Output ""
    Write-Output "Duplicate your environment."
    Write-Output ""
    Write-Output "ex.) pyenv duplicate 3.5.3 myapp_env"
    Write-Output ""
    Write-Output "To use when you want to create a sandbox and"
    Write-Output "the environment when building application-specific environment."
    if ($args -contains '--help') { exit 0 }
    exit 1
}

$src = $args[0] -replace '\\', '_'
$dst = if ($args.Count -gt 1) { $args[1] -replace '\\', '_' } else { '' }

$srcPath = Join-Path $script:PyenvVersions $src
$dstPath = Join-Path $script:PyenvVersions $dst

if (-not (Test-Path $srcPath -PathType Container)) {
    Write-Output "$src does not exist"
    exit 1
}
if (Test-Path $dstPath -PathType Container) {
    Write-Output "$dst already exists"
    exit 1
}
if ([string]::IsNullOrEmpty($dst) -or $dst -in @('.', '..')) {
    Write-Output "new_environment `"$dst`" is illegal env name"
    exit 1
}
if ([string]::IsNullOrEmpty($src) -or $src -in @('.', '..')) {
    Write-Output "available_environment `"$src`" is illegal env name"
    exit 1
}

Copy-Item -Path $srcPath -Destination $dstPath -Recurse -Force

#Requires -Version 7
# pyenv-win argument parsing library
# Parses --long-flag, -s, --option=value, positional args

function Get-ParsedOptions {
    <#
    .SYNOPSIS
        Parse command-line arguments into options and remaining positional args.
    .PARAMETER Arguments
        The arguments to parse.
    .PARAMETER LongFlags
        Array of long flag names (without --) that take no value.
    .PARAMETER ShortFlags
        Hashtable mapping short flags (without -) to their long equivalents.
    .PARAMETER LongOptions
        Array of long option names (without --) that take a value.
    .OUTPUTS
        Returns @{ Options = @{}; Remaining = @() }
    #>
    param(
        [string[]]$Arguments,
        [string[]]$LongFlags = @(),
        [hashtable]$ShortFlags = @{},
        [string[]]$LongOptions = @()
    )

    $options = @{}
    $remaining = @()
    $stopParsing = $false

    $i = 0
    while ($i -lt $Arguments.Count) {
        $arg = $Arguments[$i]

        if ($stopParsing) {
            $remaining += $arg
            $i++
            continue
        }

        if ($arg -eq '--') {
            $stopParsing = $true
            $i++
            continue
        }

        if ($arg.StartsWith('--')) {
            $name = $arg.Substring(2)

            # Handle --option=value
            $eqIdx = $name.IndexOf('=')
            if ($eqIdx -ge 0) {
                $value = $name.Substring($eqIdx + 1)
                $name = $name.Substring(0, $eqIdx)
                $options[$name] = $value
            }
            elseif ($name -in $LongFlags) {
                $options[$name] = $true
            }
            elseif ($name -in $LongOptions) {
                $i++
                if ($i -lt $Arguments.Count) {
                    $options[$name] = $Arguments[$i]
                }
            }
            else {
                $options[$name] = $true
            }
        }
        elseif ($arg.StartsWith('-') -and $arg.Length -gt 1) {
            $short = $arg.Substring(1)
            if ($ShortFlags.ContainsKey($short)) {
                $options[$ShortFlags[$short]] = $true
            }
            else {
                $options[$short] = $true
            }
        }
        else {
            $remaining += $arg
        }

        $i++
    }

    return @{
        Options   = $options
        Remaining = $remaining
    }
}

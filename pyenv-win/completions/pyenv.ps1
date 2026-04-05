# PowerShell tab-completion for pyenv
# Add the following line to your $PROFILE to enable:
#   . "$env:PYENV_HOME\completions\pyenv.ps1"

Register-ArgumentCompleter -Native -CommandName pyenv -ScriptBlock {
    param($wordToComplete, $commandAST, $cursorPosition)

    $words = $commandAST.ToString().Trim() -split '\s+'

    if ($words.Count -le 2) {
        # Completing the subcommand itself
        $completions = & pyenv completions --complete 2>$null
    }
    else {
        # Completing arguments for a subcommand
        $completions = & pyenv completions $words[1] 2>$null
    }

    $completions | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

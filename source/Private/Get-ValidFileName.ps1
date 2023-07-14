function Get-ValidFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$String,

        [Parameter(
            HelpMessage = "Specify the character used to replace invalid characters. Default: '_' ",
            Mandatory = $false
        )]
        [ValidateSet('_', '-', '.', ' ')]
        [string]$ReplacementCharacter = '_'
    )

    if ([string]::IsNullOrEmpty($ReplacementCharacter)) {
        throw "Replacement character cannot be empty."
    }

    $illegalChars = [IO.Path]::GetInvalidFileNameChars() -join ''
    $regex = "[{0}]" -f [regex]::Escape($illegalChars)

    $String -replace $regex, $ReplacementCharacter
}

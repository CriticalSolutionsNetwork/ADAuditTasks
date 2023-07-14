function Convert-ExcelCellName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [AllowNull()]
        [string]$CellName
    )

    begin {
        # Handle $null value
        if ($null -eq $CellName) {
            return $null
        }
    }

    process {
        # Trim leading and trailing whitespace
        $convertedName = $CellName.Trim()

        # Remove any invalid characters at the beginning of the name
        while ($convertedName -ne "" -and $convertedName[0] -notin [char[]]'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_') {
            $convertedName = $convertedName.Substring(1)
        }

        # Replace any invalid characters in the middle or at the end
        $convertedName = [Regex]::Replace($convertedName, '[^a-zA-Z0-9_]', '_')

        # Ensure length is no more than 255 characters
        if ($convertedName.Length -gt 255) {
            $convertedName = $convertedName.Substring(0, 255)
        }

        # Handle empty or invalid cell names
        if ([string]::IsNullOrEmpty($convertedName)) {
            throw "Invalid cell name or empty string."
        }

        $convertedName
    }
}
<#
    .SYNOPSIS
        Gets the current date and time in a specified or default string format.
    .DESCRIPTION
        The Get-FormattedDate function returns the current date and time in a string format.
        If no format is specified, it defaults to "yyyy-MM-dd_hhmm.ss".
    .PARAMETER DateFormat
        The string format to use for the date and time. This parameter is optional.
        If not provided, the default format "yyyy-MM-dd_hhmm.ss" will be used.
        This parameter accepts pipeline input.
    .INPUTS
        System.String
        Accepts a string representing the date format as pipeline input.
    .OUTPUTS
        System.String
        The current date and time in the specified or default format.
    .EXAMPLE
        Get-FormattedDate
        Returns the current date and time in the default format "yyyy-MM-dd_hhmm.ss".
    .EXAMPLE
        Get-FormattedDate -DateFormat "MM/dd/yyyy"
        Returns the current date and time in the format "MM/dd/yyyy".
    .EXAMPLE
        "MM/dd/yyyy", "yyyy-MM-dd" | Get-FormattedDate
        Returns the current date and time in the formats "MM/dd/yyyy" and "yyyy-MM-dd".
    .NOTES
        For more information on custom date and time format strings, refer to:
        https://docs.microsoft.com/en-us/dotnet/standard/base-types/custom-date-and-time-format-strings
#>
function Get-FormattedDate {
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = 'Enter the date format string.')]
        [string]$DateFormat = "yyyy-MM-dd_hhmm.ss"
    )

    process {
        # Validate the date format string by attempting to format the current date
        try {
            $formattedDate = (Get-Date).ToString($DateFormat)
        }
        catch {
            Write-Error "Invalid date format string provided."
            return
        }

        return $formattedDate
    }
}

function Join-CSVFiles {
    <#
    .SYNOPSIS
    Joins multiple CSV files with the same headers into a single CSV file.
    .DESCRIPTION
    The Join-CSVFiles function takes an array of CSV file paths, reads their
    contents, and merges them into a single CSV file. The output file is saved
    to the specified folder. All input CSV files must have the same headers
    for the function to work correctly.
    .PARAMETER CSVFilePaths
    An array of strings containing the file paths of the CSV files to be merged.
    .PARAMETER AttachmentFolderPath
    The output folder path where the merged CSV file will be saved. Default location is "C:\temp\MergedCSV".
    .EXAMPLE
    Join-CSVFiles -CSVFilePaths @("C:\path\to\csv1.csv", "C:\path\to\csv2.csv") -AttachmentFolderPath "C:\path\to\output.csv"

    This example will merge the contents of "C:\path\to\csv1.csv" and
    "C:\path\to\csv2.csv" into a single CSV file and save it in "C:\path\to\output.csv".
    .NOTES
    Make sure the input CSV files have the same headers and formatting for the function to work properly.
    .OUTPUTS
    None. The function outputs a merged CSV file to the specified folder.
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Join-CSVFiles
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Join-CSVFiles
    #>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string[]]$CSVFilePaths,
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\MergedCSV"
    )

    begin {
        $Script:LogString = @()
        #Begin Logging
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        Build-DirectoryPath -DirectoryPath $AttachmentFolderPath
        [string]$OutputCsv = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDOMAIN).JoinedCSVs.csv"
        $baseHeaders = $null
        $mergedData = @()
        $Script:LogString += Write-AuditLog -Message "Starting CSV file merge"
    }
    process {
        foreach ($csvPath in $CSVFilePaths) {
            if (-not (Test-Path -Path $csvPath -PathType Leaf)) {
                $Script:LogString += Write-AuditLog -Message "File not found: $csvPath"
                continue
            }
            $csvContent = Import-Csv -Path $csvPath
            if ($null -eq $baseHeaders) {
                $baseHeaders = $csvContent[0].PSObject.Properties.Name
            }
            $currentHeaders = $csvContent[0].PSObject.Properties.Name
            if ($null -ne (Compare-Object -ReferenceObject $baseHeaders -DifferenceObject $currentHeaders)) {
                $Script:LogString += Write-AuditLog -Message "CSV headers do not match for file: $csvPath" -Severity Error
                continue
            }
            $mergedData += $csvContent
            $Script:LogString += Write-AuditLog -Message "Processed CSV file: $csvPath"
        }
    }
    end {
        $mergedData | Export-Csv -Path $OutputCsv -NoTypeInformation
        $Script:LogString += Write-AuditLog -Message "CSV file merge completed: $OutputCsv"
    }
}

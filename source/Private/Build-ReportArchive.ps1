function Build-ReportArchive {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Exports data to a CSV file, archives the CSV file and a log file in a zip file, and returns the path to the zip file.
    .DESCRIPTION
    The Build-ReportArchive function exports data to a CSV file, archives the CSV file and a log file in a zip file,
    and returns the path to the zip file. The function takes four parameters: $Export (the data to export),
    $csv (the name of the CSV file to create), $zip (the name of the zip file to create), and $log
    (the name of the log file to create). The function writes information about the export and archive process
    to the log file, and any errors that occur are also logged.
    .PARAMETER Export
    Specifies the data to export.
    .PARAMETER csv
    Specifies the name of the CSV file to create.
    .PARAMETER zip
    Specifies the name of the zip file to create.
    .PARAMETER log
    Specifies the name of the log file to create.
    .INPUTS
    The function accepts data as input from the pipeline.
    .OUTPUTS
    The function returns the path to the zip file that contains the archived CSV and log files.
    .EXAMPLE
    PS C:\> $Export = Get-ADUser -Filter *
    PS C:\> $CsvFile = "C:\Temp\ExportedData.csv"
    PS C:\> $ZipFile = "C:\Temp\ExportedData.zip"
    PS C:\> $LogFile = "C:\Temp\ExportedData.log"
    PS C:\> Build-ReportArchive -Export $Export -csv $CsvFile -zip $ZipFile -log $LogFile

    In this example, the Build-ReportArchive function is used to export all AD users to a CSV file,
    archive the CSV file and a log file in a zip file, and return the path to the zip file. The
    exported data is passed as input to the function using the $Export parameter, and the names
    of the CSV, zip, and log files are specified using the $csv, $zip, and $log parameters, respectively.
    .NOTES
    This function requires PowerShell 5.0 or later.
    .LINK
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.archive/compress-archive
    #>

    # Define function parameters with help messages
    param (
        [Parameter(
            HelpMessage = 'Active Directory User Enabled or not. Default $true',
            Position = 0,
            ValueFromPipelineByPropertyName = $true
        )]$Export,
        [Parameter(
            HelpMessage = 'CSV File Name',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )][string]$csv,
        [Parameter(
            HelpMessage = 'Zip File Name',
            Position = 2,
            ValueFromPipelineByPropertyName = $true
        )][string]$zip,
        [Parameter(
            HelpMessage = 'Log File Name',
            Position = 3,
            ValueFromPipelineByPropertyName = $true
        )][string]$log
    )
    # Initialize variables
    begin {
        $ExportFile = $Export
    }
    # Process each object in the pipeline
    process {
        try {
            # Export data to CSV file
            $ExportFile | Export-Csv $csv -NoTypeInformation -Encoding utf8 -ErrorVariable ExportErr -ErrorAction Stop
        }
        catch {
            # Write error to log and re-throw error
            $Script:LogString += Write-AuditLog -Message "Failed to export CSV: $csv" -Severity Error
            throw $ExportErr
        }
        # Get SHA-256 hash of the CSV file and write to log
        $Sha256Hash = (Get-FileHash $csv).Hash
        $Script:LogString += Write-AuditLog -Message "Exported CSV SHA256 hash: "
        $Script:LogString += Write-AuditLog -Message "$($Sha256Hash)"
        # Write information about the export directory and file path to log
        $Script:LogString += Write-AuditLog -Message "Directory: $AttachmentFolderPath"
        $Script:LogString += Write-AuditLog -Message "FilePath: $zip"
        # Export log to CSV file
        $Script:LogString | Export-Csv $log -NoTypeInformation -Encoding utf8
    }
    # Clean up and archive files
    end {
        Compress-Archive -Path $csv, $log -DestinationPath $zip -CompressionLevel Optimal
        Remove-Item $csv, $log -Force
        return [string[]]$zip
    }
} # End Function

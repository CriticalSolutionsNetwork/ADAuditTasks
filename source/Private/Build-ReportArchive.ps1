function Build-ReportArchive {
    [CmdletBinding()]
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
    begin {
        $ExportFile = $Export
    }
    process {
        try {
            $ExportFile | Export-Csv $csv -NoTypeInformation -Encoding utf8 -ErrorVariable ExportErr -ErrorAction Stop
        }
        catch {
            $Script:ADLogString += Write-AuditLog -Message "Failed to export CSV: $csv" -Severity Error
            throw $ExportErr
        }
        $Sha256Hash = (Get-FileHash $csv).Hash
        $Script:ADLogString += Write-AuditLog -Message "Exported CSV SHA256 hash: "
        $Script:ADLogString += Write-AuditLog -Message "$($Sha256Hash)"
        $Script:ADLogString += Write-AuditLog -Message "Directory: $AttachmentFolderPath"
        $Script:ADLogString += Write-AuditLog -Message "FilePath: $zip"
        $Script:ADLogString | Export-Csv $log -NoTypeInformation -Encoding utf8
    }
    end {
        Compress-Archive -Path $csv, $log -DestinationPath $zip -CompressionLevel Optimal
        Remove-Item $csv, $log -Force
        return [string[]]$zip
    }
}
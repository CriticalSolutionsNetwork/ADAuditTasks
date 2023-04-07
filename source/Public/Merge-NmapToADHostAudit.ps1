function Merge-NmapToADHostAudit {
    <#
    .SYNOPSIS
    Merges Nmap network audit data with Active Directory host audit data.
    .DESCRIPTION
    The Merge-NmapToADHostAudit function takes in two CSV files, one containing Nmap network
    audit data and the other containing Active Directory host audit data. It merges the data
    based on matching IP addresses and hostnames, and exports the merged data to a new CSV file.
    Additionally, it exports any unmatched Nmap data to a separate CSV file.
    .PARAMETER ADAuditCsv
    The path to the Active Directory host audit CSV file.
    .PARAMETER NmapCsv
    The path to the Nmap network audit CSV file.
    .PARAMETER AttachmentFolderPath
    The output folder path where the merged CSV file and unmatched Nmap data CSV file will
    be saved. Default location is "C:\temp\NmapToADHostAudit".
    .EXAMPLE
    Merge-NmapToADHostAudit -ADAuditCsv "C:\path\to\ADAudit.csv" -NmapCsv "C:\path\to\NmapAudit.csv" -AttachmentFolderPath "C:\path\to\output"

    This example will merge the Active Directory host audit data in "C:\path\to\ADAudit.csv"
    with the Nmap network audit data in "C:\path\to\NmapAudit.csv" and save the merged data
    to a new CSV file in "C:\path\to\output". Unmatched Nmap data will also be saved to a
    separate CSV file in the same output folder.
    .NOTES
    Make sure the input CSV files have the correct headers and formatting for the function to work properly.
    #>
    [CmdletBinding(HelpURI = "https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Merge-NmapToADHostAudit")]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$ADAuditCsv,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$NmapCsv,
        [Parameter(
            HelpMessage = 'Enter output folder path. Default: C:\temp\NmapXMLTOCSV',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\NmapToADHostAudit"
    )
    begin {
        $Script:LogString = @()
        #Begin Logging
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        Build-DirectoryPath -DirectoryPath $AttachmentFolderPath
        # Variables
        $adAuditData = Import-Csv -Path $ADAuditCsv
        $nmapData = Import-Csv -Path $NmapCsv
        [string]$OutputCsv = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDOMAIN).NmapJoinedADHostAudit.csv"
        [string]$UnmatchedNmapOutputCsv = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDOMAIN).NmapUnjoinedToADAudit.csv"
    }
    process {
        $Script:LogString += Write-AuditLog -Message "Processing Nmap data and grouping by hostname and IP address"
        # Group Nmap data by hostname and IP address
        $nmapDataGrouped = $nmapData | Group-Object -Property @{Expression = { $_.Hostname + $_.IPAddress } }
        # Combine the port, service, and version information
        $nmapDataGrouped = $nmapDataGrouped | ForEach-Object {
            $nmapRow = $_.Group[0]
            $hostname = $nmapRow.Hostname
            $ipAddresses = $_.Group | ForEach-Object { $_.IPAddress } | Sort-Object | Get-Unique
            $openPorts = $_.Group | ForEach-Object { $_.OpenPorts } | Sort-Object | Get-Unique
            $closedPorts = $_.Group | ForEach-Object { $_.ClosedPorts } | Sort-Object | Get-Unique
            $services = $_.Group | ForEach-Object { $_.Services } | Sort-Object | Get-Unique
            $versions = $_.Group | ForEach-Object { $_.Versions } | Sort-Object | Get-Unique
            $os = $_.Group | ForEach-Object { $_.OS } | Sort-Object | Get-Unique
            [PSCustomObject]@{
                Hostname    = $hostname
                IPAddress   = ($ipAddresses -join ', ')
                OpenPorts   = ($openPorts -join ', ')
                ClosedPorts = ($closedPorts -join ', ')
                Services    = ($services -join ', ')
                Versions    = ($versions -join ', ')
                OS          = ($os -join '; ')
            }
        }
        $mergedData = @()
        $unmatchedNmapData = @()
        $Script:LogString += Write-AuditLog -Message "Processing ADAudit data and merging with Nmap data"
        # Process ADAudit data
        foreach ($adRow in $adAuditData) {
            $ip = $adRow.IPv4Address
            $hostname = $adRow.DNSHostName
            # ROws by ip and hostname
            $nmapRowsByIP = $nmapDataGrouped | Where-Object { $_.IPAddress -eq $ip }
            $nmapRowsByHostname = $nmapDataGrouped | Where-Object { $_.Hostname -eq $hostname }
            $nmapRow = if ($nmapRowsByIP) { $nmapRowsByIP[0] } elseif ($nmapRowsByHostname) { $nmapRowsByHostname[0] } else { $null }
            if (!$hostname -and $nmapRow.Hostname) {
                $hostname = $nmapRow.Hostname
            }
            if (!$ip -and $nmapRow.IPAddress) {
                $ip = $nmapRow.IPAddress
            }
            # Find additional IPs with the same hostname
            $additionalIPs = ($nmapDataGrouped | Where-Object { $_.Hostname -eq $hostname -and $_.IPAddress -ne $ip } | ForEach-Object { $_.IPAddress }) -join ', '
            # Consolidate duplicate hostnames and IP addresses before removing them from $nmapDataGrouped
            if ($nmapRowsByHostname.Count -gt 1) {
                $openPorts = ($nmapRowsByHostname.OpenPorts | ForEach-Object { $_.Split(', ') } | Sort-Object | Get-Unique) -join ', '
                $closedPorts = ($nmapRowsByHostname.ClosedPorts | ForEach-Object { $_.Split(', ') } | Sort-Object | Get-Unique) -join ', '
                $services = ($nmapRowsByHostname.Services | ForEach-Object { $_.Split(', ') } | Sort-Object | Get-Unique) -join ', '
                $versions = ($nmapRowsByHostname.Versions | ForEach-Object { $_.Split(', ') } | Sort-Object | Get-Unique) -join ', '
                $os = ($nmapRowsByHostname.OS | ForEach-Object { $_.Split('; ') } | Sort-Object | Get-Unique) -join '; '
                $nmapRow = [PSCustomObject]@{
                    Hostname    = $hostname
                    IPAddress   = ($nmapRowsByHostname.IPAddress | Sort-Object | Get-Unique) -join ', '
                    OpenPorts   = $openPorts
                    ClosedPorts = $closedPorts
                    Services    = $services
                    Versions    = $versions
                    OS          = $os
                }
            }
            $nmapDataGrouped = $nmapDataGrouped | Where-Object { !($_.Hostname -eq $hostname) } # Remove the matched additional IPs

            $mergedRow = [PSCustomObject]@{
                DNSHostName            = $hostname
                ComputerName           = $adRow.ComputerName
                Enabled                = $adRow.Enabled
                IPv4Address            = $ip
                AdditionalIPs          = $additionalIPs
                IPv6Address            = $adRow.IPv6Address
                OperatingSystem        = $adRow.OperatingSystem
                LastLogon              = $adRow.LastLogon
                LastSeen               = $adRow.LastSeen
                Created                = $adRow.Created
                Modified               = $adRow.Modified
                Description            = $adRow.Description
                GroupMemberships       = $adRow.GroupMemberships
                OrgUnit                = $adRow.OrgUnit
                KerberosEncryptionType = $adRow.KerberosEncryptionType
                SPNs                   = $adRow.SPNs
                Nmap_OpenPorts         = $nmapRow.OpenPorts
                Nmap_ClosedPorts       = $nmapRow.ClosedPorts
                Nmap_Services          = $nmapRow.Services
                Nmap_Versions          = $nmapRow.Versions
                Nmap_OS                = $nmapRow.OS
            }
            $mergedData += $mergedRow
            $nmapDataGrouped = $nmapDataGrouped | Where-Object { $_.IPAddress -ne $nmapRow.IPAddress -and $_.Hostname -ne $nmapRow.Hostname } # Remove matched Nmap row
        }
        $Script:LogString += Write-AuditLog -Message "Processing unmatched Nmap data"
        # Process unmatched Nmap data
        foreach ($nmapRow in $nmapDataGrouped) {
            $mergedRow = [PSCustomObject]@{
                DNSHostName            = $nmapRow.Hostname
                ComputerName           = $null
                Enabled                = $null
                IPv4Address            = $nmapRow.IPAddress
                AdditionalIPs          = $null
                IPv6Address            = $null
                OperatingSystem        = $null
                LastLogon              = $null
                LastSeen               = $null
                Created                = $null
                Modified               = $null
                Description            = $null
                GroupMemberships       = $null
                OrgUnit                = $null
                KerberosEncryptionType = $null
                SPNs                   = $null
                Nmap_OpenPorts         = $nmapRow.OpenPorts
                Nmap_ClosedPorts       = $nmapRow.ClosedPorts
                Nmap_Services          = $nmapRow.Services
                Nmap_Versions          = $nmapRow.Versions
                Nmap_OS                = $nmapRow.OS
            }
            $mergedData += $mergedRow
            $unmatchedNmapData += $nmapRow # Add the unmatched Nmap row to the separate list
        }
    }
    end {
        $Script:LogString += Write-AuditLog -Message "Exporting merged data to CSV file: $OutputCsv"
        $mergedData | Export-Csv -Path $OutputCsv -NoTypeInformation
        $Script:LogString += Write-AuditLog -Message "Exporting unmatched Nmap data to CSV file: $UnmatchedNmapOutputCsv"
        $unmatchedNmapData | Export-Csv -Path $UnmatchedNmapOutputCsv -NoTypeInformation
        $Script:LogString += Write-AuditLog -Message "End Log"
    }
}
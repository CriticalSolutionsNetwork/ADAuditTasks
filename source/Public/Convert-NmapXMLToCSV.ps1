function Convert-NmapXMLToCSV {
<#
    .SYNOPSIS
    Converts an Nmap XML scan output file to a CSV file.
    .DESCRIPTION
    The Convert-NmapXMLToCSV function takes an Nmap XML scan output
    file as input and converts it into a CSV file. The function
    extracts information about IP addresses, hostnames, open and
    closed ports, services, service versions, and operating systems.
    The output CSV file is saved to the specified folder or to
    C:\temp\NmapXMLToCSV by default.
    .PARAMETER InputXml
    A string containing the full path to the Nmap XML file that needs to be converted.
    .PARAMETER AttachmentFolderPath
    The output folder path where the converted CSV file will be saved.
    Default location is "C:\temp\NmapXMLToCSV".
    .EXAMPLE
    Convert-NmapXMLToCSV -InputXml "C:\path\to\nmap.xml" -AttachmentFolderPath "C:\path\to\output"
    This example will convert the contents of "C:\path\to\nmap.xml" into a CSV file and save it in "C:\path\to\output".
    .NOTES
    Make sure the input Nmap XML file is properly formatted and contains the necessary
    information for the conversion to work correctly.
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Convert-NmapXMLToCSV
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Convert-NmapXMLToCSV
#>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Full Path to Nmap xml file.',
            Position = 0,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$InputXml,
        [Parameter(
            HelpMessage = 'Enter output folder path. Default: C:\temp\NmapXMLToCSV',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\NmapXMLToCSV"
    )

    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }

        Initialize-DirectoryPath -DirectoryPath $AttachmentFolderPath
        [xml]$nmapXml = Get-Content -Path $InputXml
        [string]$OutputCsv = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDOMAIN).nmapxmltocsv.csv"
        $csvData = @()
        Write-AuditLog "Processing Nmap XML file: $InputXml"
    }
    process {
        foreach ($scanHost in $nmapXml.nmaprun.host) {
            $ip = $scanHost.address | Where-Object { $_.addrtype -eq 'ipv4' } | Select-Object -ExpandProperty addr
            $hostname = $scanHost.hostnames.hostname.name
            # OS Match
            $osMatches = $scanHost.os.osmatch | ForEach-Object { $_.name }
            $os = $osMatches -join '; '
            # Ports
            $openPorts = @()
            $closedPorts = @()
            $services = @()
            $versions = @()
            foreach ($port in $scanHost.ports.port) {
                $state = $port.state.state
                $protocol = $port.protocol
                $portId = $port.portid
                $service = $port.service.name
                $version = $port.service.product
                # Port State
                if ($state -eq 'open') {
                    $openPorts += "$protocol/$portId"
                    $services += $service
                    $versions += $version
                }
                elseif ($state -eq 'closed') {
                    $closedPorts += "$protocol/$portId"
                }
            }
            $openPortsStr = $openPorts -join ', '
            $closedPortsStr = $closedPorts -join ', '
            $servicesStr = $services -join ', '
            $versionsStr = $versions -join ', '
            # PSObject
            $csvData += [PSCustomObject]@{
                IPAddress   = $ip -join ","
                Hostname    = $hostname
                OpenPorts   = $openPortsStr
                ClosedPorts = $closedPortsStr
                Services    = $servicesStr
                Versions    = $versionsStr
                OS          = $os
            }
            Write-AuditLog "Processed host: $ip"
        } # End Region Foreach
    }

    end {
        $csvData | Export-Csv -Path $OutputCsv -NoTypeInformation
        Write-AuditLog "Nmap XML file converted to CSV: $OutputCsv"
        Write-AuditLog -EndFunction
    }
}
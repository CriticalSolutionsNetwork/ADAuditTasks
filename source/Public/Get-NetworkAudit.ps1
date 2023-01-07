function Get-NetworkAudit {
    <#
    .SYNOPSIS
        Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.
    .DESCRIPTION
        Scans the network for open ports specified by the user or default ports if no ports are specified.
        Creates reports if report switch is active. Adds MACID vendor info if found.
    .NOTES
        Installs PSnmap if not found and can output a report, or just the results.
    .LINK
        Specify a URI to a help page, this will show when Get-Help -Online is used.
    .EXAMPLE
        Get-NetworkAudit -report
    .PARAMETER Ports
        Default ports are:
        "21", "22", "23", "25", "53", "67", "68", "80", "443", `
        "88", "464", "123", "135", "137", "138", "139", `
        "445", "389", "636", "514", "587", "1701", `
        "3268", "3269", "3389", "5985", "5986"

        If you want to supply a port, do so as an integer or an array of integers.
        "22","80","443", etc.
    .PARAMETER Report
        Specify this switch if you would like a report generated in C:\temp.
    .PARAMETER LocalSubnets
        Specify this switch to automatically scan subnets on the local network of the scanning device.
        Will not scan outside of the hosting device's subnet.
    .PARAMETER Computers
        Scan single host or array of hosts using Subet ID in CIDR Notation, IP, NETBIOS, or FQDN in "quotes"'
        For Example:
            "10.11.1.0/24","10.11.2.0/24"
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(
            ValueFromPipelineByPropertyName = $true,
            Position = 0
        )]
        [ValidateRange(1, 65535)]
        [int[]]$Ports,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Default',
            HelpMessage = 'Automatically find and scan local attached subnets',
            ValueFromPipelineByPropertyName = $true,
            Position = 1
        )]
        [switch]$LocalSubnets,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'Computers',
            HelpMessage = 'Scan host or array of hosts using Subet ID in CIDR Notation, IP, NETBIOS, or FQDN in "quotes"',
            ValueFromPipelineByPropertyName = $true,
            Position = 1
        )]
        [string[]]$Computers,
        [switch]$Report
    )
    begin {
        If (Get-Module -ListAvailable -Name "PSnmap") { Import-Module "PSnmap" } Else { Install-Module "PSnmap" -Force; Import-Module "PSnmap" }
        if (!($ports)) {
            [int[]]$ports = "21", "22", "23", "25", "53", "67", "68", "80", "443", `
                "88", "464", "123", "135", "137", "138", "139", `
                "445", "389", "636", "514", "587", "1701", `
                "3268", "3269", "3389", "5985", "5986"
        }
        $ouiobject = Invoke-RestMethod https://standards-oui.ieee.org/oui/oui.csv | ConvertFrom-Csv
    } # Begin Close
    process {
        if ($LocalSubnets) {
            $ConnectedNetworks = Get-NetIPConfiguration -Detailed | Where-Object { $_.Netadapter.status -eq "up" }
            $results = @()
            foreach ($network in $ConnectedNetworks) {
                # Get Network DHCP Server
                $DHCPServer = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $network.IPv4Address }).DHCPServer
                # Get Subnet as CIDR
                $Subnet = "$($network.IPv4DefaultGateway.nexthop)/$($network.IPv4Address.PrefixLength)"
                # Regex for IPV4 and IPV6 validation
                if (($subnet -match '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$') -or ($subnet -match '^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$')) {
                    # Create Network Scan Object
                    $NetworkAudit = Invoke-PSnmap -ComputerName $subnet -Port $ports -Dns -NoSummary -AddService
                    # Filter devices that don't ping as no results will be found.
                    $scan = $NetworkAudit | Where-Object { $_.Ping -eq $true }
                    Write-Verbose "##########################################"
                    Write-Verbose "Network scan for Subnet $Subnet completed."
                    Write-Verbose "DHCP Server: $($DHCPServer)"
                    Write-Verbose "Gateway: $($network.IPv4DefaultGateway.nexthop)"
                    Write-Verbose "##########################################"
                    $scan | ForEach-Object {
                        $org = ""
                        $macid = ((arp -a $_.ComputerName | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value).Replace("-", ":")
                        $macpop = $macid.replace(":", "")
                        $macsubstr = $macpop.Substring(0, 6)
                        $org = ($ouiobject | Where-Object { $_.assignment -eq $macsubstr })."Organization Name"
                        Add-Member -InputObject $_ -MemberType NoteProperty -Name MacID -Value $macid
                        if ($org) {
                            Add-Member -InputObject $_ -MemberType NoteProperty -Name ManufacturerName -Value $org
                        }
                        else {
                            Add-Member -InputObject $_ -MemberType NoteProperty -Name ManufacturerName -Value "Not Found"
                        }
                    }
                    # Normalize Subnet text for filename.
                    $subnetText = $(($subnet.Replace("/", ".CIDR.")))
                    # If report switch is true.
                    if ($report) {
                        $scan | Export-Csv "C:\temp\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDNSDOMAIN)_Subnet.$($subnetText)_DHCP.$($DHCPServer)_Gateway.$($network.IPv4DefaultGateway.nexthop).NetScan.csv" -NoTypeInformation
                    }
                    # Add scan to function output.
                    $results += $scan
                } # IF Subnet Match End
            } # End Foreach
        } # End If $LocalSubnets
        elseif ($Computers) {
            $Subnet = $Computers
            $results = Invoke-PSnmap -ComputerName $subnet -Port $ports -Dns -NoSummary -AddService | Where-Object { $_.Ping -eq $true }
            if ($Report) {
                $results | Export-Csv "C:\temp\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDNSDOMAIN)_HostScan.csv" -NoTypeInformation
            }
        }
    } # Process Close
    end {
        return $results
    }# End Close
}
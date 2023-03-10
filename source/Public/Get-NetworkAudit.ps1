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
        "21", "22", "23", "25", "53", "67", "68", "80", "443",
        "88", "464", "123", "135", "137", "138", "139",
        "445", "389", "636", "514", "587", "1701",
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
        [Int32[]]$Ports,
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
        # Create logging object
        $Script:LogString = @()
        # Begin Logging
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        # Check if PSnmap module is installed, if not install it.
        # Tested Version:
        # https://www.powershellgallery.com/packages/PSnmap/1.3.1 Updated: 7/18/2018
        $params = @{
            PublicModuleNames      = "PSnmap"
            PublicRequiredVersions = "1.3.1"
            Scope                  = "CurrentUser"
        }
        Initialize-ModuleEnv @params
        # Set default ports to scan
        if (!($ports)) {
            [Int32[]]$ports = "21", "22", "23", "25", "53", "67", "68", "80", "443", `
                "88", "464", "123", "135", "137", "138", "139", `
                "445", "389", "636", "514", "587", "1701", `
                "3268", "3269", "3389", "5985", "5986"
        }
        # Download and store the OUI CSV file from IEEE website
        $ouiobject = Invoke-RestMethod https://standards-oui.ieee.org/oui/oui.csv | ConvertFrom-Csv
    } # End of begin block
    process {
        if ($LocalSubnets) {
            # Get connected networks on the local device.
            $ConnectedNetworks = Get-NetIPConfiguration -Detailed | Where-Object { $_.Netadapter.status -eq "up" }
            $results = @()
            foreach ($network in $ConnectedNetworks) {
                # Get DHCP server for the network
                $DHCPServer = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $network.IPv4Address }).DHCPServer
                # Get subnet in CIDR format
                $Subnet = "$($network.IPv4DefaultGateway.nexthop)/$($network.IPv4Address.PrefixLength)"
                # Validate the subnet format for IPv4 and IPv6
                if (($subnet -match '^([0-9]{1,3}\.){3}[0-9]{1,3}(\/([0-9]|[1-2][0-9]|3[0-2]))?$') -or ($subnet -match '^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$')) {
                    # Create Network Scan Object
                    $Script:LogString += Write-AuditLog -Message "Beggining scan of subnet $($subnet) for the following ports:"
                    $Script:LogString += Write-AuditLog -Message "$(($ports | Out-String -Stream) -join ",")"
                    $NetworkAudit = Invoke-PSnmap -ComputerName $subnet -Port $ports -Dns -NoSummary -AddService
                    # Filter devices that don't ping as no results will be found.
                    $scan = $NetworkAudit | Where-Object { $_.Ping -eq $true }
                    # Write out information about the network scan.
                    $Script:LogString += Write-AuditLog -Message "##########################################"
                    $Script:LogString += Write-AuditLog -Message "Network scan for Subnet $($Subnet) completed."
                    $Script:LogString += Write-AuditLog -Message "DHCP Server: $($DHCPServer)"
                    $Script:LogString += Write-AuditLog -Message "Gateway: $($network.IPv4DefaultGateway.nexthop)"
                    $Script:LogString += Write-AuditLog -Message "##########################################"
                    $Script:LogString += Write-AuditLog -Message "Creating $(($scan).count) output objects."
                    # For each device in the scan, get MAC ID vendor information and add it as a NoteProperty to the object.
                    $scan | ForEach-Object {
                        $org = ""
                        $SaveErrorPref = $Script:ErrorActionPreference
                        $Script:ErrorActionPreference = 'SilentlyContinue'
                        $macid = ((arp -a "$($_.ComputerName)" | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value).Replace("-", ":")
                        $macpop = $macid.replace(":", "")
                        $macsubstr = $macpop.Substring(0, 6)
                        $org = ($ouiobject | Where-Object { $_.assignment -eq $macsubstr })."Organization Name"
                        $Script:ErrorActionPreference = $SaveErrorPref
                        Add-Member -InputObject $_ -MemberType NoteProperty -Name MacID -Value $macid
                        if ($org) {
                            Add-Member -InputObject $_ -MemberType NoteProperty -Name ManufacturerName -Value $org
                        }
                        else {
                            Add-Member -InputObject $_ -MemberType NoteProperty -Name ManufacturerName -Value "Not Found"
                        }
                    }
                    $Script:LogString += Write-AuditLog -Message "Created $(($scan).count) output objects for the following hosts:"
                    $Script:LogString += Write-AuditLog -Message "$(($scan | select-object "IP/DNS")."IP/DNS" -join ", ")"

                    # Normalize Subnet text for filename.
                    $subnetText = $(($subnet.Replace("/", "_")))
                    # If report switch is true, export the scan to a CSV file with a timestamped filename.
                    if ($report) {
                        $csv = "C:\temp\$((Get-Date).ToString('yyyy.MM.dd_hhmm.ss')).$($env:USERDOMAIN)_Subnet.$($subnetText)_DHCP.$($DHCPServer)_GW.$($network.IPv4DefaultGateway.nexthop).NetScan.csv"
                        $zip = $csv -replace ".csv", ".zip"
                        $log = $csv -replace ".csv", ".AuditLog.csv"
                        return Build-ReportArchive -Export $scan -csv $csv -zip $zip -log $log -ErrorVariable BuildErr
                    }
                    # Add the scan to the function output.
                    $results += $scan
                } # IF Subnet Match End
            } # End Foreach
        } # End If $LocalSubnets
        elseif ($Computers) {
            $Subnet = $Computers
            $results = Invoke-PSnmap -ComputerName $subnet -Port $ports -Dns -NoSummary -AddService | Where-Object { $_.Ping -eq $true }
            if ($Report) {
                $csv = "C:\temp\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDNSDOMAIN)_HostScan.csv"
                $zip = $csv -replace ".csv", ".zip"
                $log = $csv -replace ".csv", ".AuditLog.csv"
                return Build-ReportArchive -Export $results -csv $csv -zip $zip -log $log -ErrorVariable BuildErr
            }
        }
    <#
        try {
            ##
        }
        catch {
            throw $_.Exception
        }
    #>

    } # Process Close
    end {
        return $results
    }# End Close
}
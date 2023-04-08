function Get-NetworkAudit {
    <#
    .SYNOPSIS
    Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.
    .DESCRIPTION
    Scans the network for open ports specified by the user or default ports if no ports are specified.
    Creates reports if report switch is active. Adds MACID vendor info if found.
    .NOTES
    Installs PSnmap if not found and can output a report, or just the results.

    Throttle Limit Notes:
        Number of hosts: 65,536
        Scan rate: 32 hosts per second (Throttle limit)
        Total scan time: 2,048 seconds (65,536 / 32 = 2,048)
        Total data transferred: 65,536 kilobytes (1 kilobyte per host)
        Average network bandwidth: 32 kilobits per second (65,536 kilobytes / 2,048 seconds = 32 kilobits per second)
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
    .PARAMETER NoHops
    Don't allow scans across a gateway.
    .PARAMETER AddService
    Add the service typically associated with the port to the output.
    .PARAMETER Computers
    Scan single host or array of hosts using Subet ID in CIDR Notation, IP, NETBIOS, or FQDN in "quotes"'
    For Example:
        "10.11.1.0/24","10.11.2.0/24"
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-NetworkAudit
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $true, ConfirmImpact = 'High')]
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
        [Parameter(
            HelpMessage = 'Number of concurrent threads. Default: 32.',
            ValueFromPipelineByPropertyName = $true,
            Position = 2
        )]
        [Int32]$ThrottleLimit = 32,
        [Parameter(
            HelpMessage = 'Build a list of IPs that are not beyond 1 hop.',
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$NoHops,
        [Parameter(
            HelpMessage = 'Add Service Name to Port Number in output.',
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$AddService,
        [Parameter(
            HelpMessage = 'Output a report to C:\temp. The function will output the full path to the report as a string.',
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report,
        [Parameter(
            HelpMessage = 'Scan all hosts even if ping fails.',
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$ScanOnPingFail
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
        switch ($ScanOnPingFail) {
            $true { $noping = $true }
            Default { $noping = $false }
        }
    } # End of begin block
    process {
        if ($LocalSubnets) {
            # Get connected networks on the local device.
            $internetadapter = Get-NetIPConfiguration -Detailed | Where-Object { $_.NetProfile.IPv4Connectivity -eq "Internet" }
            $subnetcidr = "$($internetadapter.IPv4Address.IPAddress)/$($internetadapter.IPv4Address.PrefixLength)"
            $CalcSub = Invoke-PSipcalc -NetworkAddress $subnetcidr -Enumerate
            # Get subnet in CIDR format
            $subnet = "$($CalcSub.NetworkAddress)/$($CalcSub.NetworkLength)"
            # Get DHCP server for the network
            $DHCPServer = (Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPAddress -eq $($internetadapter.IPv4Address.IPAddress) }).DHCPServer
            # Create Network Scan Object
            $Script:LogString += Write-AuditLog -Message "Beggining scan of subnet $($subnet) for the following ports:"
            $Script:LogString += Write-AuditLog -Message "$(($ports | Out-String -Stream) -join ",")"
            # Begin Reigion Build NetworkAudit Object
            if ($NoHops) {
                $IPRange = $CalcSub.IPEnumerated
                # Use a foreach loop to test each IP address
                $NonRoutedIPs, $FailedIps = Get-QuickPing -IPRange $IPRange -TTL 1
                if ($null -ne $NonRoutedIPs) {
                    $Script:LogString += Write-AuditLog -Message "Local IPs object is populated."
                    $Script:LogString += Write-AuditLog -Message "Scan found $($NonRoutedIPs.count) IPs to scan."
                    $Script:LogString += Write-AuditLog -Message "There were $($FailedIps.count) IPs that failed to scan."
                    if ( $PSCmdlet.ShouldProcess( "NoHops", "Please confirm the following ips are ok to scan before proceeding:`n$($NonRoutedIPs -join ",")" ) ) {
                        $Script:LogString += Write-AuditLog -Message "Begin Invoke-PSnmap"
                        $NetworkAudit = Invoke-PSnmap -ComputerName $NonRoutedIPs -Port $ports -ThrottleLimit $ThrottleLimit -Dns -NoSummary -ScanOnPingFail:$ScanOnPingFail -AddService:$AddService
                    } # End Region If $PSCmdlet.ShouldProcess
                }
                else {
                    throw "No Hosts found to scan!"
                }
            }
            else {
                $NetworkAudit = Invoke-PSnmap -ComputerName $subnet -Port $ports -ThrottleLimit $ThrottleLimit -Dns -NoSummary -ScanOnPingFail:$ScanOnPingFail -AddService:$AddService
            }
            # End Reigion Build Network Audit Object
            # Write out information about the network scan.
            $Script:LogString += Write-AuditLog -Message "##########################################"
            $Script:LogString += Write-AuditLog -Message "Network scan for Subnet $($Subnet) completed."
            $Script:LogString += Write-AuditLog -Message "DHCP Server: $($DHCPServer)"
            $Script:LogString += Write-AuditLog -Message "Gateway: $($internetadapter.IPv4DefaultGateway.nexthop)"
            $Script:LogString += Write-AuditLog -Message "##########################################"
            $Script:LogString += Write-AuditLog -Message "Starting with $(($NetworkAudit).count) output objects."
            # Filter devices that don't ping as no results will be found.
            $scan = Build-NetScanObject -NetScanObject $NetworkAudit -IncludeNoPing:$noping #-IncludeNoPing
            $Script:LogString += Write-AuditLog -Message "Created $(($scan).count) output objects for the following hosts:"
            $Script:LogString += Write-AuditLog -Message "$(($scan | Select-Object "IP/DNS")."IP/DNS" -join ", ")"
            # Normalize Subnet text for filename.
            $subnetText = $(($subnet.Replace("/", "_")))
            # Add the scan to the function output.
            $results = $scan
        } # End If $LocalSubnets
        elseif ($Computers) {
            $Subnet = $Computers
            if ($NoHops) {
                $IPRange = $Subnet
                $NonRoutedIPs, $FailedIps = Get-QuickPing -IPRange $IPRange -TTL 1
                if ($null -ne $NonRoutedIPs ) {
                    $Script:LogString += Write-AuditLog -Message "Local IPs object is populated."
                    $Script:LogString += Write-AuditLog -Message "Scan found $($NonRoutedIPs.count) IPs to scan."
                    if ($FailedIps -eq "NoIPs") {
                        $FailedIpsCount = 0
                    }
                    else {
                        $FailedIpsCount = $FailedIps.count
                    }
                    $Script:LogString += Write-AuditLog -Message "There were $FailedIpsCount IPs that failed to scan."
                    # Begin Region If $PSCmdlet.ShouldProcess
                    if ( $PSCmdlet.ShouldProcess( "NoHops", "Please confirm the following ips are ok to scan before proceeding:`n$($NonRoutedIPs -join ",")" ) ) {
                        $Script:LogString += Write-AuditLog -Message "Begin Invoke-PSnmap"
                        $scan = Invoke-PSnmap -ComputerName $NonRoutedIPs -Port $ports -ThrottleLimit $ThrottleLimit -Dns -NoSummary -AddService:$AddService
                    } # End Region If $PSCmdlet.ShouldProcess
                    $results = Build-NetScanObject -NetScanObject $scan -IncludeNoPing:$noping
                }
                else {
                    throw "No Hosts found to scan!"
                }
            }
            else {
                switch ($ScanOnPingFail) {
                    $true { $noping = $true }
                    Default { $noping = $false }
                }
                $Script:LogString += Write-AuditLog -Message "Begin Invoke-PSnmap"
                $scan = Invoke-PSnmap -ComputerName $Subnet -Port $ports -ThrottleLimit $ThrottleLimit -Dns -NoSummary -AddService:$AddService
                $results = Build-NetScanObject -NetScanObject $scan -IncludeNoPing:$noping
            }
        }
    }
    # Process Close
    end {
        if ($Report) {
            $csv = "C:\temp\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss')).$($env:USERDOMAIN)_HostScan_$subnetText.csv"
            $zip = $csv -replace ".csv", ".zip"
            $log = $csv -replace ".csv", ".AuditLog.csv"
            Build-ReportArchive -Export $results -csv $csv -zip $zip -log $log -AttachmentFolderPath "C:\temp" -ErrorVariable BuildErr
        }
        else {
            return $results
        }
    }# End Close
}
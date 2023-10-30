function Get-NetworkAudit {
<#
    .SYNOPSIS
    Discovers the local network and runs port scans on all hosts found for specific or default sets of ports, displaying MAC ID vendor info.
    .DESCRIPTION
    Scans the network for open ports specified by the user or default ports if no ports are specified. Creates reports if the report switch is active and adds MAC ID vendor info if found.

    NOTES:
    - This function requires the PSnmap module. If not found, it will be installed automatically.
    - The throttle limit determines the number of concurrent threads during scanning.
    - The scan rate is limited to 32 hosts per second to ensure network stability.
    - The total scan time and data transferred depend on the number of hosts.
    - The average network bandwidth is approximately 32 kilobits per second.
    .PARAMETER Ports
    Specifies the ports to scan. If not provided, the function uses default ports:
    "21", "22", "23", "25", "53", "67", "68", "80", "443",
    "88", "464", "123", "135", "137", "138", "139",
    "445", "389", "636", "514", "587", "1701",
    "3268", "3269", "3389", "5985", "5986"

    To specify ports, provide an integer or an array of integers. Example: "22", "80", "443"
    .PARAMETER Report
    Generates a report in the C:\temp folder if specified.
    .PARAMETER LocalSubnets
    Scans subnets connected to the local device. It will not scan outside of the hosting device's subnet.
    .PARAMETER NoHops
    Prevents scans across a gateway.
    .PARAMETER AddService
    Includes the service name associated with each port in the output.
    .PARAMETER Computers
    Scans a single host or an array of hosts using subnet ID in CIDR notation, IP address, NETBIOS name, or FQDN in double quotes.
    Example: "10.11.1.0/24", "10.11.2.0/24"
    .PARAMETER ThrottleLimit
    Specifies the number of concurrent threads. Default: 32.
    .PARAMETER ScanOnPingFail
    Scans a host even if ping fails.
    .EXAMPLE
    Get-NetworkAudit -Report
    Generates a report of the network audit results in the C:\temp folder.
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
        Write-AuditLog -Start
        # Begin Logging
        Write-AuditLog "Begin Log"
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
            Write-AuditLog "Beggining scan of subnet $($subnet) for the following ports:"
            Write-AuditLog "$(($ports | Out-String -Stream) -join ",")"
            # Begin Reigion Build NetworkAudit Object
            if ($NoHops) {
                $IPRange = $CalcSub.IPEnumerated
                # Use a foreach loop to test each IP address
                $NonRoutedIPs, $FailedIps = Get-QuickPing -IPRange $IPRange -TTL 1
                if ($null -ne $NonRoutedIPs) {
                    Write-AuditLog "Local IPs object is populated."
                    Write-AuditLog "Scan found $($NonRoutedIPs.count) IPs to scan."
                    Write-AuditLog "There were $($FailedIps.count) IPs that failed to scan."
                    if ( $PSCmdlet.ShouldProcess( "NoHops", "Please confirm the following ips are ok to scan before proceeding:`n$($NonRoutedIPs -join ",")" ) ) {
                        Write-AuditLog "Begin Invoke-PSnmap"
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
            Write-AuditLog "##########################################"
            Write-AuditLog "Network scan for Subnet $($Subnet) completed."
            Write-AuditLog "DHCP Server: $($DHCPServer)"
            Write-AuditLog "Gateway: $($internetadapter.IPv4DefaultGateway.nexthop)"
            Write-AuditLog "##########################################"
            Write-AuditLog "Starting with $(($NetworkAudit).count) output objects."
            # Filter devices that don't ping as no results will be found.
            $scan = Build-NetScanObject -NetScanObject $NetworkAudit -IncludeNoPing:$noping #-IncludeNoPing
            Write-AuditLog "Created $(($scan).count) output objects for the following hosts:"
            Write-AuditLog "$(($scan | Select-Object "IP/DNS")."IP/DNS" -join ", ")"
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
                    Write-AuditLog "Local IPs object is populated."
                    Write-AuditLog "Scan found $($NonRoutedIPs.count) IPs to scan."
                    if ($FailedIps -eq "NoIPs") {
                        $FailedIpsCount = 0
                    }
                    else {
                        $FailedIpsCount = $FailedIps.count
                    }
                    Write-AuditLog "There were $FailedIpsCount IPs that failed to scan."
                    # Begin Region If $PSCmdlet.ShouldProcess
                    if ( $PSCmdlet.ShouldProcess( "NoHops", "Please confirm the following ips are ok to scan before proceeding:`n$($NonRoutedIPs -join ",")" ) ) {
                        Write-AuditLog "Begin Invoke-PSnmap"
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
                Write-AuditLog "Begin Invoke-PSnmap"
                $scan = Invoke-PSnmap -ComputerName $Subnet -Port $ports -ThrottleLimit $ThrottleLimit -Dns -NoSummary -AddService:$AddService
                $results = Build-NetScanObject -NetScanObject $scan -IncludeNoPing:$noping
            }
        }
    }
    # Process Close
    end {
        if ($Report) {
            $csv = "C:\temp\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$((Get-CimInstance -ClassName Win32_ComputerSystem).Domain)_HostScan_$subnetText.csv"
            $zip = $csv -replace ".csv", ".zip"
            $log = $csv -replace ".csv", ".AuditLog.csv"
            Write-AuditLog -EndFunction
            Build-ReportArchive -Export $results -csv $csv -zip $zip -log $log -AttachmentFolderPath "C:\temp" -ErrorVariable BuildErr
        }
        else {
            return $results
        }
    }# End Close
}
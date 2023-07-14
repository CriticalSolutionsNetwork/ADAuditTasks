<#
.SYNOPSIS
    Builds a network scan object that includes information about each computer on the network.
.DESCRIPTION
    This function builds a network scan object that includes information about each computer
    on the network. The function takes a network scan object as input and returns a custom
    object with the following properties: ComputerName, IP/DNS, Ping, MacID, ManufacturerName,
    and PortsEnabled.
.PARAMETER NetScanObject
    The network scan object to use as input. The object should have the following properties:
    ComputerName, IP/DNS, and Ping.
.PARAMETER IncludeNoPing
    A switch parameter that specifies whether to include computers that did not respond to
    ping in the output.
.OUTPUTS
    System.Collections.Generic.List[System.Management.Automation.PSCustomObject]
    A list of custom objects that contain information about each computer on the network.
.EXAMPLE
    $NetScanObject = @(
        @{
            ComputerName = "computer1"
            "IP/DNS"     = "192.168.1.1"
            Ping         = $true
        },
        @{
            ComputerName = "computer2"
            "IP/DNS"     = "192.168.1.2"
            Ping         = $false
        }
    )
    $scan = Build-NetScanObject -NetScanObject $NetScanObject
    $scan
.NOTES
    Author: DrIOSx
#>
function Build-NetScanObject {
    param(
        $NetScanObject,
        [switch]$IncludeNoPing
    )
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    $ouiobject = Build-MacIdOUIList
    Write-AuditLog "Begin NetScan object creation."
    switch ($IncludeNoPing) {
        $true {
            $scan = $NetSCanObject
        }
        Default {
            $scan = $NetSCanObject | Where-Object { $_.Ping -eq $true }
        }
    }
    $Export = @()
    foreach ($Item in $scan) {
        $portsenabled = ($item.PSObject.Properties | Where-Object { $_.Value -eq $true -and $_.name -ne "Ping" }).Name -join " | "
        $portsenabled = $portsenabled.Replace("Port ", "")
        $SaveErrorPref = $Script:ErrorActionPreference
        $Script:ErrorActionPreference = 'SilentlyContinue'
        $macid = ((arp -a "$($item.ComputerName)" | Select-String '([0-9a-f]{2}-){5}[0-9a-f]{2}').Matches.Value).Replace("-", ":")
        $macpop = $macid.replace(":", "")
        $macsubstr = $macpop.Substring(0, 6)
        $org = ($ouiobject | Where-Object { $_.assignment -eq $macsubstr })."Organization Name"
        $Script:ErrorActionPreference = $SaveErrorPref
        if ($org) {
            [string]$ManufacturerName = $org
        }
        else {
            [string]$ManufacturerName = "NotFound"
        }
        $hash = [ordered]@{
            ComputerName     = $Item.ComputerName
            "IP/DNS"         = $Item."IP/DNS"
            Ping             = $Item.Ping
            MacID            = $macid
            ManufacturerName = $ManufacturerName
            PortsEnabled     = $portsenabled
        } # End Ordered Hash table
        New-Object -TypeName PSCustomObject -Property $hash -OutVariable PSObject | Out-Null
        $Export += $PSObject
    } # End foreach scan
    if ($Export) {
        Write-AuditLog "NetScan object created!"
        Write-AuditLog -EndFunction
        return $Export
    }
    else {
        throw "The ExportObject was Blank"
    }
}
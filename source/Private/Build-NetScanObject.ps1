function Build-NetScanObject {
    param(
        $NetScanObject,
        [switch]$IncludeNoPing
    )
    $ouiobject = Build-MacIdOUIList
    $Script:LogString += Write-AuditLog -Message "Begin NetScan object creation."
    switch ($IncludeNoPing) {
        $true {
            $scan = $NetworkAudit
        }
        Default {
            $scan = $NetworkAudit | Where-Object { $_.Ping -eq $true }
        }
    }
    $Export = @()
    foreach ($Item in $scan) {
        $portsenabled = ($item.PSObject.Properties | Where-Object { $_.Value -eq $true -and $_.name -ne "Ping" }).Name -join " | "
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
        $Script:LogString += Write-AuditLog -Message "NetScan object created!"
        return $Export
    }
    else {
        throw "The ExportObject was Blank"
    }
}###
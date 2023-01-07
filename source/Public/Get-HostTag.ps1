function Get-HostTag {
    <#
    .SYNOPSIS
        Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.
    .DESCRIPTION
        A longer description of the function, its purpose, common use cases, etc.
    .EXAMPLE
        Get-HostTag -PhysicalOrVirtual Physical -Prefix "CSN" -SystemOS 'Windows Server' -DeviceFunction 'Application Server' -HostCount 5
            CSN-PWSVAPP001
            CSN-PWSVAPP002
            CSN-PWSVAPP003
            CSN-PWSVAPP004
            CSN-PWSVAPP005
        This creates the name of the host under 15 characters and numbers them. Prefix can be 2-3 characters.
    .PARAMETER PhysicalOrVirtual
        Tab through selections to add 'P' or 'V' for physical or virtual to host tag.
    .PARAMETER Prefix
        Enter the 2-3 letter prefix. Good for prefixing company initials, locations, or other.
    .PARAMETER SystemOS
        Use tab to cycle through the following options:
            "Cisco ASA", "Android", "Apple IOS",
            "Dell Storage Center", "MACOSX",
            "Dell Power Edge", "Embedded", "Embedded Firmware",
            "Cisco IOS", "Linux", "Qualys", "Citrix ADC (Netscaler)",
            "Windows Thin Client", "VMWare",
            "Nutanix", "TrueNas", "FreeNas",
            "ProxMox", "Windows Workstation", "Windows Server",
            "Windows Server Core", "Generic OS", "Generic HyperVisor"
    .PARAMETER DeviceFunction
        Use tab to cycle through the following options:
            "Application Server", "Backup Server", "Directory Server",
            "Email Server", "Firewall", "FTP Server",
            "Hypervisor", "File Server", "NAS File Server",
            "Power Distribution Unit", "Redundant Power Supply", "SAN Appliance",
            "SQL Server", "Uninteruptable Power Supply", "Web Server",
            "Management", "Blade Enclosure", "Blade Enclosure Switch",
            "SAN specific switch", "General server/Network switch", "Generic Function Device"
    .PARAMETER HostCount
        Enter a number from 1 to 999 for how many hostnames you'd like to create.
    #>
    [OutputType([string[]])]
    [CmdletBinding()]
    param (
        [Parameter(
            MandaTory = $true,
            Position = 0,
            HelpMessage = 'Enter 2 character site code or prefix for your devices',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet("Physical", "Virtual")]
        [string]$PhysicalOrVirtual,
        [Parameter(
            MandaTory = $true,
            Position = 1,
            HelpMessage = 'Enter 2 to 3 character site code or prefix for your devices',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateLength(2, 3)]
        [string]$Prefix,
        [Parameter(
            MandaTory = $true,
            Position = 2,
            HelpMessage = 'Tab complete to pick from a list of System OSs',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet(
            "Cisco ASA", "Android", "Apple IOS",
            "Dell Storage Center", "MACOSX",
            "Dell Power Edge", "Embedded", "Embedded Firmware",
            "Cisco IOS", "Linux", "Qualys", "Citrix ADC (Netscaler)",
            "Windows Thin Client", "VMWare",
            "Nutanix", "TrueNas", "FreeNas",
            "ProxMox", "Windows Workstation", "Windows Server",
            "Windows Server Core", "Generic OS", "Generic HyperVisor"
        )]
        [string]$SystemOS,
        [Parameter(
            MandaTory = $true,
            Position = 3,
            HelpMessage = 'Tab complete to pick from a list of Device Functions',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet(
            "Application Server", "Backup Server", "Directory Server",
            "Email Server", "Firewall", "FTP Server",
            "Hypervisor", "File Server", "NAS File Server",
            "Power Distribution Unit", "Redundant Power Supply", "SAN Appliance",
            "SQL Server", "Uninteruptable Power Supply", "Web Server",
            "Management", "Blade Enclosure", "Blade Enclosure Switch",
            "SAN specific switch", "General server/Network switch", "Generic Function Device"
        )]
        [string]$DeviceFunction,
        [Parameter(
            Position = 4,
            HelpMessage = 'Enter the number of host names you want to create between 1 and 254',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateRange(1, 999)]
        [int]$HostCount = 1
    )
    begin {
        switch ($DeviceFunction) {
            "Application Server" { $DFunction = "APP" }
            "Backup Server" { $DFunction = "BAK" }
            "Directory Server" { $DFunction = "DIR" }
            "Email Server" { $DFunction = "EML" }
            "Firewall" { $DFunction = "FRW" }
            "FTP Server" { $DFunction = "FTP" }
            "Hypervisor" { $DFunction = "HYP" }
            "File Server" { $DFunction = "FIL" }
            "NAS File Server" { $DFunction = "NAS" }
            "Power Distribution Unit" { $DFunction = "PDU" }
            "Redundant Power Supply" { $DFunction = "RPS" }
            "SAN Appliance" { $DFunction = "SAN" }
            "SQL Server" { $DFunction = "SQL" }
            "Uninteruptable Power Supply" { $DFunction = "UPS" }
            "Web Server" { $DFunction = "WEB" }
            "Management" { $DFunction = "MGT" }
            "Blade Enclosure" { $DFunction = "BLDENC" }
            "Blade Enclosure Switch" { $DFunction = "SW-BLD" }
            "SAN specific Switch" { $DFunction = "SW-SAN" }
            "General Server/Network Switch" { $DFunction = "SW-SVR" }
            Default { $DFunction = "XDV" }
        }
        switch ($SystemOS) {
            "Cisco ASA" { $OSTxt = "ASA" }
            "Android" { $OSTxt = "DRD" }
            "Apple IOS" { $OSTxt = "IOS" }
            "Dell Storage Center" { $OSTxt = "DLS" }
            "MACOSX" { $OSTxt = "MAC" }
            "Dell Power Edge" { $OSTxt = "DPE" }
            "Embedded" { $OSTxt = "EMD" }
            "Embedded Firmware" { $OSTxt = "EFW" }
            "Cisco IOS" { $OSTxt = "COS" }
            "Linux" { $OSTxt = "NIX" }
            "Qualys" { $OSTxt = "QLS" }
            "Citrix ADC (Netscaler)" { $OSTxt = "ADC" }
            "Windows Thin Client" { $OSTxt = "WTC" }
            "VMWare" { $OSTxt = "VMW" }
            "Nutanix" { $OSTxt = "NTX" }
            "TrueNas" { $OSTxt = "FNS" }
            "FreeNas" { $OSTxt = "XDV" }
            "ProxMox" { $OSTxt = "PMX" }
            "Windows Workstation" { $OSTxt = "WWS" }
            "Windows Server" { $OSTxt = "WSV" }
            "Windows Server Core" { $OSTxt = "WSC" }
            "Generic OS" { $OSTxt = "GOS" }
            Default { $DFunction = "GHV" }
        }
        switch ($PhysicalOrVirtual) {
            "Physical" { $DevType = "P" }
            Default { $DevType = "V" }
        }
    }
    process {
        $OutPut = @()
        1..$HostCount | ForEach-Object {
            $CustomName = $Prefix + "-" + $DevType + $OSTxt + $DFunction + $('{0:d3}' -f [int]$_)
            $Output += $CustomName
        }
        # Create Device Name
    }
    end {
        return $Output
    }
}
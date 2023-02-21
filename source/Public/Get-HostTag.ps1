function Get-HostTag {
    <#
    .SYNOPSIS
        Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.
    .DESCRIPTION
        This function generates custom host names based on predetermined criteria. The criteria includes physical/virtual nature of the host, a 2-3 letter prefix, system OS, and device function. The name is composed of the prefix, a code for physical/virtual nature of the host, a code for the system OS, a code for device function, and a three-digit number. The name is no longer than 15 characters. The function can generate up to 999 names at a time.
    .EXAMPLE
        PS C:\> Get-HostTag -PhysicalOrVirtual Physical -Prefix "CSN" -SystemOS 'Windows Server' -DeviceFunction 'Application Server' -HostCount 5
        Returns:
            CSN-PWSVAPP001
            CSN-PWSVAPP002
            CSN-PWSVAPP003
            CSN-PWSVAPP004
            CSN-PWSVAPP005
    .PARAMETER PhysicalOrVirtual
        The physical or virtual nature of the host. Enter "P" for physical and "V" for virtual.
    .PARAMETER Prefix
        The 2-3 letter prefix used in the host name.
    .PARAMETER SystemOS
        The operating system of the host. Use tab to cycle through the following options:
            "Cisco ASA", "Android", "Apple IOS",
            "Dell Storage Center", "MACOSX",
            "Dell Power Edge", "Embedded", "Embedded Firmware",
            "Cisco IOS", "Linux", "Qualys", "Citrix ADC (Netscaler)",
            "Windows Thin Client", "VMWare",
            "Nutanix", "TrueNas", "FreeNas",
            "ProxMox", "Windows Workstation", "Windows Server",
            "Windows Server Core", "Generic OS", "Generic HyperVisor"
    .PARAMETER DeviceFunction
        The function of the device. Use tab to cycle through the following options:
            "Application Server", "Backup Server", "Directory Server",
            "Email Server", "Firewall", "FTP Server",
            "Hypervisor", "File Server", "NAS File Server",
            "Power Distribution Unit", "Redundant Power Supply", "SAN Appliance",
            "SQL Server", "Uninteruptable Power Supply", "Web Server",
            "Management", "Blade Enclosure", "Blade Enclosure Switch",
            "SAN specific switch", "General server/Network switch", "Generic Function Device"
    .PARAMETER HostCount
        The number of host names to generate. Must be between 1 and 999.
    #>
    # Define the output type of the function
    [OutputType([string[]])]
    # Define the binding for the cmdlet
    [CmdletBinding()]
    # Define the parameters for the function
    param (
        # Define the first parameter, which is mandatory
        [Parameter(
            MandaTory = $true,   # This parameter is mandatory
            Position = 0,       # This parameter should be the first one in the list
            HelpMessage = 'Enter 2 character site code or prefix for your devices',  # Help message for the parameter
            ValueFromPipelineByPropertyName = $true  # This parameter can be piped to
        )]
        [ValidateSet("Physical", "Virtual")]  # This parameter can only have these values
        [string]$PhysicalOrVirtual,          # The variable that will hold the value of this parameter

        # Define the second parameter, which is mandatory
        [Parameter(
            MandaTory = $true,   # This parameter is mandatory
            Position = 1,       # This parameter should be the second one in the list
            HelpMessage = 'Enter 2 to 3 character site code or prefix for your devices',  # Help message for the parameter
            ValueFromPipelineByPropertyName = $true  # This parameter can be piped to
        )]
        [ValidateLength(2, 3)]  # This parameter can only have a value of length 2 or 3
        [string]$Prefix,        # The variable that will hold the value of this parameter

        # Define the third parameter, which is mandatory
        [Parameter(
            MandaTory = $true,   # This parameter is mandatory
            Position = 2,       # This parameter should be the third one in the list
            HelpMessage = 'Tab complete to pick from a list of System OSs',  # Help message for the parameter
            ValueFromPipelineByPropertyName = $true  # This parameter can be piped to
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
        )]  # This parameter can only have values from this list
        [string]$SystemOS,     # The variable that will hold the value of this parameter

        # Define the fourth parameter, which is mandatory
        [Parameter(
            Position = 3,       # This parameter should be the fourth one in the list
            HelpMessage = 'Enter the number of host names you want to create between 1 and 254',  # Help message for the parameter
            ValueFromPipelineByPropertyName = $true  # This parameter can be piped to
        )]
        [ValidateRange(1, 999)]  # This parameter can only have a value between 1 and 999
        [int]$HostCount = 1     # The variable that will hold the value of this parameter
    )
    # Define the begin block
    begin {
        # The DeviceFunction parameter
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
        # Set a value based on the value of the SystemOS parameter
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
        # Set a value based on the value of the PhysicalOrVirtual parameter
        switch ($PhysicalOrVirtual) {
            "Physical" { $DevType = "P" }
            Default { $DevType = "V" }
        }
    }
    # Define the process block
    process {
        $OutPut = @()
        1..$HostCount | ForEach-Object {
            # Create the custom name using the values of the other parameters
            $CustomName = $Prefix + "-" + $DevType + $OSTxt + $DFunction + $('{0:d3}' -f [int]$_)
            # Add the custom name to the output array
            $Output += $CustomName
        }
        # Create Device Name
    }
    end {
        # Return the output array
        return $Output
    }
}
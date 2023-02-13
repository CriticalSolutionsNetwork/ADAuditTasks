function Get-ADHostAudit {
    <#
    .SYNOPSIS
        Active Directory Server and Workstation Audit with Report export option (Can also be piped to CSV if Report isn't specified).
    .DESCRIPTION
        Audit's Active Directory taking "days" as the input for how far back to check for a device's last sign in.
        Output can be piped to a csv manually, or automatically to C:\temp\ADHostAudit or a specified path in
        "AttachmentFolderPath" using the -Report Switch.

            Use the Tab key to cycle through the -HostType Parameter.
    .EXAMPLE
        PS C:\> Get-ADHostAudit -HostType WindowsServers -Report -Verbose
    .EXAMPLE
        PS C:\> Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
    .EXAMPLE
        PS C:\> Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
    .EXAMPLE
        PS C:\> Get-ADHostAudit -OSType "2008" -DirPath "C:\Temp\" -Report -Verbose
    .PARAMETER HostType
        Select from WindowsServers, WindowsWorkstations or Non-Windows.
    .PARAMETER OSType
        Search an OS String. There is no need to add wildcards.
    .PARAMETER DaystoConsiderAHostInactive
        How far back in days to look for sign ins. Outside of this window, hosts are considered "Inactive"
    .PARAMETER Report
        Add report output as csv to DirPath directory.
    .PARAMETER AttachmentFolderPath
        Default path is C:\temp\ADHostAudit.
        This is the folder where attachments are going to be saved.
    .PARAMETER Enabled
        If "$false", will also search disabled computers.
    .NOTES
        Outputs to C:\temp\ADHostAudit by default.
        For help type: help Get-ADHostAudit -ShowWindow
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding(DefaultParameterSetName = 'HostType')]
    param (
        [ValidateSet("WindowsServers", "WindowsWorkstations", "Non-Windows")]
        [Parameter(
            ParameterSetName = 'HostType',
            Mandatory = $true,
            Position = 0,
            HelpMessage = 'Name filter attached to users.',
            ValueFromPipeline = $true
        )]
        [string]$HostType,
        [Parameter(
            Mandatory = $true,
            ParameterSetName = 'OSType',
            Position = 0,
            HelpMessage = 'Enter a Specific OS Name or first few letters of the OS to Search for in ActiveDirectory',
            ValueFromPipeline = $true
        )]
        [string]$OSType,
        [Parameter(
            Position = 1,
            HelpMessage = 'How many days back to consider an AD Computer last sign in as active',
            ValueFromPipelineByPropertyName = $true
        )]
        [int]$DaystoConsiderAHostInactive = 90,
        [Parameter(
            Position = 2,
            HelpMessage = 'Switch to output to directory specified in DirPath parameter',
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report,
        [Parameter(
            Position = 3,
            HelpMessage = 'Enter the working directory you wish the report to save to. Default creates C:\temp'
        )]
        [string]$AttachmentFolderPath = 'C:\temp\ADHostAudit',
        [Parameter(
            HelpMessage = 'Search for Enabled or Disabled hosts',
            ValueFromPipelineByPropertyName = $true
        )]
        [bool]$Enabled = $true
    )
    begin {
        # Create logging object
        $Script:ADLogString = @()
        # Begin Logging
        $Script:ADLogString += Write-AuditLog -Message "Begin Log"
        # Get the name of the script function
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        # Check if the Active Directory module is installed and install it if necessary
        $module = Get-Module -Name ActiveDirectory -ListAvailable -InformationAction SilentlyContinue
        if (-not $module) {
            $Script:ADLogString += Write-AuditLog -Message "Install Active Directory Module?" -Severity Warning
            try {
                Import-Module ServerManager -ErrorAction Stop -ErrorVariable InstallADModuleErr
                Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop -ErrorVariable InstallADModuleErr
            }
            catch {
                $Script:ADLogString += Write-AuditLog -Message "You must install the Active Directory module to continue" -Severity Error
                throw $InstallADModuleError
            }
        }
        try {
            Import-Module "ActiveDirectory" -Global -ErrorAction Stop -InformationAction SilentlyContinue -ErrorVariable ImportADModuleErr
        }
        catch {
            $Script:ADLogString += Write-AuditLog -Message "You must import the Active Directory module to continue" -Severity Error
            throw ImportADModuleErr
        }
        # Calculate the time that is considered a host inactive
        $time = (Get-Date).Adddays( - ($DaystoConsiderAHostInactive))
        # Check if the attachment folder exists and create it if it does not
        $AttachmentFolderPathCheck = Test-Path -Path $AttachmentFolderPath
        If (!($AttachmentFolderPathCheck)) {
            $Script:ADLogString += Write-AuditLog -Message "Would you like to create the directory $($AttachmentFolderPath)?" -Severity Warning
            Try {
                # If not present then create the dir
                New-Item -ItemType Directory $AttachmentFolderPath -Force -ErrorAction Stop -ErrorVariable CreateDirErr | Out-Null
            }
            Catch {
                $Script:ADLogString += Write-AuditLog -Message "Unable to create output directory $($AttachmentFolderPath)" -Severity Error
                throw $CreateDirErr
            }
        }
        # Determine the host type and set the appropriate search criteria
        switch ($PsCmdlet.ParameterSetName) {
            'HostType' {
                if ($HostType -eq "WindowsWorkstations") {
                    $FileSuffix = "Workstations"
                    $Script:ADLogString += Write-AuditLog -Message "###############################################"
                    $Script:ADLogString += Write-AuditLog -Message "Searching Windows Workstations......"
                    Start-Sleep 2
                }
                elseif ($HostType -eq "Non-Windows") {
                    $POSIX = $true
                    $FileSuffix = "Non-Windows"
                    $Script:ADLogString += Write-AuditLog -Message "###############################################"
                    $Script:ADLogString += Write-AuditLog -Message "Searching Non-Windows Computer Objects......"
                    Start-Sleep 2
                }
                elseif ($HostType -eq "WindowsServers") {
                    $OSPicked = "*Server*"
                    $FileSuffix = "Servers"
                    $Script:ADLogString += Write-AuditLog -Message "###############################################"
                    $Script:ADLogString += Write-AuditLog -Message "Searching Windows Servers......"
                    Start-Sleep 2
                }
            }
            'OSType' {
                $OSPicked = '*' + $OSType + '*'
                $FileSuffix = $OSType
                $Script:ADLogString += Write-AuditLog -Message "###############################################"
                $Script:ADLogString += Write-AuditLog -Message "Searching OSType $OsType......"
                Start-Sleep 2
            }
        }
        # Set the properties to retrieve for the host objects
        $propsArray = `
            "Created", `
            "Description", `
            "DNSHostName", `
            "Enabled", `
            "IPv4Address", `
            "IPv6Address", `
            "KerberosEncryptionType", `
            "lastLogonTimestamp", `
            "Name", `
            "OperatingSystem", `
            "DistinguishedName", `
            "servicePrincipalName", `
            "whenChanged"
    } # End Begin
    process {
        # Log the search criteria
        $Script:ADLogString += Write-AuditLog -Message "Searching computers that have logged in within the last $DaystoConsiderAHostInactive days."
        $Script:ADLogString += Write-AuditLog -Message "Where property Enabled = $Enabled"
        Start-Sleep 2
        # Determine the Active Directory computers to include in the report
        if ($OSPicked) {
            $Script:ADLogString += Write-AuditLog -Message "And Operating System is like: $OSPicked."
            $ActiveComputers = (Get-ADComputer -Filter { (LastLogonTimeStamp -gt $time) -and (Enabled -eq $Enabled) -and (OperatingSystem -like $OSPicked) }).Name
        }
        elseif ($POSIX) {
            $Script:ADLogString += Write-AuditLog -Message "And Operating System is: Non-Windows(POSIX)."
            $ActiveComputers = (Get-ADComputer -Filter { OperatingSystem -notlike "*windows*" -and OperatingSystem -notlike "*server*" -and Enabled -eq $Enabled -and lastlogontimestamp -gt $time } ).Name
        }
        else {
            $Script:ADLogString += Write-AuditLog -Message "And Operating System is -like `"*windows*`" -and Operating System -notlike `"*server*`" (Workstations)."
            $ActiveComputers = (Get-ADComputer -Filter { OperatingSystem -like "*windows*" -and OperatingSystem -notlike "*server*" -and Enabled -eq $Enabled -and lastlogontimestamp -gt $time } ).Name
        }
        # Retrieve the selected properties for each Active Directory computer and store the results in an array
        $ADComps = @()
        foreach ($comp in $ActiveComputers) {
            Get-ADComputer -Identity $comp -Properties $propsArray | Select-Object $propsArray -OutVariable ADComp | Out-Null
            $ADComps += $ADComp
        } # End Foreach
        # Create a new object for each Active Directory computer with the selected properties and store the results in an array
        $ADCompExport = @()
        foreach ($item in $ADComps) {
            $ADCompExport += [ADAuditTasksComputer]::new(
                $item.Name,
                $item.DNSHostName,
                $item.Enabled,
                $item.IPv4Address,
                $item.IPv6Address,
                $item.OperatingSystem,
                $item.lastLogonTimestamp,
                $item.Created,
                $item.whenChanged,
                $item.Description,
                $item.DistinguishedName,
                $(($item.KerberosEncryptionType).Value.tostring()),
                ($item.servicePrincipalName -join " | "),
                $item.Name,
                $item.lastLogonTimestamp
            ) # End New [ADComputerAccount] object
        }# End foreach Item in ADComps
        # Convert the objects to PSCustomObjects and store the results in an array
        $Export = @()
        foreach ($Comp in $ADCompExport) {
            $hash = [ordered]@{
                DNSHostName            = $Comp.DNSHostName
                ComputerName           = $Comp.ComputerName
                Enabled                = $Comp.Enabled
                IPv4Address            = $Comp.IPv4Address
                IPv6Address            = $Comp.IPv6Address
                OperatingSystem        = $Comp.OperatingSystem
                LastLogon              = $Comp.LastLogon
                LastSeen               = $Comp.LastSeen
                Created                = $Comp.Created
                Modified               = $Comp.Modified
                Description            = $Comp.Description
                GroupMemberships       = $Comp.GroupMemberships
                OrgUnit                = $Comp.OrgUnit
                KerberosEncryptionType = $Comp.KerberosEncryptionType
                SPNs                   = $Comp.SPNs
            } # End Ordered Hash table
            New-Object -TypeName PSCustomObject -Property $hash -OutVariable PSObject | Out-Null
            $Export += $PSObject
        } # End foreach Comp in ADCompExport
    } # End Process
    end {
        # If there the export is not empty
        if ($Export) {
            # Create a message that lists the properties that were exported
            $ExportMembers = "Export: $(($Export | Get-Member -MemberType noteproperty ).Name -join " | ")"
            # Log a successful export message and list the exported properties and the number of objects exported
            $Script:ADLogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
            $Script:ADLogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
            $Script:ADLogString += Write-AuditLog -Message "$ExportMembers"
            # If the -Report switch is used, create a report archive and log the output
            if ($Report) {
                # Add Datetime to filename
                $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
                # Create FileNames
                $csv = "$ExportFileName.$FileSuffix.csv"
                $zip = "$ExportFileName.$FileSuffix.zip"
                $log = "$ExportFileName.$FileSuffix.AuditLog.csv"
                Build-ReportArchive -Export $Export -csv $csv -zip $zip -log $log -ErrorVariable BuildErr
            }
            # If the -Report switch is not used, return the output object
            else {
                $Script:ADLogString += Write-AuditLog -Message "Returning output object."
                Start-Sleep 2
                return $Export
            }
        }
        else {
            # If there is no output, log message and create an audit log file
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
            $log = "$ExportFileName.$FileSuffix.AuditLog.csv"
            $Script:ADLogString += "There is no output for the specified host type $FileSuffix"
            $Script:ADLogString | Export-Csv $log -NoTypeInformation -Encoding utf8
        }
    } # End End
}
function Get-ADHostAudit {
<#
.SYNOPSIS
    Active Directory Server and Workstation Audit with Report export option (Can also be piped to CSV if Report isn't specified).
.DESCRIPTION
    Audits Active Directory for hosts that haven't signed in for a specified number of days. Output can be piped to a CSV manually, or automatically saved to C:\temp\ADHostAudit or a specified directory using the -Report switch.

    Use the Tab key to cycle through the -HostType parameter.
.EXAMPLE
    PS C:\> Get-ADHostAudit -HostType WindowsServers -Report -Verbose
.EXAMPLE
    PS C:\> Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
.EXAMPLE
    PS C:\> Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
.EXAMPLE
    PS C:\> Get-ADHostAudit -OSType "2008" -DirPath "C:\Temp\" -Report -Verbose
.PARAMETER HostType
    Specifies the type of hosts to search for. Valid values are WindowsServers, WindowsWorkstations, and Non-Windows.
.PARAMETER OSType
    Specifies the operating system to search for. There is no need to add wildcards.
.PARAMETER DaystoConsiderAHostInactive
    Specifies the number of days to consider a host as inactive.
.PARAMETER Report
    Saves a CSV report to the specified directory.
.PARAMETER AttachmentFolderPath
    Specifies the directory where attachments will be saved.
.PARAMETER Enabled
    If set to $false, the function will also search for disabled computers.
.NOTES
    By default, output is saved to C:\temp\ADHostAudit.
    For more information, type: Get-Help Get-ADHostAudit -ShowWindow
.LINK
https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADHostAudit
.LINK
https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADHostAudit
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
        $Script:LogString = @()
        # Begin Logging
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        $Script:LogString += Write-AuditLog -Message "###############################################"
        # Get the name of the script function
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        # Check if the Active Directory module is installed and install it if necessary
        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        # Calculate the time that is considered a host inactive
        $time = (Get-Date).Adddays( - ($DaystoConsiderAHostInactive))
        # Check if the attachment folder exists and create it if it does not
        Build-DirectoryPath -DirectoryPath $AttachmentFolderPath
        # Determine the host type and set the appropriate search criteria
        switch ($PsCmdlet.ParameterSetName) {
            'HostType' {
                if ($HostType -eq "WindowsWorkstations") {
                    $FileSuffix = "Workstations"
                    $Script:LogString += Write-AuditLog -Message "###############################################"
                    $Script:LogString += Write-AuditLog -Message "Searching Windows Workstations......"
                    Start-Sleep 2
                }
                elseif ($HostType -eq "Non-Windows") {
                    $POSIX = $true
                    $FileSuffix = "Non-Windows"
                    $Script:LogString += Write-AuditLog -Message "###############################################"
                    $Script:LogString += Write-AuditLog -Message "Searching Non-Windows Computer Objects......"
                    Start-Sleep 2
                }
                elseif ($HostType -eq "WindowsServers") {
                    $OSPicked = "*Server*"
                    $FileSuffix = "Servers"
                    $Script:LogString += Write-AuditLog -Message "###############################################"
                    $Script:LogString += Write-AuditLog -Message "Searching Windows Servers......"
                    Start-Sleep 2
                }
            }
            'OSType' {
                $OSPicked = '*' + $OSType + '*'
                $FileSuffix = $OSType
                $Script:LogString += Write-AuditLog -Message "###############################################"
                $Script:LogString += Write-AuditLog -Message "Searching OSType $OsType......"
                Start-Sleep 2
            }
        }
        # Set the properties to retrieve for the host objects
        $propsArray =
        "Created",
        "Description",
        "DNSHostName",
        "Enabled",
        "IPv4Address",
        "IPv6Address",
        "KerberosEncryptionType",
        "lastLogonTimestamp",
        "Name",
        "OperatingSystem",
        "DistinguishedName",
        "servicePrincipalName",
        "whenChanged"

    } # End Begin
    process {
        # Log the search criteria
        $Script:LogString += Write-AuditLog -Message "Searching computers that have logged in within the last $DaystoConsiderAHostInactive days."
        $Script:LogString += Write-AuditLog -Message "Where property Enabled = $Enabled"
        Start-Sleep 2
        # Determine the Active Directory computers to include in the report
        if ($OSPicked) {
            $Script:LogString += Write-AuditLog -Message "And Operating System is like: $OSPicked."
            Get-ADComputer -Filter { (LastLogonTimeStamp -gt $time) -and (Enabled -eq $Enabled) -and (OperatingSystem -like $OSPicked) }`
                -Properties $propsArray | Select-Object $propsArray -OutVariable ADComps | Out-Null
        }
        elseif ($POSIX) {
            $Script:LogString += Write-AuditLog -Message "And Operating System is: Non-Windows(POSIX)."
            Get-ADComputer -Filter { OperatingSystem -notlike "*windows*" -and OperatingSystem -notlike "*server*" -and Enabled -eq $Enabled -and lastlogontimestamp -gt $time }`
                -Properties $propsArray | Select-Object $propsArray -OutVariable ADComps | Out-Null
        }
        else {
            $Script:LogString += Write-AuditLog -Message "And Operating System is -like `"*windows*`" -and Operating System -notlike `"*server*`" (Workstations)."
            Get-ADComputer -Filter { OperatingSystem -like "*windows*" -and OperatingSystem -notlike "*server*" -and Enabled -eq $Enabled -and lastlogontimestamp -gt $time } `
                -Properties $propsArray | Select-Object $propsArray -OutVariable ADComps | Out-Null
        }
        # Create a new object for each Active Directory computer with the selected properties and store the results in an array
        $ADCompExport = foreach ($item in $ADComps) {
            Build-ADAuditTasksComputer -ADComputer $item
        } # End foreach Item in ADComps
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
            $Script:LogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
            $Script:LogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
            $Script:LogString += Write-AuditLog -Message "$ExportMembers"
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
                $Script:LogString += Write-AuditLog -Message "Returning output object."
                Start-Sleep 2
                return $Export
            }
        }
        else {
            # If there is no output, log message and create an audit log file
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
            $log = "$ExportFileName.$FileSuffix.AuditLog.csv"
            $Script:LogString += Write-AuditLog "There is no output for the specified host type $FileSuffix"
            $Script:LogString | Export-Csv $log -NoTypeInformation -Encoding utf8
            # If the -Report switch is not used, return null
            if (-not $Report) {
                return $null
            }
            else {
                return $log
            }
        }
    } # End End
}
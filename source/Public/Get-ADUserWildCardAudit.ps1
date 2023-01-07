function Get-ADUserWildCardAudit {
    <#
    .SYNOPSIS
        Takes a search string to find commonly named accounts.
    .DESCRIPTION
        Takes a search string to find commonly named accounts.
        For example:
            If you commonly name service accounts with the prefix "svc",
            Use "svc" for the WildCardIdentifier to search for names that contain "svc"
    .EXAMPLE
        Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
        Searches for all user accounts that are named like the search string "svc".
    .PARAMETER Report
        Add report output as csv to AttachmentFolderPath directory.
    .PARAMETER AttachmentFolderPath
        Default path is C:\temp\ADUserWildCardAudit.
        This is the folder where attachments are going to be saved.
    .PARAMETER Enabled
        If "$false", will also search disabled users.
    .PARAMETER DaysInactive
        How far back in days to look for sign ins. Outside of this window, users are considered "Inactive"
    .PARAMETER WildCardIdentifier
        The search string to look for in the name of the account. Case does not matter.
        Do not add a wildcard (*) as it will do this automatically.
    #>
    [OutputType([ADAuditTasksUser])]
    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Active Directory User Enabled or not. Default $true',
            Position = 0,
            ValueFromPipelineByPropertyName = $true
        )]
        [bool]$Enabled = $true,
        [Parameter(
            HelpMessage = 'Days back to check for recent sign in. Default: 90 days',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [int]$DaysInactive = 90,
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name filter attached to users.',
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$WildCardIdentifier,
        [Parameter(
            HelpMessage = 'Enter output folder path. Default: C:\temp\ADUserWildCardAudit',
            Position = 3,
            ValueFromPipeline = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\ADUserWildCardAudit",
        [Parameter(
            HelpMessage = 'Switch to export output to a csv and zipped to Directory C:\temp. Default: $false',
            Position = 4,
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report
    )
    begin {
        #Create logging object
        $Script:ADLogString = @()
        #Begin Logging
        $Script:ADLogString += Write-AuditLog -Message "Begin Log"
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
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
        } # End If not Module
        try {
            Import-Module "ActiveDirectory" -Global -ErrorAction Stop -InformationAction SilentlyContinue -ErrorVariable ImportADModuleErr
        }
        catch {
            $Script:ADLogString += Write-AuditLog -Message "You must import the Active Directory module to continue" -Severity Error
            throw $ImportADModuleErr
        } # End Try Catch
        # Create Directory Path
        $AttachmentFolderPathCheck = Test-Path -Path $AttachmentFolderPath
        If (!($AttachmentFolderPathCheck)) {
            Try {
                # If not present then create the dir
                New-Item -ItemType Directory $AttachmentFolderPath -Force -ErrorAction Stop
            }
            Catch {
                $Script:ADLogString += Write-AuditLog -Message $("Directory: " + $AttachmentFolderPath + "was not created.") -Severity Error
                $Script:ADLogString += Write-AuditLog -Message "End Log"
                throw $Script:ADLogString
            }
            $Script:ADLogString += Write-AuditLog -Message "$("Output Folder created at: `n" + $AttachmentFolderPath)"
            Start-Sleep 2
        }
        # ADUser Properties to search for.
        $propsArray =
        "SamAccountName",
        "GivenName",
        "Surname",
        "Name",
        "UserPrincipalName",
        "LastLogonTimeStamp",
        "Enabled",
        "LastLogonTimeStamp",
        "DistinguishedName",
        "Title",
        "Manager",
        "Department"
        $Script:ADLogString += Write-AuditLog -Message "Retriving the following ADUser properties: "
        $Script:ADLogString += Write-AuditLog -Message "$($propsArray -join " | ")"
        # Establish timeframe to review.
        $Script:ADLogString += Write-AuditLog -Message "Searching for accounts using search string `"$WildCardIdentifier`" "
        Start-Sleep 2
    }
    process {
        # Get Users
        $WildCardIdentifierstring = '*' + $WildCardIdentifier + '*'
        Get-ADUser -Filter { Name -like $WildCardIdentifierstring } `
            -Properties $propsArray -OutVariable ADExport | Out-Null
        $Script:ADLogString += Write-AuditLog -Message "Creating a custom object from ADUser output."
        $Export = @()
        foreach ($item in $ADExport) {
            $Export += [ADAuditTasksUser]::new(
                $($item.SamAccountName),
                $($item.GivenName),
                $($item.Surname),
                $($item.Name),
                $($item.UserPrincipalName),
                $($item.LastLogonTimeStamp),
                $($item.Enabled),
                $($item.LastLogonTimeStamp),
                $($item.DistinguishedName),
                $($item.Title),
                $($item.Manager),
                $($item.Department),
                $false,
                $false
            )
        }
    }
    end {
        $Script:ADLogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
        $Script:ADLogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
        $Script:ADLogString += Write-AuditLog -Message "$(($Export | Get-Member -MemberType property ).Name -join " | ")"
        if ($Report) {
            # Add Datetime to filename
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
            # Create FileNames
            $csv = "$ExportFileName.csv"
            $zip = "$ExportFileName.zip"
            $hash = "$ExportFileName.csv.SHA256.txt"
            $log = "$ExportFileName.AuditLog.csv"
            Build-ReportArchive -Export $Export -csv $csv -zip $zip -hash $hash -log $log -ErrorVariable BuildErr
        }
        else {
            $Script:ADLogString += Write-AuditLog -Message "Returning output object."
            Start-Sleep 2
            return $Export
        }
    }
}
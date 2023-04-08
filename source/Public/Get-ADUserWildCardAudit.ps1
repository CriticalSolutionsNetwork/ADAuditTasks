function Get-ADUserWildCardAudit {
<#
.SYNOPSIS
Takes a search string to find commonly named accounts.
.DESCRIPTION
Takes a search string to find commonly named accounts. For example, if you
commonly name service accounts with the prefix "svc", use "svc" for the
WildCardIdentifier to search for names that contain "svc".
.EXAMPLE
Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose

Searches for all user accounts that are named like the search string "svc".
.PARAMETER Report
Add report output as csv to AttachmentFolderPath directory.
.PARAMETER AttachmentFolderPath
Default path is C:\temp\ADUserWildCardAudit. This is the folder where attachments are going to be saved.
.PARAMETER Enabled
If "$false", will also search disabled users.
.PARAMETER DaysInactive
How far back in days to look for sign ins. Outside of this window, users are considered "Inactive"
.PARAMETER WildCardIdentifier
The search string to look for in the name of the account. Case does not matter. Do not add a
wildcard (*) as it will do this automatically.
.NOTES
This function requires the ActiveDirectory module.
.LINK
https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserWildCardAudit
.LINK
https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADUserWildCardAudit
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
        $Script:LogString = @()
        #Begin Logging
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        $Script:LogString += Write-AuditLog -Message "###############################################"
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        ### ActiveDirectory Module Install
        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        # Create Directory Path
        Build-DirectoryPath -DirectoryPath $AttachmentFolderPath
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
        $Script:LogString += Write-AuditLog -Message "###############################################"
        $Script:LogString += Write-AuditLog -Message "Retriving the following ADUser properties: "
        $Script:LogString += Write-AuditLog -Message "$($propsArray -join " | ")"
        # Establish timeframe to review.
        $Script:LogString += Write-AuditLog -Message "Searching for accounts using search string `"$WildCardIdentifier`" "
        Start-Sleep 2
    }
    process {
        # Get Users
        $WildCardIdentifierstring = '*' + $WildCardIdentifier + '*'
        Get-ADUser -Filter { Name -like $WildCardIdentifierstring } `
            -Properties $propsArray -OutVariable ADExport | Out-Null
        $Script:LogString += Write-AuditLog -Message "Creating a custom object from ADUser output."
        $Export = Build-ADAuditTasksUser -ADExport $ADExport
    }
    end {
        $Script:LogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
        $Script:LogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
        $Script:LogString += Write-AuditLog -Message "$(($Export | Get-Member -MemberType property ).Name -join " | ")"
        if ($Report) {
            # Add Datetime to filename
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
            # Create FileNames
            $csv = "$ExportFileName.csv"
            $zip = "$ExportFileName.zip"
            $log = "$ExportFileName.AuditLog.csv"
            Build-ReportArchive -Export $Export -csv $csv -zip $zip -log $log -ErrorVariable BuildErr
        }
        else {
            $Script:LogString += Write-AuditLog -Message "Returning output object."
            Start-Sleep 2
            return $Export
        }
    }
}
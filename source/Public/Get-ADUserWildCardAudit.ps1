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
        Write-AuditLog -Start
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        $DomainSuffix = (Get-CimInstance -ClassName Win32_ComputerSystem).Domain
        ### ActiveDirectory Module Install
        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        # Create Directory Path
        Initialize-DirectoryPath -DirectoryPath $AttachmentFolderPath
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
        Write-AuditLog "###############################################"
        Write-AuditLog "Retriving the following ADUser properties: "
        Write-AuditLog "$($propsArray -join " | ")"
        # Establish timeframe to review.
        Write-AuditLog "Searching for accounts using search string `"$WildCardIdentifier`" "
        Start-Sleep 2
    }
    process {
        $time = (Get-Date).Adddays( - ($DaysInactive))
        # Get Users
        write-auditlog "Enabled is: $Enabled"
        $WildCardIdentifierstring = '*' + $WildCardIdentifier + '*'
        Get-ADUser -Filter { Name -like $WildCardIdentifierstring -and LastLogonTimeStamp -lt $time -and Enabled -eq $Enabled } `
        -Properties $propsArray -OutVariable ADExport | Out-Null
        Write-AuditLog "Creating a custom object from ADUser output."
        $Export = Build-ADAuditTasksUser -ADExport $ADExport
    }
    end {
        Write-AuditLog "The $ScriptFunctionName Export was successful."
        Write-AuditLog "There are $(@($Export).Count) objects listed with the following properties: "
        Write-AuditLog "$(($Export | Get-Member -MemberType property ).Name -join " | ")"
        if ($Report) {
            # Add Datetime to filename
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($DomainSuffix)"
            # Create FileNames
            $csv = "$ExportFileName.csv"
            $zip = "$ExportFileName.zip"
            $log = "$ExportFileName.AuditLog.csv"
            Write-AuditLog -EndFunction
            Build-ReportArchive -Export $Export -csv $csv -zip $zip -log $log -AttachmentFolderPath $AttachmentFolderPath -ErrorVariable BuildErr
        }
        else {
            Write-AuditLog "Returning output object."
            Write-AuditLog -EndFunction
            Start-Sleep 1
            return $Export
        }
    }
}

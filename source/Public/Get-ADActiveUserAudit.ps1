function Get-ADActiveUserAudit {
<#
    .SYNOPSIS
    Gets active but stale AD User accounts that haven't logged in within the last 90 days by default.
    .DESCRIPTION
    Audit's Active Directory taking "days" as the input for how far back to check for a user's last sign in.
    Output can be piped to a csv manually, or automatically to C:\temp\ADActiveUserAudit or a specified path
    in "AttachmentFolderPath" using the -Report Switch.

    Any user account that is enabled and not signed in over 90 days is a candidate for removal.
    .EXAMPLE
    PS C:\> Get-ADActiveUserAudit
    .EXAMPLE
    PS C:\> Get-ADActiveUserAudit -Report -Verbose
    .EXAMPLE
    PS C:\> Get-ADActiveUserAudit -Enabled $false -DaysInactive 30 -AttachmentFolderPath "C:\temp\MyNewFolderName" -Report -Verbose
    .PARAMETER Report
    Add report output as csv to DirPath directory.
    .PARAMETER AttachmentFolderPath
    Default path is C:\temp\ADActiveUserAudit.
    This is the folder where attachments are going to be saved.
    .PARAMETER Enabled
    If "$false", will also search disabled users.
    .PARAMETER DaysInactive
    How far back in days to look for sign ins. Outside of this window, users are considered "Inactive"
    .NOTES
    Outputs to C:\temp\ADActiveUserAudit by default.
    For help type: help Get-ADActiveUserAudit -ShowWindow
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADActiveUserAudit
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADActiveUserAudit
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
            HelpMessage = 'Enter output folder path. Default: C:\temp\ADActiveUserAudit',
            Position = 2,
            ValueFromPipeline = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\ADActiveUserAudit",
        [Parameter(
            HelpMessage = 'Switch to export output to a csv and zipped to Directory C:\temp. Default: $false',
            Position = 3,
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report
    )
    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        ### ActiveDirectory Module Install
        if ($env:USERNAME -eq 'SYSTEM') {
            $DomainSuffix = $env:USERDOMAIN
        } else {
            $DomainSuffix = $env:USERDNSDOMAIN
        }

        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        # Create Directory Path if it does not exist.
        Initialize-DirectoryPath -DirectoryPath $AttachmentFolderPath
        # Gather ADUser Properties to search for.
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
        # Log the properties being retrieved.
        Write-AuditLog "###############################################"
        Write-AuditLog "Retrieving the following ADUser properties: "
        Write-AuditLog "$($propsArray -join " | ")"
        # Establish timeframe to review.
        $time = (Get-Date).Adddays( - ($DaysInactive))
        # Log the search criteria.
        Write-AuditLog "Searching for users who have not signed in within the last $DaysInactive days."
        Write-AuditLog "Where property Enabled = $Enabled"
        # Pause for 2 seconds to avoid potential race conditions.
        Start-Sleep 2
    }
    process {
        # Get Users
        Get-ADUser -Filter { LastLogonTimeStamp -gt $time -and Enabled -eq $Enabled } `
            -Properties $propsArray -OutVariable ADExport | Out-Null
        # Create custom object for the output
        $Export = Build-ADAuditTasksUser -ADExport $ADExport
    } # End Process
    end {
        # Log success message.
        Write-AuditLog "The $ScriptFunctionName Export was successful."

        # Log output object properties.
        Write-AuditLog "There are $($Export.Count) objects listed with the following properties: "
        Write-AuditLog "$(($Export | Get-Member -MemberType property ).Name -join " | ")"
        # Export to csv and zip, if requested.
        if ($Report) {
            # Add Datetime to filename.
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($DomainSuffix)"
            # Create FileNames.
            $csv = "$ExportFileName.csv"
            $zip = "$ExportFileName.zip"
            $log = "$ExportFileName.AuditLog.csv"
            # Call the Build-ReportArchive function to create the archive.
            Write-AuditLog -Endfunction
            Build-ReportArchive -Export $Export -csv $csv -zip $zip -log $log -AttachmentFolderPath $AttachmentFolderPath -ErrorAction SilentlyContinue -ErrorVariable BuildErr
        }
        else {
            # Log message indicating that the function is returning the output object.
            Write-AuditLog "Returning output object."
            Start-Sleep 1
            Write-AuditLog -Endfunction
            return $Export
        }
    }
}
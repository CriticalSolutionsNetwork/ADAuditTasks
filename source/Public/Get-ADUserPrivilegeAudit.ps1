function Get-ADUserPrivilegeAudit {
    <#
    .SYNOPSIS
    Produces three object outputs: PrivilegedGroups, AdExtendedRights, and possible service accounts.
    .DESCRIPTION
    The Get-ADUserPrivilegeAudit function produces reports on privileged groups, AD extended rights, and possible service accounts. If the -Report switch is used, the reports will be created in the specified folder. To instantiate variables with the objects, provide three objects on the left side of the assignment:

    Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose

    The objects will be populated with privileged groups, AD extended rights, and possible service accounts, respectively.
    .EXAMPLE
    Get-ADUserPrivilegeAudit -Verbose
    Gets the reports as three separate objects. To instantiate variables with the objects, provide three objects on the left side of the assignment:
    Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose
    The objects will be populated with privileged groups, AD extended rights, and possible service accounts, respectively.
    .EXAMPLE
    Get-ADUserPrivilegeAudit -Report -Verbose
    Returns three reports to the default folder, C:\temp\ADUserPrivilegeAudit, in a single zip file.
    .PARAMETER AttachmentFolderPath
    Specifies the path of the folder where you want to save attachments. The default path is C:\temp\ADUserPrivilegeAudit.
    .PARAMETER Report
    Adds report output as CSV to the directory specified by AttachmentFolderPath.
    .NOTES
    This function requires the ActiveDirectory module.
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserPrivilegeAudit
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADUserPrivilegeAudit
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject[]], [string], [System.Object[]])]
    param (
        # Input parameter: output folder path for generated reports
        [Parameter(
            HelpMessage = ' Enter output folder path. Default: C:\temp\ADUserPrivilegeAudit ',
            Position = 0,
            ValueFromPipeline = $true
        )]
        [string]$AttachmentFolderPath = 'C:\temp\ADUserPrivilegeAudit',
        # Input parameter: switch to export output to a CSV and zip to the specified directory
        [Parameter(
            HelpMessage = 'Switch to export output to a CSV and zipped to Directory C:\temp\ADUserPrivilegeAudit Default: $false',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report
    )
    begin {
        Write-AuditLog -Start
        Write-AuditLog "###############################################"
        # Get name of the function
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        if ($env:USERNAME -eq 'SYSTEM') {
            $DomainSuffix = $env:USERDOMAIN
        } else {
            $DomainSuffix = $env:USERDNSDOMAIN
        }
        # Check if ActiveDirectory module is installed
        ### ActiveDirectory Module Install
        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        # Create output directory if it does not already exist
        Initialize-DirectoryPath -DirectoryPath $AttachmentFolderPath
        # Create Privilege Groups Array.
        $AD_PrivilegedGroups = @(
            'Enterprise Admins',
            'Schema Admins',
            'Domain Admins',
            'Administrators',
            'Cert Publishers',
            'Account Operators',
            'Server Operators',
            'Backup Operators',
            'Print Operators',
            'DnsAdmins',
            'DnsUpdateProxy',
            'DHCP Administrators'
        )
        # Time Variables
        $time90 = (Get-Date).Adddays( - (90))
        $time60 = (Get-Date).Adddays( - (60))
        $time30 = (Get-Date).Adddays( - (30))
        # Create Arrays
        $members = @()
        $ADUsers = @()
        # AD Groups to search for.
        Write-AuditLog "###############################################"
        Write-AuditLog "Retriving info from the following priveledged groups: "
        Write-AuditLog "$($AD_PrivilegedGroups -join " | ")"
        Start-Sleep 2
    }
    process {
        # Iterate through each group in $AD_PrivilegedGroups
        foreach ($group in $AD_PrivilegedGroups) {
            # Clear the GroupMember variable and retrieve all members of the current group
            Clear-Variable GroupMember -ErrorAction SilentlyContinue
            Get-ADGroupMember -Identity $group -Recursive -OutVariable GroupMember | Out-Null
            # Select the desired properties for each member and add custom properties to the output
            $GroupMember | Select-Object SamAccountName, Name, ObjectClass, `
            @{N = 'PriviledgedGroup'; E = { $group } }, `
            @{N = 'Enabled'; E = { (Get-ADUser -Identity $_.samaccountname).Enabled } }, `
            @{N = 'PasswordNeverExpires'; E = { (Get-ADUser -Identity $_.samaccountname -Properties PasswordNeverExpires).PasswordNeverExpires } }, `
            @{N = 'LastLogin'; E = { [DateTime]::FromFileTime((Get-ADUser -Identity $_.samaccountname -Properties lastLogonTimestamp).lastLogonTimestamp) } }, `
            @{N = 'LastSeen'; E = {
                    switch ([DateTime]::FromFileTime((Get-ADUser -Identity $_.samaccountname -Properties lastLogonTimestamp).lastLogonTimestamp)) {
                        # Over 90 Days
                        { ($_ -lt $time90) } { '3+ months'; break }
                        # Over 60 Days
                        { ($_ -lt $time60) } { '2+ months'; break }
                        # Over 90 Days
                        { ($_ -lt $time30) } { '1+ month'; break }
                        default { 'Recently' }
                    }
                }
            }, `
            @{N = 'OrgUnit'; E = { $_.DistinguishedName -replace '^.*?,(?=[A-Z]{2}=)' } }, `
            @{N = 'GroupMemberships'; E = { Get-ADGroupMemberof -SamAccountName $_.samaccountname } }, `
                Title, `
            @{N = 'Manager'; E = { (Get-ADUser -Identity $_.manager).Name } }, `
            @{N = 'SuspectedSvcAccount'; E = {
                    # Check if the account is a suspected service account based on PasswordNeverExpires or servicePrincipalName
                    if (((Get-ADUser -Identity $_.samaccountname -Properties PasswordNeverExpires).PasswordNeverExpires) -or ( $null -ne  ((Get-ADUser -Identity $_.samaccountname -Properties servicePrincipalName).servicePrincipalName) ) ) {
                        return $true
                    }
                    else {
                        return $false
                    }
                } # End Expression
            }, # End Named Expression SuspectedSvcAccount
            Department, AccessRequired, NeedMailbox -OutVariable members | Out-Null
            # Add the member objects to $ADUsers array
            $ADUsers += $members
        }
        # Create an array to store the output objects
        $Export = @()
        # Iterate through each member in $ADUsers and create a custom object with desired properties
        foreach ($User in $ADUsers) {
            $hash = [ordered]@{
                PriviledgedGroup     = $User.PriviledgedGroup
                SamAccountName       = $User.SamAccountName
                Name                 = $User.Name
                ObjectClass          = $User.ObjectClass
                LastLogin            = $User.LastLogin
                LastSeen             = $User.LastSeen
                GroupMemberships     = $User.GroupMemberships
                Title                = $User.Title
                Manager              = $User.Manager
                Department           = $User.Department
                OrgUnit              = $User.OrgUnit
                Enabled              = $User.Enabled
                PasswordNeverExpires = $User.PasswordNeverExpires
                SuspectedSvcAccount  = $User.SuspectedSvcAccount
                AccessRequired       = $false
                NeedMailbox          = $true
            }
            New-Object -TypeName PSCustomObject -Property $hash -OutVariable PSObject | Out-Null
            $Export += $PSObject
        }
        # Log success message for $ScriptFunctionName export
        Write-AuditLog "The $ScriptFunctionName Export was successful."
        # Log count and properties of objects in $Export
        Write-AuditLog "There are $($Export.Count) objects listed with the following properties: "
        Write-AuditLog "$(($Export | Get-Member -MemberType noteproperty ).Name -join " | ")"

        # Get PDC
        $dc = (Get-ADDomainController -Discover -DomainName $DomainSuffix -Service PrimaryDC).Name
        # Get DN of AD Root.
        $rootou = (Get-ADRootDSE).defaultNamingContext
        # Get AD objects from the PDC for the root ou. #TODO Check
        $Allobjects = Get-ADObject -Server $dc -SearchBase $rootou -SearchScope subtree -LDAPFilter `
            "(&(objectclass=user)(objectcategory=person))" -Properties ntSecurityDescriptor -ResultSetSize $null

        # Create $Export2 object by looping through all objects in $Allobjects and retrieving extended rights
        $Export2 = Foreach ($ADObject in $Allobjects) {
            Get-AdExtendedRight $ADObject
        }
        # Log success message for extended permissions export
        Write-AuditLog "The Extended Permissions Export was successful."
        # Log count and properties of objects in $Export2
        Write-AuditLog "There are $($Export2.Count) objects listed with the following properties: "
        Write-AuditLog "$(($Export2 | Get-Member -MemberType noteproperty ).Name -join " | ")"

        # Export Delegated access, allowed protocols, and Destination Services by filtering for relevant properties
        $Export3 = Get-ADObject -Filter { (msDS-AllowedToDelegateTo -like '*') -or (UserAccountControl -band 0x0080000) -or (UserAccountControl -band 0x1000000) } `
            -prop samAccountName, msDS-AllowedToDelegateTo, servicePrincipalName, userAccountControl | `
            Select-Object DistinguishedName, ObjectClass, samAccountName, `
        @{N = 'servicePrincipalName'; E = { $_.servicePrincipalName -join " | " } }, `
        @{N = 'DelegationStatus'; E = { if ($_.UserAccountControl -band 0x80000) { 'AllServices' }else { 'SpecificServices' } } }, `
        @{N = 'AllowedProtocols'; E = { if ($_.UserAccountControl -band 0x1000000) { 'Any' }else { 'Kerberos' } } }, `
        @{N = 'DestinationServices'; E = { $_.'msDS-AllowedToDelegateTo' } }

        # Log success message for delegated permissions export
        Write-AuditLog "The delegated permissions Export was successful."
        # Log count and properties of objects in $Export3
        Write-AuditLog "There are $($Export3.Count) objects listed with the following properties: "
        Write-AuditLog "$(($Export3 | Get-Member -MemberType noteproperty ).Name -join " | ")"
    }
    end {
        if ($Report) {
            # Add Datetime to filename
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($DomainSuffix)"
            # Create FileNames
            $csv1 = "$ExportFileName.csv"
            $csv2 = "$ExportFileName.ExtendedPermissions.csv"
            $csv3 = "$ExportFileName.PossibleServiceAccounts.csv"
            $zip1 = "$ExportFileName.zip"
            $log = "$ExportFileName.AuditLog.csv"
            # Export results to CSV files
            $Export | Export-Csv $csv1 -NoTypeInformation
            $Export2 | Export-Csv $csv2 -NoTypeInformation
            $Export3 | Export-Csv $csv3 -NoTypeInformation
            # Compute SHA256 hash for each CSV file
            $csv1Sha256Hash = (Get-FileHash $csv1).Hash
            $csv2Sha256Hash = (Get-FileHash $csv2).Hash
            $csv3Sha256Hash = (Get-FileHash $csv3).Hash
            # Log SHA256 hash for each CSV file
            Write-AuditLog "Exported CSV $csv1 SHA256 hash: "
            Write-AuditLog "$($csv1Sha256Hash)"
            Write-AuditLog "Exported CSV $csv2 SHA256 hash: "
            Write-AuditLog "$($csv2Sha256Hash)"
            Write-AuditLog "Exported CSV $csv3 SHA256 hash: "
            Write-AuditLog "$($csv3Sha256Hash)"
            # Log directory path and ZIP file path
            Write-AuditLog "Directory: $AttachmentFolderPath"
            Write-AuditLog "Returning string filepath of: "
            Write-AuditLog "FilePath: $zip1"
            # Export audit log to CSV file
            # $Script:LogString | Export-Csv $log -NoTypeInformation -Encoding utf8
            # Compress CSV files and audit log into a ZIP file
            Write-AuditLog -End -OutputPath $log
            Compress-Archive $csv1, $csv2, $csv3, $log -DestinationPath $zip1 -CompressionLevel Optimal
            # Remove CSV and audit log files
            Remove-Item $csv1, $csv2, $csv3, $log -Force
            # Return ZIP file path
            return $zip1
        }
        else {
            # Return output objects
            Write-AuditLog "Returning 3 output objects. Instantiate object Example:  `$a, `$b, `$c, = Get-ADUserPrivilegedAudit"
            Write-AuditLog -EndFunction
            Start-Sleep 1
            return $Export, $Export2, $Export3
        }
    }
}

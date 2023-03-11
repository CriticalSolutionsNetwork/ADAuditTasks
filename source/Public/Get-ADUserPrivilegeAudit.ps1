function Get-ADUserPrivilegeAudit {
    <#
    .SYNOPSIS
        Produces three object outputs: PrivilegedGroups, AdExtendedRights, and possible service accounts.
    .DESCRIPTION
        The Get-ADUserPrivilegeAudit function produces reports on privileged groups,
        AD extended rights, and possible service accounts. If the -Report switch is
        used, the reports will be created in the specified folder. To instantiate
        variables with the objects, provide three objects on the left side of the
        assignment:

        Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose

        The objects will be populated with privileged groups, AD extended rights,
        and possible service accounts, respectively.
    .EXAMPLE
        Get-ADUserPrivilegeAudit -Verbose

        Gets the reports as three separate objects. To instantiate variables with
        the objects, provide three objects on the left side of the assignment:

        Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose

        The objects will be populated with privileged groups, AD extended rights,
        and possible service accounts, respectively.
    .EXAMPLE
        Get-ADUserPrivilegeAudit -Report -Verbose

        Returns three reports to the default folder, C:\temp\ADUserPrivilegeAudit,
        in a single zip file.
    .PARAMETER AttachmentFolderPath
        Specifies the path of the folder where you want to save attachments.
        The default path is C:\temp\ADUserPrivilegeAudit.
    .PARAMETER Report
        Adds report output as CSV to the directory specified by AttachmentFolderPath.
    .NOTES
        This function requires the ActiveDirectory module.
    #>
    [CmdletBinding()]
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
        # Create logging object
        $ADLogString = @()
        # Begin Logging
        $ADLogString += Write-AuditLog -Message "Begin Log"
        # Get name of the function
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        # Check if ActiveDirectory module is installed
        $module = Get-Module -Name ActiveDirectory -ListAvailable -InformationAction SilentlyContinue
        if (-not $module) {
            # Prompt user to install ActiveDirectory module
            $ADLogString += Write-AuditLog -Message "Install Active Directory Module?" -Severity Warning
            try {
                # Install ActiveDirectory module using Server Manager
                Import-Module ServerManager -ErrorAction Stop -InformationAction SilentlyContinue -ErrorVariable InstallADModuleErr
                Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop  -InformationAction SilentlyContinue -ErrorVariable InstallADModuleErr
            }
            catch {
                # If module is not installed and cannot be installed, throw an error
                $ADLogString += Write-AuditLog -Message "You must install the Active Directory module to continue" -Severity Error
                throw $InstallADModuleError
            }
        } # End If not Module
        try {
            # Import ActiveDirectory module
            Import-Module "ActiveDirectory" -Global -ErrorAction Stop -InformationAction SilentlyContinue -ErrorVariable ImportADModuleErr
        }
        catch {
            # If module is not imported, throw an error
            $ADLogString += Write-AuditLog -Message "You must import the Active Directory module to continue" -Severity Error
            throw $ImportADModuleErr
        } # End Try Catch
        # Create output directory if it does not already exist
        $AttachmentFolderPathCheck = Test-Path -Path $AttachmentFolderPath
        If (!($AttachmentFolderPathCheck)) {
            # Prompt user to create output directory
            $ADLogString += Write-AuditLog -Message "Would you like to create the directory $($AttachmentFolderPath)?" -Severity Warning
            Try {
                # Create output directory if it does not already exist
                New-Item -ItemType Directory $AttachmentFolderPath -Force -ErrorAction Stop | Out-Null
            }
            Catch {
                # If directory cannot be created, throw an error
                $ADLogString += Write-AuditLog -Message $("Directory: " + $AttachmentFolderPath + "was not created.") -Severity Error
                $ADLogString += Write-AuditLog -Message "End Log"
                throw $ADLogString
            }
            # Log the creation of the output directory
            $ADLogString += Write-AuditLog -Message "$("Output Folder created at: `n" + $AttachmentFolderPath)"
            Start-Sleep 2
        }
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
        $ADLogString += Write-AuditLog -Message "Retriving info from the following priveledged groups: "
        $ADLogString += Write-AuditLog -Message "$($AD_PrivilegedGroups -join " | ")"
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
                    if (((Get-ADUser -Identity $_.samaccountname -Properties PasswordNeverExpires).PasswordNeverExpires) -or (((Get-ADUser -Identity $_.samaccountname -Properties servicePrincipalName).servicePrincipalName) -ne $null) ) {
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
        $ADLogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
        # Log count and properties of objects in $Export
        $ADLogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
        $ADLogString += Write-AuditLog -Message "$(($Export | Get-Member -MemberType noteproperty ).Name -join " | ")"

        # Get PDC
        $dc = (Get-ADDomainController -Discover -DomainName $env:USERDNSDOMAIN -Service PrimaryDC).Name
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
        $ADLogString += Write-AuditLog -Message "The Extended Permissions Export was successful."
        # Log count and properties of objects in $Export2
        $ADLogString += Write-AuditLog -Message "There are $($Export2.Count) objects listed with the following properties: "
        $ADLogString += Write-AuditLog -Message "$(($Export2 | Get-Member -MemberType noteproperty ).Name -join " | ")"

        # Export Delegated access, allowed protocols, and Destination Services by filtering for relevant properties
        $Export3 = Get-ADObject -Filter { (msDS-AllowedToDelegateTo -like '*') -or (UserAccountControl -band 0x0080000) -or (UserAccountControl -band 0x1000000) } `
            -prop samAccountName, msDS-AllowedToDelegateTo, servicePrincipalName, userAccountControl | `
            Select-Object DistinguishedName, ObjectClass, samAccountName, `
        @{N = 'servicePrincipalName'; E = { $_.servicePrincipalName -join " | " } }, `
        @{N = 'DelegationStatus'; E = { if ($_.UserAccountControl -band 0x80000) { 'AllServices' }else { 'SpecificServices' } } }, `
        @{N = 'AllowedProtocols'; E = { if ($_.UserAccountControl -band 0x1000000) { 'Any' }else { 'Kerberos' } } }, `
        @{N = 'DestinationServices'; E = { $_.'msDS-AllowedToDelegateTo' } }

        # Log success message for delegated permissions export
        $ADLogString += Write-AuditLog -Message "The delegated permissions Export was successful."
        # Log count and properties of objects in $Export3
        $ADLogString += Write-AuditLog -Message "There are $($Export3.Count) objects listed with the following properties: "
        $ADLogString += Write-AuditLog -Message "$(($Export3 | Get-Member -MemberType noteproperty ).Name -join " | ")"
    }
    end {
        if ($Report) {
            # Add Datetime to filename
            $ExportFileName = "$AttachmentFolderPath\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($ScriptFunctionName)_$($env:USERDNSDOMAIN)"
            # Create FileNames
            $csv1 = "$ExportFileName.csv"
            $csv2 = "$ExportFileName.ExtendedPermissions.csv"
            $csv3 = "$ExportFileName.PossibleServiceAccounts.csv"
            $zip1 = "$ExportFileName.zip"
            $log = "$ExportFileName.AuditLog.csv"
            # Export results to CSV files
            $Export | Export-Csv $csv1
            $Export2 | Export-Csv $csv2
            $Export3 | Export-Csv $csv3
            # Compute SHA256 hash for each CSV file
            $csv1Sha256Hash = (Get-FileHash $csv1).Hash
            $csv2Sha256Hash = (Get-FileHash $csv2).Hash
            $csv3Sha256Hash = (Get-FileHash $csv3).Hash
            # Log SHA256 hash for each CSV file
            $ADLogString += Write-AuditLog -Message "Exported CSV $csv1 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv1Sha256Hash)"
            $ADLogString += Write-AuditLog -Message "Exported CSV $csv2 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv2Sha256Hash)"
            $ADLogString += Write-AuditLog -Message "Exported CSV $csv3 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv3Sha256Hash)"
            # Log directory path and ZIP file path
            $ADLogString += Write-AuditLog -Message "Directory: $AttachmentFolderPath"
            $ADLogString += Write-AuditLog -Message "Returning string filepath of: "
            $ADLogString += Write-AuditLog -Message "FilePath: $zip1"
            # Export audit log to CSV file
            $ADLogString | Export-Csv $log -NoTypeInformation -Encoding utf8
            # Compress CSV files and audit log into a ZIP file
            Compress-Archive $csv1, $csv2, $csv3, $log -DestinationPath $zip1 -CompressionLevel Optimal
            # Remove CSV and audit log files
            Remove-Item $csv1, $csv2, $csv3, $log -Force
            # Return ZIP file path
            return $zip1
        }
        else {
            # Return output objects
            $ADLogString += Write-AuditLog -Message "Returning 3 output objects. Create object like this:  `$a, `$b, `$c, = Get-ADUserPrivilegedAudit"
            Start-Sleep 2
            return $Export, $Export2, $Export3
        }
    }

}
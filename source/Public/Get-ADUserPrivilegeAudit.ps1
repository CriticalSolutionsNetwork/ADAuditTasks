function Get-ADUserPrivilegeAudit {
    <#
    .SYNOPSIS
        Produces 3 object outputs: PrivilegedGroups, AdExtendedRights and possible service accounts.
    .DESCRIPTION
        Reports will be created in the C:\temp directory if the -Report Switch is used.
        To instantiate variables with the objects, provide 3 objects on the left side of the assignment:
            For Example: $a,$b,$c = Get-ADUserPrivilegeAudit -verbose
        The objects will be populated with PrivilegedGroups, AdExtendedRights and possible
        service accounts respectively.
    .EXAMPLE
        Get-ADUserPrivilegeAudit -Verbose
        Get the reports as three separate objects.
            To instantiate variables with the objects, provide 3 objects on the left side of the assignment:
                For Example: $a,$b,$c = Get-ADUserPrivilegeAudit -verbose
                The objects will be populated with PrivilegedGroups, AdExtendedRights and possible
                service accounts respectively.
    .EXAMPLE
        Get-ADUserPrivilegeAudit -Report -Verbose
            Will return 3 reports to the default temp directory in a single zip file.
    .PARAMETER AttachmentFolderPath
        The path of the folder you want to save attachments to. The default is:
            C:\temp\ADUserPrivilegeAudit'
    .PARAMETER Report
        Add report output as csv to DirPath directory.
    #>


    [CmdletBinding()]
    param (
        [Parameter(
            HelpMessage = 'Enter output folder path. Default: C:\temp\ADUserPrivilegeAudit',
            Position = 0,
            ValueFromPipeline = $true
        )]
        [string]$AttachmentFolderPath = "C:\temp\ADUserPrivilegeAudit",
        [Parameter(
            HelpMessage = 'Switch to export output to a csv and zipped to Directory C:\temp\ADUserPrivilegeAudit Default: $false',
            Position = 1,
            ValueFromPipelineByPropertyName = $true
        )]
        [switch]$Report
    )
    begin {
        #Create logging object
        $ADLogString = @()
        #Begin Logging
        $ADLogString += Write-AuditLog -Message "Begin Log"
        $ScriptFunctionName = $MyInvocation.MyCommand.Name -replace '\..*'
        $module = Get-Module -Name ActiveDirectory -ListAvailable -InformationAction SilentlyContinue
        if (-not $module) {
            $ADLogString += Write-AuditLog -Message "Install Active Directory Module?" -Severity Warning
            try {
                Import-Module ServerManager -ErrorAction Stop -ErrorVariable InstallADModuleErr
                Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop -ErrorVariable InstallADModuleErr
            }
            catch {
                $ADLogString += Write-AuditLog -Message "You must install the Active Directory module to continue" -Severity Error
                throw $InstallADModuleError
            }
        } # End If not Module
        try {
            Import-Module "ActiveDirectory" -Global -ErrorAction Stop -InformationAction SilentlyContinue -ErrorVariable ImportADModuleErr
        }
        catch {
            $ADLogString += Write-AuditLog -Message "You must import the Active Directory module to continue" -Severity Error
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
                $ADLogString += Write-AuditLog -Message $("Directory: " + $AttachmentFolderPath + "was not created.") -Severity Error
                $ADLogString += Write-AuditLog -Message "End Log"
                throw $ADLogString
            }
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
        foreach ($group in $AD_PrivilegedGroups) {
            Clear-Variable GroupMember -ErrorAction SilentlyContinue
            Get-ADGroupMember -Identity $group -Recursive -OutVariable GroupMember | Out-Null
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
                    # Null gave unexpected behavior on the left side. Works on the right side.
                    if (((Get-ADUser -Identity $_.samaccountname -Properties PasswordNeverExpires).PasswordNeverExpires) -or (((Get-ADUser -Identity $_.samaccountname -Properties servicePrincipalName).servicePrincipalName) -ne $null) ) {
                        return $true
                    } # end if
                    else {
                        return $false
                    } # end else
                } # End Expression
            }, # End Named Expression SuspectedSvcAccount
            Department, AccessRequired, NeedMailbox -OutVariable members | Out-Null
            $ADUsers += $members
        }
        $Export = @()
        # Create $Export Object
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
        $ADLogString += Write-AuditLog -Message "The $ScriptFunctionName Export was successful."
        $ADLogString += Write-AuditLog -Message "There are $($Export.Count) objects listed with the following properties: "
        $ADLogString += Write-AuditLog -Message "$(($Export | Get-Member -MemberType noteproperty ).Name -join " | ")"
        # Get PDC
        $dc = (Get-ADDomainController -Discover -DomainName $env:USERDNSDOMAIN -Service PrimaryDC).Name
        # Get DN of AD Root.
        $rootou = (Get-ADRootDSE).defaultNamingContext
        # Get ad objects from the PDC for the root ou. #TODO Check
        $Allobjects = Get-ADObject -Server $dc -SearchBase $rootou -SearchScope subtree -LDAPFilter `
            "(&(objectclass=user)(objectcategory=person))" -Properties ntSecurityDescriptor -ResultSetSize $null
        # "(|(objectClass=domain)(objectClass=organizationalUnit)(objectClass=group)(sAMAccountType=805306368)(objectCategory=Computer)(&(objectclass=user)(objectcategory=person)))"
        # Create $Export2 Object
        $Export2 = Foreach ($ADObject in $Allobjects) {
            Get-AdExtendedRight $ADObject
        }
        $ADLogString += Write-AuditLog -Message "The Extended Permissions Export was successful."
        $ADLogString += Write-AuditLog -Message "There are $($Export2.Count) objects listed with the following properties: "
        $ADLogString += Write-AuditLog -Message "$(($Export2 | Get-Member -MemberType noteproperty ).Name -join " | ")"
        # Export Delegated access, allowed protocols and Destination Serivces.
        $Export3 = Get-ADObject -Filter { (msDS-AllowedToDelegateTo -like '*') -or (UserAccountControl -band 0x0080000) -or (UserAccountControl -band 0x1000000) } `
            -prop samAccountName, msDS-AllowedToDelegateTo, servicePrincipalName, userAccountControl | `
            Select-Object DistinguishedName, ObjectClass, samAccountName, `
        @{N = 'servicePrincipalName'; E = { $_.servicePrincipalName -join " | " } }, `
        @{N = 'DelegationStatus'; E = { if ($_.UserAccountControl -band 0x80000) { 'AllServices' }else { 'SpecificServices' } } }, `
        @{N = 'AllowedProtocols'; E = { if ($_.UserAccountControl -band 0x1000000) { 'Any' }else { 'Kerberos' } } }, `
        @{N = 'DestinationServices'; E = { $_.'msDS-AllowedToDelegateTo' } }
        # Log Success
        $ADLogString += Write-AuditLog -Message "The delegated permissions Export was successful."
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
            $hash1 = "$ExportFileName.csv.SHA256.txt"
            $hash2 = "$ExportFileName.ExtendedPermissions.csv.SHA256.txt"
            $hash3 = "$ExportFileName.PossibleServiceAccounts.csv.SHA256.txt"
            $log = "$ExportFileName.AuditLog.csv"

            $Export | Export-Csv $csv1
            $Export2 | Export-Csv $csv2
            $Export3 | Export-Csv $csv3
            $csv1Sha256Hash = (Get-FileHash $csv1).Hash
            $csv1Sha256Hash | Out-File $hash1 -Encoding utf8
            $csv2Sha256Hash = (Get-FileHash $csv2).Hash
            $csv2Sha256Hash | Out-File $hash2 -Encoding utf8
            $csv3Sha256Hash = (Get-FileHash $csv3).Hash
            $csv3Sha256Hash | Out-File $hash3 -Encoding utf8

            $ADLogString += Write-AuditLog -Message "Exported CSV $csv1 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv1Sha256Hash)"
            $ADLogString += Write-AuditLog -Message "Exported CSV $csv2 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv2Sha256Hash)"
            $ADLogString += Write-AuditLog -Message "Exported CSV $csv3 SHA256 hash: "
            $ADLogString += Write-AuditLog -Message "$($csv3Sha256Hash)"
            $ADLogString += Write-AuditLog -Message "Directory: $AttachmentFolderPath"
            $ADLogString += Write-AuditLog -Message "Returning string filepath of: "
            $ADLogString += Write-AuditLog -Message "FilePath: $zip1"


            $ADLogString | Export-Csv $log -NoTypeInformation -Encoding utf8

            Compress-Archive $csv1, $csv2, $csv3, $hash1, $hash2, $hash3, $log -DestinationPath $zip1 -CompressionLevel Optimal
            Remove-Item $csv1, $csv2, $csv3, $hash1, $hash2, $hash3, $log -Force
            return $zip1
        }
        else {
            $ADLogString += Write-AuditLog -Message "Returning 3 output objects. Create object like this:  `$a, `$b, `$c, = Get-ADUserPrivilegedAudit"
            Start-Sleep 2
            return $Export, $Export2, $Export3
        }
    }
}
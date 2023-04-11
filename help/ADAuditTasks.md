---
Module Name: ADAuditTasks
Module Guid: 6b72cdb3-2101-4a7e-b0d0-968a70018809
Download Help Link: https://criticalsolutions.net/ADAuditTasks/CAB/
Help Version: 1.0.0.3
Locale: en-US
---

# ADAuditTasks Module
## Description
The ADAuditTasks module is a PowerShell module that provides a set of cmdlets for auditing Active Directory environments. The cmdlets in this module can be used to perform various audit tasks, including user and host auditing, logon auditing, privilege auditing, network auditing, and web certificate auditing. The module is designed to simplify the process of auditing Active Directory environments and provides easy-to-use cmdlets that can be run from a PowerShell console or script. With the ADAuditTasks module, you can easily gather and analyze data about your Active Directory environment to identify potential security risks and improve the overall security of your organization.

## ADAuditTasks Cmdlets
### [Convert-NmapXMLToCSV](Convert-NmapXMLToCSV)
Converts an Nmap XML scan output file to a CSV file.

### [Get-ADActiveUserAudit](Get-ADActiveUserAudit)
Gets active but stale AD User accounts that haven't logged in within the last 90 days by default.

### [Get-ADHostAudit](Get-ADHostAudit)
Active Directory Server and Workstation Audit with Report export option (Can also be piped to CSV if Report isn't specified).

### [Get-ADUserLogonAudit](Get-ADUserLogonAudit)
Retrieves the most recent LastLogon timestamp for a specified Active Directory user
account from all domain controllers and outputs it as a DateTime object.

### [Get-ADUserPrivilegeAudit](Get-ADUserPrivilegeAudit)
Produces three object outputs: PrivilegedGroups, AdExtendedRights, and possible service accounts.

### [Get-ADUserWildCardAudit](Get-ADUserWildCardAudit)
Takes a search string to find commonly named accounts.

### [Get-HostTag](Get-HostTag)
Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.

### [Get-NetworkAudit](Get-NetworkAudit)
Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.

### [Get-QuickPing](Get-QuickPing)
Performs a quick ping on a range of IP addresses and returns an array of IP addresses
that responded to the ping and an array of IP addresses that failed to respond.

### [Get-WebCertAudit](Get-WebCertAudit)
Retrieves the certificate information for a web server.

### [Join-CSVFiles](Join-CSVFiles)
Joins multiple CSV files with the same headers into a single CSV file.

### [Merge-ADAuditZip](Merge-ADAuditZip)
Combines multiple audit report files into a single compressed ZIP file.

### [Merge-NmapToADHostAudit](Merge-NmapToADHostAudit)
Merges Nmap network audit data with Active Directory host audit data.

### [New-GraphEmailApp](New-GraphEmailApp)
Creates a new Microsoft Graph Email app and associated certificate for app-only authentication.

### [New-PatchTuesdayReport](New-PatchTuesdayReport)
Generates a Patch Tuesday report HTML file based on a CSV input file.

### [Send-AuditEmail](Send-AuditEmail)
This is a wrapper function for Send-MailKitMessage and takes string arrays as input.

### [Send-GraphAppEmail](Send-GraphAppEmail)
Sends an email using the Microsoft Graph API.

### [Submit-FTPUpload](Submit-FTPUpload)
Uploads a file to an FTP server using the WinSCP module.


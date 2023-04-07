---
Module Name: ADAuditTasks
Module Guid: 6b72cdb3-2101-4a7e-b0d0-968a70018809
Download Help Link: {{ Update Download Link }}
Help Version: {{ Please enter version of help manually (X.X.X.X) format }}
Locale: en-US
---

# ADAuditTasks Module
## Description
{{ Fill in the Description }}

## ADAuditTasks Cmdlets
### [Convert-NmapXMLToCSV](Convert-NmapXMLToCSV.md)
Converts an Nmap XML scan output file to a CSV file.

### [Get-ADActiveUserAudit](Get-ADActiveUserAudit.md)
Gets active but stale AD User accounts that haven't logged in within the last 90 days by default.

### [Get-ADHostAudit](Get-ADHostAudit.md)
Active Directory Server and Workstation Audit with Report export option (Can also be piped to CSV if Report isn't specified).

### [Get-ADUserLogonAudit](Get-ADUserLogonAudit.md)
Retrieves the most recent LastLogon timestamp for a specified Active Directory user account from all domain controllers and outputs it as a DateTime object.

### [Get-ADUserPrivilegeAudit](Get-ADUserPrivilegeAudit.md)
Produces three object outputs: PrivilegedGroups, AdExtendedRights, and possible service accounts.

### [Get-ADUserWildCardAudit](Get-ADUserWildCardAudit.md)
Takes a search string to find commonly named accounts.

### [Get-HostTag](Get-HostTag.md)
Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.

### [Get-NetworkAudit](Get-NetworkAudit.md)
Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.

### [Get-QuickPing](Get-QuickPing.md)
Performs a quick ping on a range of IP addresses and returns an array of IP addresses
that responded to the ping and an array of IP addresses that failed to respond.

### [Get-WebCertAudit](Get-WebCertAudit.md)
Retrieves the certificate information for a web server.

### [Join-CSVFiles](Join-CSVFiles.md)
Joins multiple CSV files with the same headers into a single CSV file.

### [Merge-ADAuditZip](Merge-ADAuditZip.md)
Combines multiple audit report files into a single compressed ZIP file.

### [Merge-NmapToADHostAudit](Merge-NmapToADHostAudit.md)
Merges Nmap network audit data with Active Directory host audit data.

### [New-GraphEmailApp](New-GraphEmailApp.md)
Creates a new Microsoft Graph Email app and associated certificate for app-only authentication.

### [New-PatchTuesdayReport](New-PatchTuesdayReport.md)
Generates a Patch Tuesday report HTML file based on a CSV input file.

### [Send-AuditEmail](Send-AuditEmail.md)
This is a wrapper function for Send-MailKitMessage and takes string arrays as input.

### [Send-GraphAppEmail](Send-GraphAppEmail.md)
Sends an email using the Microsoft Graph API.

### [Submit-FTPUpload](Submit-FTPUpload.md)
Uploads a file to an FTP server using the WinSCP module.


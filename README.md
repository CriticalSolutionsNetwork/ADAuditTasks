# ADAuditTasks Module
[![PSScriptAnalyzer](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/actions/workflows/powershell.yml/badge.svg)](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/actions/workflows/powershell.yml)
[![pages-build-deployment](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/actions/workflows/pages/pages-build-deployment)

[Patch Tuesday Newsletter](https://patchtuesday.criticalsolutions.net/)
## Summary

The ADAuditTasks module provides a comprehensive set of tools for auditing and reporting on Active Directory resources, including users, computers, and network devices. The module generates logs, CSV output, and report objects, which can be sent via email using the `Send-AuditEmail` function.

## Help Documentation

See the [ADAuditTasks help documentation](https://criticalsolutionsnetwork.github.io/ADAuditTasks/) or the [Wiki](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki) for more information on this module and how to use it.

## Public Functions

The following Public Functions are available to the user executing the tasks:

- `Convert-NmapXMLToCSV`
- `Get-ADActiveUserAudit`
- `Get-ADHostAudit`
- `Get-ADUserLogonAudit`
- `Get-ADUserPrivilegeAudit`
- `Get-ADUserWildCardAudit`
- `Get-NetworkAudit`
- `Get-WebCertAudit`
- `Get-HostTag`
- `Get-QuickPing`
- `Join-CSVFile`
- `Merge-ADAuditZip`
- `Merge-NmapToADHostAudit`
- `Send-AuditEmail`
- `Submit-FTPUpload`

## Private Functions

The following Private Functions support the functions in this module:

- `Build-ADAuditTasksComputer`
- `Build-ADAuditTasksUser`
- `Initialize-DirectoryPath`
- `Build-MacIdOUIList`
- `Build-NetScanObject`
- `Build-ReportArchive`
- `Get-AdExtendedRight`
- `Get-ADGroupMemberof`
- `Initialize-ModuleEnv`
- `Install-ADModule`
- `Read-FileContent`
- `Test-IsAdmin`
- `Write-AuditLog`


### Example 1: Creating a zip file of various host types

The following example demonstrates how to create a zip file of different host types:

```powershell
$workstations   = Get-ADHostAudit -HostType WindowsWorkstations -Report
$servers        = Get-ADHostAudit -HostType WindowsServers -Report
$nonWindows     = Get-ADHostAudit -HostType "Non-Windows" -Report

Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows
```
### Example 2: Sending Email with **Attachment**

This example shows how to send an email with an attachment file generated by the `Get-ADActiveUserAudit` function using the `Send-AuditEmail` function.

```powershell
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -Pass (Read-Host -AsSecureString) -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -SSL
```
### Example 3: Sending Email with Attachment and Body
This example shows how to send an email with an attachment file generated by the Get-ADActiveUserAudit function, along with a body and a custom date stamp.

```powershell
$SMTPServer = "smtp.office365.com"
$Port       = 587
$UserName   = "helpdesk@constoso.com"
$From       = "helpdesk@constoso.com"
$To         = "user@anothercompany.com"
$password   = Read-Host -AsSecureString
$date       = (Get-Date).tostring("yyyy-MM-dd_hh.mm.ss")
$Body       = "Report run on $date for $env:USERDNSDOMAIN"


Send-AuditEmail -smtpServer $SMTPServer -port $Port -username $UserName `
-body $Body -from $From -to $To -pass $password -attachmentfiles "$(Get-ADActiveUserAudit -Report)" -ssl
```

### Example 4: Creating a ZIP file with parts

This example demonstrates how to create a ZIP file that could be split into multiple parts. 

```powershell
$workstations       = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
$servers            = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
$nonWindows         = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
$activeUsers        = Get-ADActiveUserAudit -Report -Verbose
$privilegedUsers    = Get-ADUserPrivilegeAudit -Report -Verbose
$wildcardUsers      = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers -MaxFileSize 100MB -OutputFolder "C:\Temp" -OpenDirectory
```
### Example 5: Creating a ZIP file with parts and emailing it

This example demonstrates how to create a ZIP file that could be split into multiple parts and emailed.

```powershell
# Function Variables
$workstations       = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
$servers            = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
$nonWindows         = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
$activeUsers        = Get-ADActiveUserAudit -Report -Verbose
$privilegedUsers    = Get-ADUserPrivilegeAudit -Report -Verbose
$wildcardUsers      = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose

# Email Variables
$SMTPServer     = "smtp.office365.com"
$Port           = 587
$UserName       = "helpdesk@constoso.com"
$From           = "helpdesk@constoso.com"
$To             = "user@anothercompany.com"
$password       = Read-Host -AsSecureString
$date           = (Get-Date).tostring("yyyy-MM-dd_hh.mm.ss")
$Body           = "Report run on $date for $env:USERDNSDOMAIN"
$attachments    = Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers


Send-AuditEmail -smtpServer $SMTPServer -port $Port -username $UserName `
-body $Body -from $From -to $To -pass $password -attachmentfiles $attachments -ssl
```

# ADAuditTasks Module

## Summary

- The module contains various Active Directory auditing tasks that generate logs, CSV output and report objects. 
Most reports can be sent via Send-AuditEmail by using them as the -AttachmentFiles parameter. 

## Help Documentation

See the [ADAuditTasks help documentation](https://criticalsolutionsnetwork.github.io/ADAuditTasks/) for more information on this module and how to use it.

## Public Functions
 The following Public Functions are available to the user executing the tasks: 
- `Get-ADActiveUserAudit`
- `Get-ADHostAudit`
- `Get-ADUserLogonAudit`
- `Get-ADUserPrivilegeAudit`
- `Get-ADUserWildCardAudit`
- `Get-HostTag`
- `Get-NetworkAudit`
- `Merge-ADAuditZip`
- `Send-AuditEmail`
- `Submit-FTPUpload`
### Example 1: Creating a zip file of various host types

The following example demonstrates how to create a zip file of different host types:

```powershell
$workstations = Get-ADHostAudit -HostType WindowsWorkstations
$servers = Get-ADHostAudit -HostType WindowsServers
$nonWindows = Get-ADHostAudit -HostType "Non-Windows"

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
$Port = 587
$UserName = "helpdesk@constoso.com"
$From = "helpdesk@constoso.com"
$To = "user@anothercompany.com"
$password = Read-Host -AsSecureString
$date = (Get-Date).tostring("yyyy-MM-dd_hh.mm.ss")
$Body = "Report run on $date for $env:USERDNSDOMAIN"


Send-AuditEmail -smtpServer $SMTPServer -port $Port -username $UserName `
-body $Body -from $From -to $To -pass $password -attachmentfiles "$(Get-ADActiveUserAudit -Report)" -ssl
```

### Example 4: Creating a ZIP file with parts

This example demonstrates how to create a ZIP file that will be split into multiple parts. 

```powershell
$workstations = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
$servers = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
$nonWindows = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
$activeUsers = Get-ADActiveUserAudit -Report -Verbose
$privilegedUsers = Get-ADUserPrivilegeAudit -Report -Verbose
$wildcardUsers = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers -MaxFileSize 100MB -OutputFolder "C:\Temp" -OpenDirectory
```
### Limitations:

- The module Get-NetworkAudit does not return a string output of the filename for usage in the Send-AuditEmail function. 
This will be added in a future update. 

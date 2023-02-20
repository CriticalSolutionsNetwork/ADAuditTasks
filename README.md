# ADAuditTasks Module

## Summary

- The module contains various Active Directory auditing tasks that generate logs, CSV output and report objects. 
Most reports can be sent via Send-AuditEmail by using them as the -AttachmentFiles parameter. 

### Example 1:
```powershell
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -Pass (Read-Host -AsSecureString) -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -SSL
```

### Example 2:
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

### Limitations:

- The module Get-NetworkAudit does not return a string output of the filename for usage in the Send-AuditEmail function. 
This will be added in a future update. 

### The following Public Functions are available to the user executing the tasks: 
```powershell
Get-ADActiveUserAudit
Get-ADHostAudit
Get-ADUserLogonAudit
Get-ADUserPrivilegeAudit
Get-ADUserWildCardAudit
Get-HostTag
Get-NetworkAudit
Send-AuditEmail
```
## Get-ADActiveUserAudit
### Synopsis
Gets active but stale AD User accounts that haven't logged in within the last 90 days by default.
### Syntax
```powershell

Get-ADActiveUserAudit [[-Enabled] <Boolean>] [[-DaysInactive] <Int32>] [[-AttachmentFolderPath] <String>] [[-Report]] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Enabled</nobr> |  | If "$false", will also search disabled users. | false | true \\(ByPropertyName\\) | True |
| <nobr>DaysInactive</nobr> |  | How far back in days to look for sign ins. Outside of this window, users are considered "Inactive" | false | true \\(ByPropertyName\\) | 90 |
| <nobr>AttachmentFolderPath</nobr> |  | Default path is C:\\temp\\ADActiveUserAudit. This is the folder where attachments are going to be saved. | false | true \\(ByValue\\) | C:\\temp\\ADActiveUserAudit |
| <nobr>Report</nobr> |  | Add report output as csv to DirPath directory. | false | true \\(ByPropertyName\\) | False |
### Outputs
 - ADAuditTasksUser

### Note
Outputs to C:\\temp\\ADActiveUserAudit by default. For help type: help Get-ADActiveUserAudit -ShowWindow

### Examples
**EXAMPLE 1**
```powershell
Get-ADActiveUserAudit
```


**EXAMPLE 2**
```powershell
Get-ADActiveUserAudit -Report -Verbose
```


**EXAMPLE 3**
```powershell
Get-ADActiveUserAudit -Enabled $false -DaysInactive 30 -AttachmentFolderPath "C:\temp\MyNewFolderName" -Report -Verbose
```


## Get-ADHostAudit
### Synopsis
Active Directory Server and Workstation Audit with Report export option \\(Can also be piped to CSV if Report isn't specified\\).
### Syntax
```powershell

Get-ADHostAudit [-HostType] <String> [[-DaystoConsiderAHostInactive] <Int32>] [[-Report]] [[-AttachmentFolderPath] <String>] [-Enabled <Boolean>] [<CommonParameters>]

Get-ADHostAudit [-OSType] <String> [[-DaystoConsiderAHostInactive] <Int32>] [[-Report]] [[-AttachmentFolderPath] <String>] [-Enabled <Boolean>] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>HostType</nobr> |  | Select from WindowsServers, WindowsWorkstations or Non-Windows. | true | true \\(ByValue\\) |  |
| <nobr>OSType</nobr> |  | Search an OS String. There is no need to add wildcards. | true | true \\(ByValue\\) |  |
| <nobr>DaystoConsiderAHostInactive</nobr> |  | How far back in days to look for sign ins. Outside of this window, hosts are considered "Inactive" | false | true \\(ByPropertyName\\) | 90 |
| <nobr>Report</nobr> |  | Add report output as csv to DirPath directory. | false | true \\(ByPropertyName\\) | False |
| <nobr>AttachmentFolderPath</nobr> |  | Default path is C:\\temp\\ADHostAudit. This is the folder where attachments are going to be saved. | false | false | C:\\temp\\ADHostAudit |
| <nobr>Enabled</nobr> |  | If "$false", will also search disabled computers. | false | true \\(ByPropertyName\\) | True |
### Outputs
 - System.Management.Automation.PSObject

### Note
Outputs to C:\\temp\\ADHostAudit by default. For help type: help Get-ADHostAudit -ShowWindow

### Examples
**EXAMPLE 1**
```powershell
Get-ADHostAudit -HostType WindowsServers -Report -Verbose
```


**EXAMPLE 2**
```powershell
Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
```


**EXAMPLE 3**
```powershell
Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
```


**EXAMPLE 4**
```powershell
Get-ADHostAudit -OSType "2008" -DirPath "C:\Temp\" -Report -Verbose
```


## Get-ADUserLogonAudit
### Synopsis
Takes SamAccountName as input to retrieve most recent LastLogon from all DC's and output as DateTime.
### Syntax
```powershell

Get-ADUserLogonAudit [-SamAccountName] <Object> [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>SamAccountName</nobr> | Identity, UserName, Account | The SamAccountName of the user being checked for LastLogon. | true | true \\(ByValue\\) |  |
### Outputs
 - System.DateTime

### Examples
**EXAMPLE 1**
```powershell
Get-ADUsersLastLogon -SamAccountName "UserName"
```


## Get-ADUserPrivilegeAudit
### Synopsis
Produces 3 object outputs: PrivilegedGroups, AdExtendedRights and possible service accounts.
### Syntax
```powershell

Get-ADUserPrivilegeAudit [[-AttachmentFolderPath] <String>] [[-Report]] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AttachmentFolderPath</nobr> |  | The path of the folder you want to save attachments to. The default is: C:\\temp\\ADUserPrivilegeAudit | false | true \\(ByValue\\) | C:\\temp\\ADUserPrivilegeAudit |
| <nobr>Report</nobr> |  | Add report output as csv to DirPath directory. | false | true \\(ByPropertyName\\) | False |
### Examples
**EXAMPLE 1**
```powershell
Get-ADUserPrivilegeAudit -Verbose
Get the reports as three separate objects.
To instantiate variables with the objects, provide 3 objects on the left side of the assignment:
For Example: $a,$b,$c = Get-ADUserPrivilegeAudit -verbose
The objects will be populated with PrivilegedGroups, AdExtendedRights and possible
service accounts respectively.
```


**EXAMPLE 2**
```powershell
Get-ADUserPrivilegeAudit -Report -Verbose
Will return 3 reports to the default temp directory in a single zip file.
```


## Get-ADUserWildCardAudit
### Synopsis
Takes a search string to find commonly named accounts.
### Syntax
```powershell

Get-ADUserWildCardAudit [[-Enabled] <Boolean>] [[-DaysInactive] <Int32>] -WildCardIdentifier <String> [[-AttachmentFolderPath] <String>] [[-Report]] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Enabled</nobr> |  | If "$false", will also search disabled users. | false | true \\(ByPropertyName\\) | True |
| <nobr>DaysInactive</nobr> |  | How far back in days to look for sign ins. Outside of this window, users are considered "Inactive" | false | true \\(ByPropertyName\\) | 90 |
| <nobr>WildCardIdentifier</nobr> |  | The search string to look for in the name of the account. Case does not matter. Do not add a wildcard \\(\\*\\) as it will do this automatically. | true | true \\(ByPropertyName\\) |  |
| <nobr>AttachmentFolderPath</nobr> |  | Default path is C:\\temp\\ADUserWildCardAudit. This is the folder where attachments are going to be saved. | false | true \\(ByValue\\) | C:\\temp\\ADUserWildCardAudit |
| <nobr>Report</nobr> |  | Add report output as csv to AttachmentFolderPath directory. | false | true \\(ByPropertyName\\) | False |
### Outputs
 - ADAuditTasksUser

### Examples
**EXAMPLE 1**
```powershell
Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
Searches for all user accounts that are named like the search string "svc".
```


## Get-HostTag
### Synopsis
Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.
### Syntax
```powershell

Get-HostTag [-PhysicalOrVirtual] <String> [-Prefix] <String> [-SystemOS] <String> [-DeviceFunction] <String> [[-HostCount] <Int32>] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>PhysicalOrVirtual</nobr> |  | Tab through selections to add 'P' or 'V' for physical or virtual to host tag. | true | true \\(ByPropertyName\\) |  |
| <nobr>Prefix</nobr> |  | Enter the 2-3 letter prefix. Good for prefixing company initials, locations, or other. | true | true \\(ByPropertyName\\) |  |
| <nobr>SystemOS</nobr> |  | Use tab to cycle through the following options: "Cisco ASA", "Android", "Apple IOS", "Dell Storage Center", "MACOSX", "Dell Power Edge", "Embedded", "Embedded Firmware", "Cisco IOS", "Linux", "Qualys", "Citrix ADC \\(Netscaler\\)", "Windows Thin Client", "VMWare", "Nutanix", "TrueNas", "FreeNas", "ProxMox", "Windows Workstation", "Windows Server", "Windows Server Core", "Generic OS", "Generic HyperVisor" | true | true \\(ByPropertyName\\) |  |
| <nobr>DeviceFunction</nobr> |  | Use tab to cycle through the following options: "Application Server", "Backup Server", "Directory Server", "Email Server", "Firewall", "FTP Server", "Hypervisor", "File Server", "NAS File Server", "Power Distribution Unit", "Redundant Power Supply", "SAN Appliance", "SQL Server", "Uninteruptable Power Supply", "Web Server", "Management", "Blade Enclosure", "Blade Enclosure Switch", "SAN specific switch", "General server/Network switch", "Generic Function Device" | true | true \\(ByPropertyName\\) |  |
| <nobr>HostCount</nobr> |  | Enter a number from 1 to 999 for how many hostnames you'd like to create. | false | true \\(ByPropertyName\\) | 1 |
### Outputs
 - System.String\\[\\]

### Examples
**EXAMPLE 1**
```powershell
Get-HostTag -PhysicalOrVirtual Physical -Prefix "CSN" -SystemOS 'Windows Server' -DeviceFunction 'Application Server' -HostCount 5
CSN-PWSVAPP001
CSN-PWSVAPP002
CSN-PWSVAPP003
CSN-PWSVAPP004
CSN-PWSVAPP005
This creates the name of the host under 15 characters and numbers them. Prefix can be 2-3 characters.
```


## Get-NetworkAudit
### Synopsis
Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.
### Syntax
```powershell

Get-NetworkAudit [[-Ports] <Int32[]>] [-LocalSubnets] [-Report] [<CommonParameters>]

Get-NetworkAudit [[-Ports] <Int32[]>] [-Computers] <String[]> [-Report] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>Ports</nobr> |  | Default ports are: "21", "22", "23", "25", "53", "67", "68", "80", "443", "88", "464", "123", "135", "137", "138", "139", "445", "389", "636", "514", "587", "1701", "3268", "3269", "3389", "5985", "5986"  If you want to supply a port, do so as an integer or an array of integers. "22","80","443", etc. | false | true \\(ByPropertyName\\) |  |
| <nobr>LocalSubnets</nobr> |  | Specify this switch to automatically scan subnets on the local network of the scanning device. Will not scan outside of the hosting device's subnet. | true | true \\(ByPropertyName\\) | False |
| <nobr>Computers</nobr> |  | Scan single host or array of hosts using Subet ID in CIDR Notation, IP, NETBIOS, or FQDN in "quotes"' For Example: "10.11.1.0/24","10.11.2.0/24" | true | true \\(ByPropertyName\\) |  |
| <nobr>Report</nobr> |  | Specify this switch if you would like a report generated in C:\\temp. | false | false | False |
### Outputs
 - System.Management.Automation.PSObject

### Note
Installs PSnmap if not found and can output a report, or just the results.

### Examples
**EXAMPLE 1**
```powershell
Get-NetworkAudit -report
```


### Links

 - [Specify a URI to a help page, this will show when Get-Help -Online is used.](#Specify a URI to a help page, this will show when Get-Help -Online is used.)
## Send-AuditEmail
### Synopsis
This is a wrapper function for Send-MailKitMessage and takes string arrays as input.
### Syntax
```powershell

Send-AuditEmail -AttachmentFiles <String[]> [-SMTPServer <String>] [-Port <Int32>] [-UserName <String>] [-SSL] [-From <String>] [-To <String>] [-Subject <String>] [-Body <String>] [-Pass <SecureString>] [<CommonParameters>]

Send-AuditEmail -AttachmentFiles <String[]> [-SMTPServer <String>] [-Port <Int32>] [-UserName <String>] [-SSL] [-From <String>] [-To <String>] [-Subject <String>] [-Body <String>] [-Function <String>] [-FunctionApp <String>] [-Token <String>] [<CommonParameters>]




```
### Parameters
| Name  | Alias  | Description | Required? | Pipeline Input | Default Value |
| - | - | - | - | - | - |
| <nobr>AttachmentFiles</nobr> |  | The full filepath to the zip you are sending: -AttachmentFiles "C:\\temp\\ADHostAudit\\2023-01-04\\_03.45.14\\_Get-ADHostAudit\\_AD.CONTOSO.COM.Servers.zip"  The Audit reports output this filename if the "-Report" switch is used allowing it to be nested in this parameter for ease of automation. | true | true \\(ByPropertyName\\) |  |
| <nobr>SMTPServer</nobr> |  | The SMTP Server address. For example: "smtp.office365.com" | false | false |  |
| <nobr>Port</nobr> |  | The following ports can be used to send email: "993", "995", "587", "25" | false | true \\(ByPropertyName\\) | 0 |
| <nobr>UserName</nobr> |  | The Account authorized to send email via SMTP. From parameter is usually the same. | false | false |  |
| <nobr>SSL</nobr> |  | Switch to ensure SSL is used during transport. | false | false | False |
| <nobr>From</nobr> |  | This is who the email will appear to originate from. This is either the same as the UserName, or, if delegated, access to an email account the Username account has delegated permissions to send for. Link: https://learn.microsoft.com/en-us/microsoft-365/admin/add-users/give-mailbox-permissions-to-another-user?view=o365-worldwide | false | false |  |
| <nobr>To</nobr> |  | This is the mailbox who will be the recipient of the communication. | false | false |  |
| <nobr>Subject</nobr> |  | The subject is automatically populated with the name of the function that ran the script, as well as the domain and hostname.  If you specify subject in the parameters, it will override the default with your subject. | false | false | "$\\($script:MyInvocation.MyCommand.Name -replace '\\..\\*'\\) report ran for $\\($env:USERDNSDOMAIN\\) on host $\\($env:COMPUTERNAME\\)." |
| <nobr>Body</nobr> |  | The body of the message, pre-populates with the same data as the subject line. Specify body text in the function parameters to override. | false | false | "$\\($script:MyInvocation.MyCommand.Name -replace '\\..\\*'\\) report ran for $\\($env:USERDNSDOMAIN\\) on host $\\($env:COMPUTERNAME\\)." |
| <nobr>Pass</nobr> |  | Takes a SecureString as input. The password must be added to the command by using: -Pass \\(Read-Host -AsSecureString\\) You will be promted to enter the password for the UserName parameter. | false | false |  |
| <nobr>Function</nobr> |  | If you are using the optional function feature and created a password retrieval function, this is the name of the function in Azure AD that accesses the vault. | false | false |  |
| <nobr>FunctionApp</nobr> |  | If you are using the optional function feature, this is the name of the function app in Azure AD. | false | false |  |
| <nobr>Token</nobr> |  | If you are using the optional function feature, this is the api token for the specific function. Ensure you are using the "Function Key" and NOT the "Host Key" to ensure access is only to the specific funtion. | false | false |  |
### Examples
**EXAMPLE 1**
```powershell
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -Pass (Read-Host -AsSecureString) -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -SSL
```
This will automatically send the report zip via email to the parameters specified.  
There is no cleanup of files. Please cleanup the directory of zip's if neccessary.

**EXAMPLE 2**
```powershell
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -FunctionApp "MyVaultFunctionApp" `
-Function "MyClientSpecificFunction" -Token "ABCDEF123456" -SSL
```
This will automatically send the report zip via email to the parameters specified.  
There is no cleanup of files. Please cleanup the directory of zip's if neccessary.


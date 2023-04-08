---
Module Name: ADAuditTasks
Module Guid: 6b72cdb3-2101-4a7e-b0d0-968a70018809
Download Help Link: {{ [ADAuditTasks](https://criticalsolutionsnetwork.github.io/ADAuditTasks/) }}
Help Version: {{ 0.0.1 }}
Locale: en-US
---

# ADAuditTasks Module
## Description
The ADAuditTasks module provides a set of cmdlets for auditing and reporting on Active Directory environments. It includes tools for user, host, and network audits, as well as utilities for working with Nmap, CSV, and other data formats.

## ADAuditTasks Cmdlets
### [Convert-NmapXMLToCSV](Convert-NmapXMLToCSV.md)
Converts an Nmap XML scan output file to a CSV file, extracting information about IP addresses, hostnames, open and closed ports, services, service versions, and operating systems.

### [Get-ADActiveUserAudit](Get-ADActiveUserAudit.md)
Retrieves active but stale AD user accounts that haven't logged in within the specified number of days (default 90 days). The cmdlet can output the results as a CSV report, and can also include disabled users if specified.

### [Get-ADHostAudit](Get-ADHostAudit.md)
Audits Active Directory server and workstation host objects based on input parameters. Generates a report, which can be exported as a CSV or manually piped. Filters by host type, OS type, and enables or disables host searching. Customizable search criteria and report generation supported.

### [Get-ADUserLogonAudit](Get-ADUserLogonAudit.md)
Retrieves the most recent LastLogon timestamp for a specified Active Directory user account from all domain controllers and outputs it as a DateTime object. Ensures domain controller availability before querying and generates an audit log of available and unavailable domain controllers.

### [Get-ADUserPrivilegeAudit](Get-ADUserPrivilegeAudit.md)
The Get-ADUserPrivilegeAudit PowerShell function generates three object outputs, detailing privileged groups, Active Directory (AD) extended rights, and potential service accounts. If the -Report switch is used, these reports are saved in a specified folder as a single zip file. The function requires the ActiveDirectory module and can be used in conjunction with other parameters such as AttachmentFolderPath and Report to customize the output directory and file format.

### [Get-ADUserWildCardAudit](Get-ADUserWildCardAudit.md)
Get-ADUserWildCardAudit is a PowerShell function that searches for Active Directory user accounts with names containing a specified string, considering their enabled status and activity within a set timeframe. It can generate an optional CSV report with the results, saved to a specified folder.

### [Get-HostTag](Get-HostTag.md)
Get-HostTag is a PowerShell function that generates custom hostnames or tags based on a combination of predefined criteria, such as physical or virtual status, prefix, system OS, and device function. It can create up to 999 hostnames at once, ensuring each name stays within a 15-character limit.

### [Get-NetworkAudit](Get-NetworkAudit.md)
This function discovers local networks and runs port scans on all hosts found for specific or default sets of ports. It displays MAC ID vendor information and can generate reports if the `-Report` switch is active. The function installs the PSnmap module if it's not found and can output a report or just the results. It supports a throttle limit for concurrent threads and can scan single hosts or an array of hosts using subnet ID in CIDR notation, IP, NETBIOS, or FQDN. The `-AddService` switch can be used to add the service typically associated with the port to the output.

### [Get-QuickPing](Get-QuickPing.md)
The Get-QuickPing function performs a rapid ping on a range of IP addresses and returns two arrays: one containing the IP addresses that responded to the ping, and the other containing the IP addresses that failed to respond. It accepts an IP range in various formats, such as a single IP address, a CIDR notation range, or an array of IP addresses. The Time-to-Live (TTL) value can be set to limit the ping to local networks, with a default value of 128.

### [Get-WebCertAudit](Get-WebCertAudit.md)
The Get-WebCertAudit function retrieves certificate information for a specified web server by establishing a TCP connection and using SSL to obtain the certificate details. It accepts the URL of the web server as input and returns a PowerShell custom object containing the certificate's subject, thumbprint, and expiration date.

### [Join-CSVFiles](Join-CSVFiles.md)
The Join-CSVFiles function merges multiple CSV files with the same headers into a single CSV file. It accepts an array of CSV file paths as input and saves the merged output to a specified folder. The function requires that all input CSV files have identical headers for proper merging.

### [Merge-ADAuditZip](Merge-ADAuditZip.md)
The Merge-ADAuditZip function combines multiple audit report files into a single compressed ZIP file. It accepts an array of file paths, a maximum file size for the output ZIP file, an output folder for the merged file, and an optional switch to open the directory of the merged file after creation. If the maximum file size is exceeded, the function will split the output file into multiple parts with incremental numbers added to the file names.

### [Merge-NmapToADHostAudit](Merge-NmapToADHostAudit.md)
This PowerShell function, Merge-NmapToADHostAudit, merges Nmap network audit data with Active Directory host audit data based on matching IP addresses and hostnames. It takes in two CSV files, one containing Nmap audit data and the other containing Active Directory host audit data. The merged data is then exported to a new CSV file, while any unmatched Nmap data is exported to a separate CSV file. This can be useful for consolidating and analyzing network and host information from both Nmap and Active Directory sources.

### [New-GraphEmailApp](New-GraphEmailApp.md)
New-GraphEmailApp is a PowerShell cmdlet that creates a new Microsoft Graph Email app and an associated certificate for app-only authentication. It requires a prefix ID, email address of the sender, and email address of the group the sender is a part of to assign app policy restrictions. The cmdlet connects to MSGraph and Exchange, creates the app registration, service principal, and app access policy in Exchange Online. Finally, it returns a pscustomobject containing the AppId, CertThumbprint, TenantID, CertExpires, SendAsUser, and AppRestrictedSendGroup, which can be used for app-only authentication later.

### [New-PatchTuesdayReport](New-PatchTuesdayReport.md)
New-PatchTuesdayReport is a PowerShell function that generates an HTML report file with the latest Microsoft updates released on Patch Tuesday. The report includes separate sections for client and server operating systems, and can be generated by following the steps provided in the description of the function. The function takes input parameters such as the path to the CSV input file, a string value used to identify the date of the Patch Tuesday report, the URL of the logo to be displayed in the report, and more. The output of the function is a string value containing the HTML code for the Patch Tuesday report.

### [Send-AuditEmail](Send-AuditEmail.md)
Send-AuditEmail is a PowerShell function that uses Send-MailKitMessage to send an email with attachments. It includes parameters for SMTP server, username, password, SSL, and attachment file paths. It can also retrieve credentials from an Azure Function App, allowing for secure automation of email sending. The subject and body of the email are automatically populated, but can be overridden with specified parameters.

### [Send-GraphAppEmail](Send-GraphAppEmail.md)
Send-GraphAppEmail is a PowerShell function that uses the Microsoft Graph API to send an email to a specified recipient. It requires a pre-created Microsoft Graph API app to send the email, and the app name can be passed in as a parameter. The function also allows for attaching files to the email. The Microsoft.Graph and MSAL.PS modules must be installed and imported to use this function.

### [Submit-FTPUpload](Submit-FTPUpload.md)
The Submit-FTPUpload function uses the WinSCP PowerShell module to upload a file to an FTP server. The function requires the FTP server name, the username and password of the account to use, the protocol to use, and the file to upload. It also allows the user to specify the level of security to use when connecting to the FTP server and the remote path to upload the file to on the FTP server.


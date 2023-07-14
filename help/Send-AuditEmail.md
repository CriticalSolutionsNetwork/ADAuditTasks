---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Send-AuditEmail
schema: 2.0.0
---

# Send-AuditEmail

## SYNOPSIS
This is a wrapper function for Send-MailKitMessage and takes string arrays as input.

## SYNTAX

### Pass (Default)
```
Send-AuditEmail -AttachmentFiles <String[]> [-SMTPServer <String>] [-Port <Int32>] [-UserName <String>] [-SSL]
 [-From <String>] [-To <String>] [-Subject <String>] [-Body <String>] [-Pass <SecureString>]
 [<CommonParameters>]
```

### Func
```
Send-AuditEmail -AttachmentFiles <String[]> [-SMTPServer <String>] [-Port <Int32>] [-UserName <String>] [-SSL]
 [-From <String>] [-To <String>] [-Subject <String>] [-Body <String>] -Function <String> -FunctionApp <String>
 -Token <String> -CertificateThumbprint <String> [<CommonParameters>]
```

## DESCRIPTION
Other Audit tasks can be used as the -AttachmentFiles parameter when used with the report switch.

## EXAMPLES

### EXAMPLE 1
```
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -Pass (Read-Host -AsSecureString) -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -SSL
```

This will automatically send the report zip via email to the parameters specified.
There is no cleanup of files.
Please cleanup the directory of zip's if neccessary.

### EXAMPLE 2
```
Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
-From "Username@contoso.com" -To "user@anothercompany.com" -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -FunctionApp "MyVaultFunctionApp" `
-Function "MyClientSpecificFunction" -Token "ABCDEF123456" -SSL
```

This will automatically send the report zip via email to the parameters specified.
There is no cleanup of files.
Please cleanup the directory of zip's if neccessary.

## PARAMETERS

### -AttachmentFiles
The full filepath to the zip you are sending:
    -AttachmentFiles "C:\temp\ADHostAudit\2023-01-04_03.45.14_Get-ADHostAudit_AD.CONTOSO.COM.Servers.zip"

The Audit reports output this filename if the "-Report" switch is used allowing it to be nested in this parameter
for ease of automation.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Body
The body of the message, pre-populates with the same data as the subject line.
Specify body text
in the function parameters to override.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "$($script:MyInvocation.MyCommand.Name -replace '\..*') report ran for $($env:USERDNSDOMAIN) on host $($env:COMPUTERNAME)."
Accept pipeline input: False
Accept wildcard characters: False
```

### -CertificateThumbprint
API key for the Azure Function App

```yaml
Type: String
Parameter Sets: Func
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From
This is who the email will appear to originate from.
This is either the same as the UserName,
or, if delegated, access to an email account the Username account has delegated permissions to send for.
Link:
    https://learn.microsoft.com/en-us/microsoft-365/admin/add-users/give-mailbox-permissions-to-another-user?view=o365-worldwide

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Function
If you are using the optional function feature and created a password retrieval function,
this is the name of the function in Azure AD that accesses the vault.

```yaml
Type: String
Parameter Sets: Func
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FunctionApp
If you are using the optional function feature, this is the name of the function app in Azure AD.

```yaml
Type: String
Parameter Sets: Func
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Pass
Takes a SecureString as input.
The password must be added to the command by using:
    -Pass (Read-Host -AsSecureString)
    You will be promted to enter the password for the UserName parameter.

```yaml
Type: SecureString
Parameter Sets: Pass
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Port
The following ports can be used to send email:
    "993", "995", "587", "25"

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SMTPServer
The SMTP Server address.
For example: "smtp.office365.com"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SSL
Switch to ensure SSL is used during transport.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
The subject is automatically populated with the name of the function that ran the script,
as well as the domain and hostname.

If you specify subject in the parameters, it will override the default with your subject.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: "$($script:MyInvocation.MyCommand.Name -replace '\..*') report ran for $($env:USERDNSDOMAIN) on host $($env:COMPUTERNAME)."
Accept pipeline input: False
Accept wildcard characters: False
```

### -To
This is the mailbox who will be the recipient of the communication.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Token
If you are using the optional function feature, this is the api token for the specific function.
Ensure you are using the "Function Key" and NOT the "Host Key" to ensure access is only to the specific funtion.

```yaml
Type: String
Parameter Sets: Func
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserName
The Account authorized to send email via SMTP.
From parameter is usually the same.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Send-AuditEmail](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Send-AuditEmail)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Send-AuditEmail](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Send-AuditEmail)


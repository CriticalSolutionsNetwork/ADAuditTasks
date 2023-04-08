---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/tree/main/help/Send-GraphAppEmail.md
schema: 2.0.0
---

# Send-GraphAppEmail

## SYNOPSIS
Sends an email using the Microsoft Graph API.

## SYNTAX

```
Send-GraphAppEmail [[-AppName] <String>] [-To] <String> [-FromAddress] <String> [-Subject] <String>
 [-EmailBody] <String> [[-AttachmentPath] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The Send-GraphAppEmail function uses the Microsoft Graph API to send an email to a specified recipient.
The function requires the Microsoft Graph API to be set up and requires a pre-created Microsoft Graph API
app to send the email.
The AppName can be passed in as a parameter and the function will retrieve the
associated authentication details from the Credential Manager.

## EXAMPLES

### EXAMPLE 1
```
Send-GraphAppEmail -AppName "GraphEmailApp" -To "recipient@example.com" -FromAddress "sender@example.com" -Subject "Test Email" -EmailBody "This is a test email."
```

## PARAMETERS

### -AppName
The pre-created Microsoft Graph API app name used to send the email.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -To
The email address of the recipient.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FromAddress
The email address of the sender who is a member of the Security Enabled Group allowed to send email
that was configured using the New-GraphEmailApp.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
The subject line of the email.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EmailBody
The body text of the email.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AttachmentPath
An array of file paths for any attachments to include in the email.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
The function requires the Microsoft.Graph and MSAL.PS modules to be installed and imported.

## RELATED LINKS

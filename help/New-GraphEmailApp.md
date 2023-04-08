---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/New-GraphEmailApp
schema: 2.0.0
---

# New-GraphEmailApp

## SYNOPSIS
Creates a new Microsoft Graph Email app and associated certificate for app-only authentication.

## SYNTAX

```
New-GraphEmailApp [-Prefix] <String> [-UserId] <String> [-MailEnabledSendingGroup] <String>
 [[-CertThumbprint] <String>] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet creates a new Microsoft Graph Email app and associated certificate for app-only authentication.
It requires a 2 to 4 character long prefix ID for the app, files and certs that are created, as well as the
email address of the sender and the email of the Group the sender is a part of to assign app policy restrictions.

## EXAMPLES

### EXAMPLE 1
```
New-GraphEmailApp -Prefix ABC -UserId jdoe@example.com -MailEnabledSendingGroup "Example Mail Group" -CertThumbprint "9B8B40C5F148B710AD5C0E5CC8D0B71B5A30DB0C"
```

## PARAMETERS

### -Prefix
The 2 to 4 character long prefix ID of the app, files and certs that are created.
Meant to group multiple runs
so that if run in different environments, they will stack naturally in Azure.
Ensure you use the same prefix each
time if you'd like this behavior.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserId
The email address of the sender.

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

### -MailEnabledSendingGroup
The email of the Group the sender is a member of to assign app policy restrictions.
For Example: IT-AuditEmailGroup@contoso.com
You can create the group using the admin center at https://admin.microsoft.com or you can create it
using the following commands as an example.
    # Import the ExchangeOnlineManagement module
    Import-Module ExchangeOnlineManagement

    # Create a new mail-enabled security group
    New-DistributionGroup -Name "My Group" -Members "user1@contoso.com", "user2@contoso.com" -MemberDepartRestriction Closed

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

### -CertThumbprint
The thumbprint of the certificate to use.
If not specified, a self-signed certificate will be generated.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Returns a pscustomobject containing the AppId, CertThumbprint, TenantID, and CertExpires.
## NOTES
This cmdlet requires that the user running the cmdlet have the necessary permissions
to create the app and connect to Exchange Online.
In addition, a mail-enabled security
group must already exist in Exchange Online for the MailEnabledSendingGroup parameter.

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/New-GraphEmailApp](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/New-GraphEmailApp)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#New-GraphEmailApp](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#New-GraphEmailApp)


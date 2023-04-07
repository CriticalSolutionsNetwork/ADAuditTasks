---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version:
schema: 2.0.0
---

# Get-ADUserWildCardAudit

## SYNOPSIS
Takes a search string to find commonly named accounts.

## SYNTAX

```
Get-ADUserWildCardAudit [[-Enabled] <Boolean>] [[-DaysInactive] <Int32>] -WildCardIdentifier <String>
 [[-AttachmentFolderPath] <String>] [-Report] [<CommonParameters>]
```

## DESCRIPTION
Takes a search string to find commonly named accounts.
For example:
    If you commonly name service accounts with the prefix "svc",
    Use "svc" for the WildCardIdentifier to search for names that contain "svc"

## EXAMPLES

### EXAMPLE 1
```
Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
Searches for all user accounts that are named like the search string "svc".
```

## PARAMETERS

### -Enabled
If "$false", will also search disabled users.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: True
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DaysInactive
How far back in days to look for sign ins.
Outside of this window, users are considered "Inactive"

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 90
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WildCardIdentifier
The search string to look for in the name of the account.
Case does not matter.
Do not add a wildcard (*) as it will do this automatically.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AttachmentFolderPath
Default path is C:\temp\ADUserWildCardAudit.
This is the folder where attachments are going to be saved.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: C:\temp\ADUserWildCardAudit
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Report
Add report output as csv to AttachmentFolderPath directory.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### ADAuditTasksUser
## NOTES

## RELATED LINKS

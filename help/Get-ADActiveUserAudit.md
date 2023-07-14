---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADActiveUserAudit
schema: 2.0.0
---

# Get-ADActiveUserAudit

## SYNOPSIS
Gets active but stale AD User accounts that haven't logged in within the last 90 days by default.

## SYNTAX

```
Get-ADActiveUserAudit [[-Enabled] <Boolean>] [[-DaysInactive] <Int32>] [[-AttachmentFolderPath] <String>]
 [-Report] [<CommonParameters>]
```

## DESCRIPTION
Audit's Active Directory taking "days" as the input for how far back to check for a user's last sign in.
Output can be piped to a csv manually, or automatically to C:\temp\ADActiveUserAudit or a specified path
in "AttachmentFolderPath" using the -Report Switch.

Any user account that is enabled and not signed in over 90 days is a candidate for removal.

## EXAMPLES

### EXAMPLE 1
```
Get-ADActiveUserAudit
```

### EXAMPLE 2
```
Get-ADActiveUserAudit -Report -Verbose
```

### EXAMPLE 3
```
Get-ADActiveUserAudit -Enabled $false -DaysInactive 30 -AttachmentFolderPath "C:\temp\MyNewFolderName" -Report -Verbose
```

## PARAMETERS

### -AttachmentFolderPath
Default path is C:\temp\ADActiveUserAudit.
This is the folder where attachments are going to be saved.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: C:\temp\ADActiveUserAudit
Accept pipeline input: True (ByValue)
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

### -Report
Add report output as csv to DirPath directory.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
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
Outputs to C:\temp\ADActiveUserAudit by default.
For help type: help Get-ADActiveUserAudit -ShowWindow

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADActiveUserAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADActiveUserAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADActiveUserAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADActiveUserAudit)


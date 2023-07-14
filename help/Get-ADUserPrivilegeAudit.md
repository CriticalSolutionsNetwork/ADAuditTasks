---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserPrivilegeAudit
schema: 2.0.0
---

# Get-ADUserPrivilegeAudit

## SYNOPSIS
Produces three object outputs: PrivilegedGroups, AdExtendedRights, and possible service accounts.

## SYNTAX

```
Get-ADUserPrivilegeAudit [[-AttachmentFolderPath] <String>] [-Report] [<CommonParameters>]
```

## DESCRIPTION
The Get-ADUserPrivilegeAudit function produces reports on privileged groups, AD extended rights, and possible service accounts.
If the -Report switch is used, the reports will be created in the specified folder.
To instantiate variables with the objects, provide three objects on the left side of the assignment:

Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose

The objects will be populated with privileged groups, AD extended rights, and possible service accounts, respectively.

## EXAMPLES

### EXAMPLE 1
```
Get-ADUserPrivilegeAudit -Verbose
Gets the reports as three separate objects. To instantiate variables with the objects, provide three objects on the left side of the assignment:
Example: $a,$b,$c = Get-ADUserPrivilegeAudit -Verbose
The objects will be populated with privileged groups, AD extended rights, and possible service accounts, respectively.
```

### EXAMPLE 2
```
Get-ADUserPrivilegeAudit -Report -Verbose
Returns three reports to the default folder, C:\temp\ADUserPrivilegeAudit, in a single zip file.
```

## PARAMETERS

### -AttachmentFolderPath
Specifies the path of the folder where you want to save attachments.
The default path is C:\temp\ADUserPrivilegeAudit.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: C:\temp\ADUserPrivilegeAudit
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Report
Adds report output as CSV to the directory specified by AttachmentFolderPath.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject[]
### System.String
### System.Object[]
## NOTES
This function requires the ActiveDirectory module.

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserPrivilegeAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserPrivilegeAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADUserPrivilegeAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADUserPrivilegeAudit)


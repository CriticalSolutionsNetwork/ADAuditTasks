---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADHostAudit
schema: 2.0.0
---

# Get-ADHostAudit

## SYNOPSIS
Active Directory Server and Workstation Audit with Report export option (Can also be piped to CSV if Report isn't specified).

## SYNTAX

### HostType (Default)
```
Get-ADHostAudit [-HostType] <String> [[-DaystoConsiderAHostInactive] <Int32>] [-Report]
 [[-AttachmentFolderPath] <String>] [-Enabled <Boolean>] [<CommonParameters>]
```

### OSType
```
Get-ADHostAudit [-OSType] <String> [[-DaystoConsiderAHostInactive] <Int32>] [-Report]
 [[-AttachmentFolderPath] <String>] [-Enabled <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Audits Active Directory for hosts that haven't signed in for a specified number of days.
Output can be piped to a CSV manually, or automatically saved to C:\temp\ADHostAudit or a specified directory using the -Report switch.

Use the Tab key to cycle through the -HostType parameter.

## EXAMPLES

### EXAMPLE 1
```
Get-ADHostAudit -HostType WindowsServers -Report -Verbose
```

### EXAMPLE 2
```
Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
```

### EXAMPLE 3
```
Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
```

### EXAMPLE 4
```
Get-ADHostAudit -OSType "2008" -DirPath "C:\Temp\" -Report -Verbose
```

## PARAMETERS

### -AttachmentFolderPath
Specifies the directory where attachments will be saved.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: C:\temp\ADHostAudit
Accept pipeline input: False
Accept wildcard characters: False
```

### -DaystoConsiderAHostInactive
Specifies the number of days to consider a host as inactive.

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
If set to $false, the function will also search for disabled computers.

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HostType
Specifies the type of hosts to search for.
Valid values are WindowsServers, WindowsWorkstations, and Non-Windows.

```yaml
Type: String
Parameter Sets: HostType
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -OSType
Specifies the operating system to search for.
There is no need to add wildcards.

```yaml
Type: String
Parameter Sets: OSType
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Report
Saves a CSV report to the specified directory.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES
By default, output is saved to C:\temp\ADHostAudit.
For more information, type: Get-Help Get-ADHostAudit -ShowWindow

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADHostAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADHostAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADHostAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADHostAudit)


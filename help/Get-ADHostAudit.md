---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/tree/main/help/Get-ADHostAudit.md
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
Audit's Active Directory taking "days" as the input for how far back to check for a device's last sign in.
Output can be piped to a csv manually, or automatically to C:\temp\ADHostAudit or a specified path in
"AttachmentFolderPath" using the -Report Switch.

Use the Tab key to cycle through the -HostType Parameter.

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

### -HostType
Select from WindowsServers, WindowsWorkstations or Non-Windows.

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
Search an OS String.
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

### -DaystoConsiderAHostInactive
How far back in days to look for sign ins.
Outside of this window, hosts are considered "Inactive"

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

### -Report
Add report output as csv to DirPath directory.

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

### -AttachmentFolderPath
Default path is C:\temp\ADHostAudit.
This is the folder where attachments are going to be saved.

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

### -Enabled
If "$false", will also search disabled computers.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES
Outputs to C:\temp\ADHostAudit by default.
For help type: help Get-ADHostAudit -ShowWindow

## RELATED LINKS

---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/tree/main/help/Merge-ADAuditZip.md
schema: 2.0.0
---

# Merge-ADAuditZip

## SYNOPSIS
Combines multiple audit report files into a single compressed ZIP file.

## SYNTAX

```
Merge-ADAuditZip [[-FilePaths] <String[]>] [[-MaxFileSize] <Int32>] [[-OutputFolder] <String>] [-OpenDirectory]
 [<CommonParameters>]
```

## DESCRIPTION
The Merge-ADAuditZip function combines multiple audit report files into a single
compressed ZIP file.
The function takes an array of file paths, a maximum file
size for the output ZIP file, an output folder for the merged file, and an optional
switch to open the directory of the merged file after creation.

## EXAMPLES

### EXAMPLE 1
```
$workstations = Get-ADHostAudit -HostType WindowsWorkstations -Report
$servers = Get-ADHostAudit -HostType WindowsServers -Report
$nonWindows = Get-ADHostAudit -HostType "Non-Windows" -Report
Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows
```

This example combines three audit reports for Windows workstations, Windows servers,
and non-Windows hosts into a single compressed ZIP file.

### EXAMPLE 2
```
Merge-ADAuditZip -FilePaths C:\AuditReports\Report1.csv,C:\AuditReports\Report2.csv -MaxFileSize 50MB -OutputFolder C:\MergedReports -OpenDirectory
```

This example merges two audit reports into a single compressed ZIP file with a maximum file size of 50 MB, an output folder of C:\MergedReports,
and opens the directory of the merged compressed ZIP file after creation.

## PARAMETERS

### -FilePaths
Specifies an array of file paths to be merged into a single compressed ZIP file.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxFileSize
Specifies the maximum file size (in bytes) for the output ZIP file.
The default
value is 24 MB.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 25165824
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFolder
Specifies the output folder for the merged compressed ZIP file.
The default folder
is C:\temp.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: C:\temp
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpenDirectory
Specifies an optional switch to open the directory of the merged compressed ZIP
file after creation.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
This function will split the output file into multiple parts if the maximum
file size is exceeded.
If the size exceeds the limit, a new ZIP file will be
created with an incremental number added to the file name.

This function may or may not work with various types of input.

## RELATED LINKS

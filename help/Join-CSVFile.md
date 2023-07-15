---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Join-CSVFiles
schema: 2.0.0
---

# Join-CSVFile

## SYNOPSIS
Joins multiple CSV files with the same headers into a single CSV file.

## SYNTAX

```
Join-CSVFile [-CSVFilePaths] <String[]> [[-AttachmentFolderPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Join-CSVFiles function takes an array of CSV file paths, reads their
contents, and merges them into a single CSV file.
The output file is saved
to the specified folder.
All input CSV files must have the same headers
for the function to work correctly.

## EXAMPLES

### EXAMPLE 1
```
Join-CSVFiles -CSVFilePaths @("C:\path\to\csv1.csv", "C:\path\to\csv2.csv") -AttachmentFolderPath "C:\path\to\output.csv"
```

This example will merge the contents of "C:\path\to\csv1.csv" and
"C:\path\to\csv2.csv" into a single CSV file and save it in "C:\path\to\output.csv".

## PARAMETERS

### -AttachmentFolderPath
The output folder path where the merged CSV file will be saved.
Default location is "C:\temp\MergedCSV".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: C:\temp\MergedCSV
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -CSVFilePaths
An array of strings containing the file paths of the CSV files to be merged.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### None. The function outputs a merged CSV file to the specified folder.
## NOTES
Make sure the input CSV files have the same headers and formatting for the function to work properly.

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Join-CSVFiles](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Join-CSVFiles)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Join-CSVFiles](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Join-CSVFiles)


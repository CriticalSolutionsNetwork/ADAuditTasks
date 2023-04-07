---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version:
schema: 2.0.0
---

# Merge-NmapToADHostAudit

## SYNOPSIS
Merges Nmap network audit data with Active Directory host audit data.

## SYNTAX

```
Merge-NmapToADHostAudit -ADAuditCsv <String> -NmapCsv <String> [[-AttachmentFolderPath] <String>]
 [<CommonParameters>]
```

## DESCRIPTION
The Merge-NmapToADHostAudit function takes in two CSV files, one containing Nmap network
audit data and the other containing Active Directory host audit data.
It merges the data
based on matching IP addresses and hostnames, and exports the merged data to a new CSV file.
Additionally, it exports any unmatched Nmap data to a separate CSV file.

## EXAMPLES

### EXAMPLE 1
```
Merge-NmapToADHostAudit -ADAuditCsv "C:\path\to\ADAudit.csv" -NmapCsv "C:\path\to\NmapAudit.csv" -AttachmentFolderPath "C:\path\to\output"
```

This example will merge the Active Directory host audit data in "C:\path\to\ADAudit.csv"
with the Nmap network audit data in "C:\path\to\NmapAudit.csv" and save the merged data
to a new CSV file in "C:\path\to\output".
Unmatched Nmap data will also be saved to a
separate CSV file in the same output folder.

## PARAMETERS

### -ADAuditCsv
The path to the Active Directory host audit CSV file.

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

### -NmapCsv
The path to the Nmap network audit CSV file.

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
The output folder path where the merged CSV file and unmatched Nmap data CSV file will
be saved.
Default location is "C:\temp\NmapToADHostAudit".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: C:\temp\NmapToADHostAudit
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Make sure the input CSV files have the correct headers and formatting for the function to work properly.

## RELATED LINKS

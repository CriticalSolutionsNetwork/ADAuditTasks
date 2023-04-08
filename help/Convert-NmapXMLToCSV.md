---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Convert-NmapXMLToCSV
schema: 2.0.0
---

# Convert-NmapXMLToCSV

## SYNOPSIS
Converts an Nmap XML scan output file to a CSV file.

## SYNTAX

```
Convert-NmapXMLToCSV [-InputXml] <String> [[-AttachmentFolderPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Convert-NmapXMLToCSV function takes an Nmap XML scan output
file as input and converts it into a CSV file.
The function
extracts information about IP addresses, hostnames, open and
closed ports, services, service versions, and operating systems.
The output CSV file is saved to the specified folder or to
C:\temp\NmapXMLToCSV by default.

## EXAMPLES

### EXAMPLE 1
```
Convert-NmapXMLToCSV -InputXml "C:\path\to\nmap.xml" -AttachmentFolderPath "C:\path\to\output"
This example will convert the contents of "C:\path\to\nmap.xml" into a CSV file and save it in "C:\path\to\output".
```

## PARAMETERS

### -InputXml
A string containing the full path to the Nmap XML file that needs to be converted.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AttachmentFolderPath
The output folder path where the converted CSV file will be saved.
Default location is "C:\temp\NmapXMLToCSV".

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: C:\temp\NmapXMLToCSV
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Make sure the input Nmap XML file is properly formatted and contains the necessary
information for the conversion to work correctly.

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Convert-NmapXMLToCSV](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Convert-NmapXMLToCSV)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Convert-NmapXMLToCSV](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Convert-NmapXMLToCSV)


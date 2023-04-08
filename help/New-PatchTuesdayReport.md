---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/tree/main/help/New-PatchTuesdayReport.md
schema: 2.0.0
---

# New-PatchTuesdayReport

## SYNOPSIS
Generates a Patch Tuesday report HTML file based on a CSV input file.

## SYNTAX

```
New-PatchTuesdayReport [[-CsvPath] <String>] [[-DateId] <String>] [[-LogoUrl] <String>]
 [[-ImportHeaderAs] <String[]>] [[-OSList] <String[]>] [<CommonParameters>]
```

## DESCRIPTION
The function generates an HTML report file with the latest Microsoft updates released on Patch Tuesday.
The report file includes separate sections for client and server operating systems.

To use this function, follow these steps:

Go to the Microsoft Security Response Center website at https://msrc.microsoft.com/update-guide.
Select the appropriate filters to display the updates you want to include in the report.
For example, select the following options:
    Product:
    Windows Server 2022, Windows Server 2019, Windows Server 2016, Windows Server 2012 R2, Windows 11 Version 22H2 for x64-based Systems, Windows 10 Version 22H2 for x64-based Systems.
    Severity: Critical
    Release Date: Last 30 days
Click on "Download all as CSV" to download the updates as a CSV file.
The function will import the CSV file with the appropriate headers:
    Import-Csv -Path $Path -Header 'Release Date','Product','Platform','Impact','Max Severity','Article','ArticleUrl','Download','Download Url','Build Number','Details','Details Url','Base Score'
Use the New-PatchTuesdayReport function to generate the HTML report file.
Future updates will include options to specify the parameters.

## EXAMPLES

### EXAMPLE 1
```
New-PatchTuesdayReport -CsvPath "C:\updates.csv" -DateId "2022-Oct" -LogoUrl "https://example.com/logo.png" -OSList @("Windows Server 2012 R2", "Windows Server 2016", "Windows Server 2019", "Windows Server 2022", "Windows 11", "Windows 10")
```

This example generates a Patch Tuesday report for October 2022 with updates for Windows Server 2012 R2, Windows Server 2016, Windows Server 2019, Windows Server 2022, Windows 11, and Windows 10 operating systems.
The report includes a logo displayed at the top of the report.

## PARAMETERS

### -CsvPath
The path to the CSV input file containing the Microsoft update information.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DateId
A string value used to identify the date of the Patch Tuesday report.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogoUrl
A string value representing the URL of the logo to be displayed in the report.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ImportHeaderAs
An array of strings representing the header row of the CSV input file.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: @("Release Date", "Product", "Platform", "Impact", "Max Severity", "Article", "ArticleUrl", "Download", "Download Url", "Build Number", "Details", "Details Url", "Base Score")
Accept pipeline input: False
Accept wildcard characters: False
```

### -OSList
An array of strings representing the list of operating systems to include in the report.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: @('Windows Server 2012 R2', 'Windows Server 2016', 'Windows Server 2019', 'Windows Server 2022', 'Windows 11', 'Windows 10')
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None.
## OUTPUTS

### A string value containing the HTML code for the Patch Tuesday report.
## NOTES
None.

## RELATED LINKS

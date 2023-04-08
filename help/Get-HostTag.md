---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-HostTag
schema: 2.0.0
---

# Get-HostTag

## SYNOPSIS
Creates a host name or tag based on predetermined criteria for as many as 999 hosts at a time.

## SYNTAX

```
Get-HostTag [-PhysicalOrVirtual] <String> [-Prefix] <String> [-SystemOS] <String> [-DeviceFunction] <String>
 [[-HostCount] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
A longer description of the function, its purpose, common use cases, etc.

## EXAMPLES

### EXAMPLE 1
```
Get-HostTag -PhysicalOrVirtual Physical -Prefix "CSN" -SystemOS 'Windows Server' -DeviceFunction 'Application Server' -HostCount 5
    CSN-PWSVAPP001
    CSN-PWSVAPP002
    CSN-PWSVAPP003
    CSN-PWSVAPP004
    CSN-PWSVAPP005
```

This creates the name of the host under 15 characters and numbers them.
Prefix can be 2-3 characters.

## PARAMETERS

### -PhysicalOrVirtual
Tab through selections to add 'P' or 'V' for physical or virtual to host tag.

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

### -Prefix
Enter the 2-3 letter prefix.
Good for prefixing company initials, locations, or other.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SystemOS
Use tab to cycle through the following options:
    "Cisco ASA", "Android", "Apple IOS",
    "Dell Storage Center", "MACOSX",
    "Dell Power Edge", "Embedded", "Embedded Firmware",
    "Cisco IOS", "Linux", "Qualys", "Citrix ADC (Netscaler)",
    "Windows Thin Client", "VMWare",
    "Nutanix", "TrueNas", "FreeNas",
    "ProxMox", "Windows Workstation", "Windows Server",
    "Windows Server Core", "Generic OS", "Generic HyperVisor"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -DeviceFunction
Use tab to cycle through the following options:
    "Application Server", "Backup Server", "Directory Server",
    "Email Server", "Firewall", "FTP Server",
    "Hypervisor", "File Server", "NAS File Server",
    "Power Distribution Unit", "Redundant Power Supply", "SAN Appliance",
    "SQL Server", "Uninteruptable Power Supply", "Web Server",
    "Management", "Blade Enclosure", "Blade Enclosure Switch",
    "SAN specific switch", "General server/Network switch", "Generic Function Device"

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -HostCount
Enter a number from 1 to 999 for how many hostnames you'd like to create.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: 1
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.String[]
## NOTES
Additional information about the function, usage tips, etc.

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-HostTag](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-HostTag)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-HostTag](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-HostTag)


---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit
schema: 2.0.0
---

# Get-NetworkAudit

## SYNOPSIS
Discovers local network and runs port scans on all hosts found for specific or default sets of ports and displays MAC ID vendor info.

## SYNTAX

### Default (Default)
```
Get-NetworkAudit [[-Ports] <Int32[]>] [-LocalSubnets] [[-ThrottleLimit] <Int32>] [-NoHops] [-AddService]
 [-Report] [-ScanOnPingFail] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### Computers
```
Get-NetworkAudit [[-Ports] <Int32[]>] [-Computers] <String[]> [[-ThrottleLimit] <Int32>] [-NoHops]
 [-AddService] [-Report] [-ScanOnPingFail] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Scans the network for open ports specified by the user or default ports if no ports are specified.
Creates reports if report switch is active.
Adds MACID vendor info if found.

## EXAMPLES

### EXAMPLE 1
```
Get-NetworkAudit -report
```

## PARAMETERS

### -Ports
Default ports are:
"21", "22", "23", "25", "53", "67", "68", "80", "443",
"88", "464", "123", "135", "137", "138", "139",
"445", "389", "636", "514", "587", "1701",
"3268", "3269", "3389", "5985", "5986"

If you want to supply a port, do so as an integer or an array of integers.
"22","80","443", etc.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -LocalSubnets
Specify this switch to automatically scan subnets on the local network of the scanning device.
Will not scan outside of the hosting device's subnet.

```yaml
Type: SwitchParameter
Parameter Sets: Default
Aliases:

Required: True
Position: 2
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Computers
Scan single host or array of hosts using Subet ID in CIDR Notation, IP, NETBIOS, or FQDN in "quotes"'
For Example:
    "10.11.1.0/24","10.11.2.0/24"

```yaml
Type: String[]
Parameter Sets: Computers
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ThrottleLimit
Number of concurrent threads.
Default: 32.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 32
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -NoHops
Don't allow scans across a gateway.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -AddService
Add the service typically associated with the port to the output.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Report
Specify this switch if you would like a report generated in C:\temp.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ScanOnPingFail
Scan all hosts even if ping fails.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES
Installs PSnmap if not found and can output a report, or just the results.

Throttle Limit Notes:
    Number of hosts: 65,536
    Scan rate: 32 hosts per second (Throttle limit)
    Total scan time: 2,048 seconds (65,536 / 32 = 2,048)
    Total data transferred: 65,536 kilobytes (1 kilobyte per host)
    Average network bandwidth: 32 kilobits per second (65,536 kilobytes / 2,048 seconds = 32 kilobits per second)

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-NetworkAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-NetworkAudit)


---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit
schema: 2.0.0
---

# Get-NetworkAudit

## SYNOPSIS
Discovers the local network and runs port scans on all hosts found for specific or default sets of ports, displaying MAC ID vendor info.

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
Creates reports if the report switch is active and adds MAC ID vendor info if found.

NOTES:
- This function requires the PSnmap module.
If not found, it will be installed automatically.
- The throttle limit determines the number of concurrent threads during scanning.
- The scan rate is limited to 32 hosts per second to ensure network stability.
- The total scan time and data transferred depend on the number of hosts.
- The average network bandwidth is approximately 32 kilobits per second.

## EXAMPLES

### EXAMPLE 1
```
Get-NetworkAudit -Report
Generates a report of the network audit results in the C:\temp folder.
```

## PARAMETERS

### -AddService
Includes the service name associated with each port in the output.

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

### -Computers
Scans a single host or an array of hosts using subnet ID in CIDR notation, IP address, NETBIOS name, or FQDN in double quotes.
Example: "10.11.1.0/24", "10.11.2.0/24"

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

### -LocalSubnets
Scans subnets connected to the local device.
It will not scan outside of the hosting device's subnet.

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

### -NoHops
Prevents scans across a gateway.

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

### -Ports
Specifies the ports to scan.
If not provided, the function uses default ports:
"21", "22", "23", "25", "53", "67", "68", "80", "443",
"88", "464", "123", "135", "137", "138", "139",
"445", "389", "636", "514", "587", "1701",
"3268", "3269", "3389", "5985", "5986"

To specify ports, provide an integer or an array of integers.
Example: "22", "80", "443"

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

### -Report
Generates a report in the C:\temp folder if specified.

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
Scans a host even if ping fails.

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

### -ThrottleLimit
Specifies the number of concurrent threads.
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Management.Automation.PSObject
## NOTES

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-NetworkAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-NetworkAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-NetworkAudit)


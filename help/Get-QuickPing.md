---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version:
schema: 2.0.0
---

# Get-QuickPing

## SYNOPSIS
Performs a quick ping on a range of IP addresses and returns an array of IP addresses
that responded to the ping and an array of IP addresses that failed to respond.

## SYNTAX

```
Get-QuickPing [[-IPRange] <Object>] [[-TTL] <Int32>] [[-BufferSize] <Int32>] [[-Count] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
This function performs a quick ping on a range of IP addresses specified by the IPRange parameter.
The ping is done with a Time-to-Live (TTL) value of 128 (by default), meaning only the local network
will be pinged.
The function returns an array of IP addresses that responded to the ping and an array
of IP addresses that failed to respond.

## EXAMPLES

### EXAMPLE 1
```
Get-QuickPing -IPRange 192.168.1.1
Performs a quick ping on the IP address 192.168.1.1 with a TTL of 128 and returns an
array of IP addresses that responded to the ping and anget- array of IP addresses that
failed to respond.
```

### EXAMPLE 2
```
Get-QuickPing -IPRange 192.168.1.0/24
Performs a quick ping on all IP addresses in the 192.168.1.0/24 network with a TTL of
128 and returns an array of IP addresses that responded to the ping and an array of IP
addresses that failed to respond.
```

### EXAMPLE 3
```
Get-QuickPing -IPRange @(192.168.1.1, 192.168.1.2, 192.168.1.3)
Performs a quick ping on the IP addresses 192.168.1.1, 192.168.1.2, and 192.168.1.3 with
a TTL of 128 and returns an array of IP addresses that responded to the ping and an array
of IP addresses that failed to respond.
```

## PARAMETERS

### -IPRange
Specifies a range of IP addresses to ping.
Can be a string with a single IP address,
a range of IP addresses in CIDR notation, or an array of IP addresses.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TTL
Specifies the Time-to-Live (TTL) value to use for the ping.
The default value is 128.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 128
Accept pipeline input: False
Accept wildcard characters: False
```

### -BufferSize
{{ Fill BufferSize Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 16
Accept pipeline input: False
Accept wildcard characters: False
```

### -Count
{{ Fill Count Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Author: DrIOSx

## RELATED LINKS

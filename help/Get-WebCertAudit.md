---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-WebCertAudit
schema: 2.0.0
---

# Get-WebCertAudit

## SYNOPSIS
Retrieves the certificate information for a web server.

## SYNTAX

```
Get-WebCertAudit [-Url] <String[]> [<CommonParameters>]
```

## DESCRIPTION
The Get-WebCert function retrieves the certificate information for
a web server by creating a TCP connection and using SSL to retrieve
the certificate information.

## EXAMPLES

### EXAMPLE 1
```
Get-WebCert -Url "https://www.example.com"
This example retrieves the certificate information for the web server at https://www.example.com.
```

## PARAMETERS

### -Url
The URL of the web server.

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

### PSCustomObject
### Returns a PowerShell custom object with the following properties:
### Subject: The subject of the certificate.
### Thumbprint: The thumbprint of the certificate.
### Expires: The expiration date of the certificate.
## NOTES
This function requires access to the target web server over port 443 (HTTPS).

## RELATED LINKS

[https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-WebCertAudit](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-WebCertAudit)

[https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-WebCertAudit](https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-WebCertAudit)


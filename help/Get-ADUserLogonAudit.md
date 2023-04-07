---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version:
schema: 2.0.0
---

# Get-ADUserLogonAudit

## SYNOPSIS
Retrieves the most recent LastLogon timestamp for a specified Active Directory user account from all domain controllers and outputs it as a DateTime object.

## SYNTAX

```
Get-ADUserLogonAudit [-SamAccountName] <Object> [<CommonParameters>]
```

## DESCRIPTION
This function takes a SamAccountName input parameter for a specific user account and retrieves the most recent
LastLogon timestamp for that user from all domain controllers in the Active Directory environment.
It then returns the LastLogon timestamp as a DateTime object.
The function also checks the availability
of each domain controller before querying it, and writes an audit log with a list of available and
unavailable domain controllers.

## EXAMPLES

### EXAMPLE 1
```
Get-ADUserLogonAudit -SamAccountName "jdoe"
Retrieves the most recent LastLogon timestamp for the user account with the SamAccountName "jdoe" from all
domain controllers in the Active Directory environment.
```

## PARAMETERS

### -SamAccountName
Specifies the SamAccountName of the user account to be checked for the most recent LastLogon timestamp.

```yaml
Type: Object
Parameter Sets: (All)
Aliases: Identity, UserName, Account

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### A SamAccountName string representing the user account to be checked.
## OUTPUTS

### A DateTime object representing the most recent LastLogon timestamp for the specified user account.
## NOTES
This function is designed to be run on the primary domain controller, but it can be run on any domain
controller in the environment.
It requires the Active Directory PowerShell module and appropriate permissions to read user account data.
The function may take some time to complete if the Active Directory environment is large or the domain
controllers are geographically distributed.

## RELATED LINKS

<#
.SYNOPSIS
    Builds a list of custom objects containing Active Directory user data.
.DESCRIPTION
    This function builds a list of custom objects containing Active Directory
    user data, such as the user's name, last logon timestamp, and manager.
.PARAMETER ADExport
    An array of Microsoft.ActiveDirectory.Management.ADUser objects.
.OUTPUTS
    System.Collections.Generic.List[ADAuditTasksUser]
    A list of custom objects that contains Active Directory user data.
.EXAMPLE
    $adUsers = Get-ADUser -Filter * -Properties *
    $adAuditTasksUsers = Build-ADAuditTasksUser -ADExport $adUsers
    $adAuditTasksUsers
.NOTES
    Author: DrIOSx
#>

function Build-ADAuditTasksUser {
    param (
        [Microsoft.ActiveDirectory.Management.ADUser[]]$ADExport
    )
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog "Begin ADAUditTasksUser object creation."

    $Export = $ADExport | ForEach-Object {
        [ADAuditTasksUser]::new(
            $_.SamAccountName,
            $_.GivenName,
            $_.Surname,
            $_.Name,
            $_.UserPrincipalName,
            $_.LastLogonTimeStamp,
            $_.Enabled,
            $_.LastLogonTimeStamp,
            $_.DistinguishedName,
            $_.Title,
            $_.Manager,
            $_.Department,
            $false,
            $false
        )
    }

    Write-AuditLog "The ADAUditTasksUser object was built successfully."
    Write-auditlog -EndFunction
    return $Export
}
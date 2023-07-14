<#
.SYNOPSIS
Builds ADAuditTasksComputer objects from Active Directory computer objects.
.DESCRIPTION
This function takes an array of Active Directory computer objects and creates
an array of ADAuditTasksComputer objects.
.PARAMETER ADComputers
An array of Active Directory computer objects.
.OUTPUTS
Returns an array of ADAuditTasksComputer objects.
.EXAMPLE
$ADComputers = Get-ADComputer -Filter {OperatingSystem -Like "Windows 10*"} -Properties *
$Export = Build-ADAuditTasksComputer -ADComputers $ADComputers
.NOTES
Author: DrIOSx
#>
function Build-ADAuditTasksComputer {
    param (
        [pscustomobject[]]$ADComputers
    )
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog "Begin ADAUditTasksComputer object creation."

    $Export = $ADComputers | ForEach-Object {
        [ADAuditTasksComputer]::new(
            $_.DNSHostName,
            $_.Name,
            $_.Enabled,
            $_.IPv4Address,
            $_.IPv6Address,
            $_.OperatingSystem,
            $_.lastLogonTimestamp,
            $_.lastLogonTimestamp,
            $_.Created,
            $_.whenChanged,
            $_.Description,
            $_.DistinguishedName,
            (($_.KerberosEncryptionType | Out-String) -replace "`n" -replace "`r"),
            ($_.servicePrincipalName -join " | "),
            $_.Name
        )
    } # End ForEach-Object

    Write-AuditLog "The ADAUditTasksComputer objects were built successfully."
    Write-AuditLog -EndFunction
    return $Export
}
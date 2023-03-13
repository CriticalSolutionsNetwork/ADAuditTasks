function Build-ADAuditTasksUser {
    #Not Finished
    param (
        [Microsoft.ActiveDirectory.Management.ADUser[]]$ADExport
    )
    $Script:LogString += Write-AuditLog -Message "Begin ADAUditTasksUser object creation."
    $Export = @()
    foreach ($item in $ADExport) {
        $Export += [ADAuditTasksUser]::new(
            $($item.SamAccountName),
            $($item.GivenName),
            $($item.Surname),
            $($item.Name),
            $($item.UserPrincipalName),
            $($item.LastLogonTimeStamp),
            $($item.Enabled),
            $($item.LastLogonTimeStamp),
            $($item.DistinguishedName),
            $($item.Title),
            $($item.Manager),
            $($item.Department),
            $false,
            $false
        )
    }
    if ($null -ne $Export) {
        $Script:LogString += Write-AuditLog -Message "The ADAUditTasksUser object was built successfully."
        return $Export
    }
}

function Build-ADAuditTasksComputer {
    param (
        $ADCompsExport
    )
    $Script:LogString += Write-AuditLog -Message "Begin ADAuditTasksComputer object creation."
    $ADCompExported = @()
    foreach ($item in $ADCompsExport) {
        $ADCompExport += [ADAuditTasksComputer]::new(
            $item.Name,
            $item.DNSHostName,
            $item.Enabled,
            $item.IPv4Address,
            $item.IPv6Address,
            $item.OperatingSystem,
            $item.lastLogonTimestamp,
            $item.Created,
            $item.whenChanged,
            $item.Description,
            $item.DistinguishedName,
            $(($item.KerberosEncryptionType).Value.tostring()),
            ($item.servicePrincipalName -join " | "),
            $item.Name,
            $item.lastLogonTimestamp
        ) # End New [ADComputerAccount] object
    }# End foreach Item in ADComps
    if ($null -ne $ADCompExported) {
        $Script:LogString += Write-AuditLog -Message "The ADAuditTasksComputer object was built successfully."
        return $ADCompExported
    }
}

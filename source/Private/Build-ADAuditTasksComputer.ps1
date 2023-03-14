function Build-ADAuditTasksComputer {
    param (
        $ADComputer
    )

    return [ADAuditTasksComputer]::new(
        $ADComputer.Name,
        $ADComputer.DNSHostName,
        $ADComputer.Enabled,
        $ADComputer.IPv4Address,
        $ADComputer.IPv6Address,
        $ADComputer.OperatingSystem,
        $ADComputer.lastLogonTimestamp,
        $ADComputer.Created,
        $ADComputer.whenChanged,
        $ADComputer.Description,
        $ADComputer.DistinguishedName,
        $(($ADComputer.KerberosEncryptionType).Value.tostring()),
        ($ADComputer.servicePrincipalName -join " | "),
        $ADComputer.Name,
        $ADComputer.lastLogonTimestamp
    )
}


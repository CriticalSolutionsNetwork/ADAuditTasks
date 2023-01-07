class ADAuditTasksComputer {
    [string]$ComputerName
    [string]$DNSHostName
    [bool]$Enabled
    [string]$IPv4Address
    [string]$IPv6Address
    [string]$OperatingSystem
    [string]$LastLogon
    [string]$Created
    [string]$Modified
    [string]$Description
    [string]$OrgUnit
    [string]$KerberosEncryptionType
    [string]$SPNs
    [string]$GroupMemberships #Computername for Group Membership Search
    [string]$LastSeen
    # Constructor 1
    ADAuditTasksComputer(
        [string]$ComputerName,
        [string]$DNSHostName,
        [bool]$Enabled,
        [string]$IPv4Address,
        [string]$IPv6Address,
        [string]$OperatingSystem,
        [long]$LastLogon,
        [datetime]$Created,
        [string]$Modified,
        [string]$Description,
        [string]$OrgUnit,
        [string]$KerberosEncryptionType,
        [string]$SPNs,
        [string]$GroupMemberships,
        [long]$LastSeen
    ) {
        #Begin Contructor 1
        $this.ComputerName = $ComputerName
        $this.DNSHostName = $DNSHostName
        $this.Enabled   = $Enabled
        $this.IPv4Address = $IPv4Address
        $this.IPv6Address = $IPv6Address
        $this.OperatingSystem = $OperatingSystem
        $this.LastLogon = ([DateTime]::FromFileTime($LastLogon))
        $this.Created = $Created
        $this.Modified = $Modified
        $this.Description = $Description
        $this.OrgUnit = $(($OrgUnit -replace '^.*?,(?=[A-Z]{2}=)') -replace ",", ">")
        $this.KerberosEncryptionType = $(($KerberosEncryptionType | Select-Object -ExpandProperty $_) -replace ", ", " | ")
        $this.SPNs = $SPNs
        $this.GroupMemberships = $(Get-ADGroupMemberof -SamAccountName $GroupMemberships -AccountType ADComputer)
        $this.LastSeen = $(
            switch (([DateTime]::FromFileTime($LastSeen))) {
                # Over 90 Days
                { ($_ -lt (Get-Date).Adddays( - (90))) } { '3+ months'; break }
                # Over 60 Days
                { ($_ -lt (Get-Date).Adddays( - (60))) } { '2+ months'; break }
                # Over 90 Days
                { ($_ -lt (Get-Date).Adddays( - (30))) } { '1+ month'; break }
                default { 'Recently' }
            } # End Switch
        ) # End LastSeen
    }# End Constuctor 1
}

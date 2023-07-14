class ADAuditTasksComputer {
    [string]$DNSHostName
    [string]$ComputerName
    [bool]$Enabled
    [string]$IPv4Address
    [string]$IPv6Address
    [string]$OperatingSystem
    [string]$LastLogon
    [string]$LastSeen
    [string]$Created
    [string]$Modified
    [string]$Description
    [string]$GroupMemberships
    [string]$OrgUnit
    [string]$KerberosEncryptionType
    [string]$SPNs
    # Default constructor
    ADAuditTasksComputer() {
        $this.ComputerName = 'DefaultComputer'
    }
    # Constructor 1
    ADAuditTasksComputer(
        [string]$DNSHostName,
        [string]$ComputerName,
        [bool]$Enabled,
        [string]$IPv4Address,
        [string]$IPv6Address,
        [string]$OperatingSystem,
        [long]$LastLogon,
        [long]$LastSeen,
        [string]$Created,
        [string]$Modified,
        [string]$Description,
        [string]$OrgUnit,
        [string]$KerberosEncryptionType,
        [string]$SPNs,
        [string]$GroupMemberships
    ) {
        #Begin Contructor 1
        $this.DNSHostName = $DNSHostName
        $this.ComputerName = $ComputerName
        $this.Enabled = $Enabled
        $this.IPv4Address = $IPv4Address
        $this.IPv6Address = $IPv6Address
        $this.OperatingSystem = $OperatingSystem
        $this.LastLogon = ([DateTime]::FromFileTime($LastLogon))
        $this.LastSeen = $(
            switch (([DateTime]::FromFileTime($LastSeen))) {
                # Over 90 Days
                { ($_ -lt (Get-Date).Adddays( - (90))) } { '3+ months'; break }
                # Over 60 Days
                { ($_ -lt (Get-Date).Adddays( - (60))) } { '2+ months'; break }
                # Over 30 Days
                { ($_ -lt (Get-Date).Adddays( - (30))) } { '1+ month'; break }
                default { 'Recently' }
            } # End Switch
        ) # End LastSeen
        $this.Created = $Created
        $this.Modified = $Modified
        $this.Description = $Description
        $this.GroupMemberships = $(
            switch ($GroupMemberships) {
                { if ($_) { return $true } } { $(Get-ADGroupMemberof -SamAccountName $GroupMemberships -AccountType ADComputer); break }
                default { 'GroupsNotFound' }
            }
        )
        $this.OrgUnit = $(($OrgUnit -replace '^.*?,(?=[A-Z]{2}=)') -replace ",", ">")
        $this.KerberosEncryptionType = $(($KerberosEncryptionType | Select-Object -ExpandProperty $_) -replace ", ", " | ")
        $this.SPNs = $SPNs
    }# End Constuctor 1
    # ToString() method override
    [string] ToString() {
        return "ADAuditTasksComputer: $($this.ComputerName), DNS Host Name: $($this.DNSHostName), Enabled: $($this.Enabled), IPv4 Address: $($this.IPv4Address), IPv6 Address: $($this.IPv6Address), Operating System: $($this.OperatingSystem), Last Logon: $($this.LastLogon), Last Seen: $($this.LastSeen), Created: $($this.Created), Modified: $($this.Modified), Description: $($this.Description), Group Memberships: $($this.GroupMemberships), Org Unit: $($this.OrgUnit), Kerberos Encryption Type: $($this.KerberosEncryptionType), SPNs: $($this.SPNs)"
    }
}
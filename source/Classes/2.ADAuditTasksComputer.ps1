class ADAuditTasksComputer {
    [string]$DNSHostName
    [string]$ComputerName
    [bool]$Enabled
    [string]$IPv4Address
    [string]$IPv6Address
    [string]$OperatingSystem
    [DateTime]$LastLogon
    [string]$LastSeen
    [string]$Created
    [string]$Modified
    [string]$Description
    [string]$GroupMemberships
    [string]$OrgUnit
    [string]$KerberosEncryptionType
    [string]$SPNs
    [string]$OperatingSystemVersion
    [string]$OperatingSystemBuildName

    # Default constructor
    ADAuditTasksComputer() {
        $this.ComputerName = 'DefaultComputer'
    }

    # Parameterized Constructor
    ADAuditTasksComputer(
        [string]$DNSHostName,
        [string]$ComputerName,
        [bool]$Enabled,
        [string]$IPv4Address,
        [string]$IPv6Address,
        [string]$OperatingSystem,
        [DateTime]$LastLogon,
        [string]$LastSeen,
        [string]$Created,
        [string]$Modified,
        [string]$Description,
        [string]$OrgUnit,
        [string]$KerberosEncryptionType,
        [string]$SPNs,
        [string]$GroupMemberships,
        [string]$OperatingSystemVersion,
        [string]$OperatingSystemBuildName
    ) {
        $this.DNSHostName = $DNSHostName
        $this.ComputerName = $ComputerName
        $this.Enabled = $Enabled
        $this.IPv4Address = $IPv4Address
        $this.IPv6Address = $IPv6Address
        $this.OperatingSystem = $OperatingSystem
        $this.LastLogon = $LastLogon
        $this.LastSeen = $LastSeen
        $this.Created = $Created
        $this.Modified = $Modified
        $this.Description = $Description
        $this.GroupMemberships = $GroupMemberships
        $this.OrgUnit = $OrgUnit
        $this.KerberosEncryptionType = $KerberosEncryptionType
        $this.SPNs = $SPNs
        $this.OperatingSystemVersion = $OperatingSystemVersion
        $this.OperatingSystemBuildName = $OperatingSystemBuildName
    }

    # ToString() method override
    [string] ToString() {
        return "ADAuditTasksComputer: $($this.ComputerName), DNS Host Name: $($this.DNSHostName), Enabled: $($this.Enabled), IPv4 Address: $($this.IPv4Address), IPv6 Address: $($this.IPv6Address), Operating System: $($this.OperatingSystem), Last Logon: $($this.LastLogon), Last Seen: $($this.LastSeen), Created: $($this.Created), Modified: $($this.Modified), Description: $($this.Description), Group Memberships: $($this.GroupMemberships), Org Unit: $($this.OrgUnit), Kerberos Encryption Type: $($this.KerberosEncryptionType), SPNs: $($this.SPNs), Operating System Version: $($this.OperatingSystemVersion), Operating System Build Name: $($this.OperatingSystemBuildName)"
    }
}

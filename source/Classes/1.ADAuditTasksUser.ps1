class ADAuditTasksUser {
    [string]$UserName
    [string]$FirstName
    [string]$LastName
    [string]$Name
    [string]$UPN
    [string]$LastSignIn
    [string]$Enabled
    [string]$LastSeen
    [string]$OrgUnit
    [string]$Title
    [string]$Manager
    [string]$Department
    [bool]$AccessRequired
    [bool]$NeedMailbox
    ADAuditTasksUser(
        [string]$UserName,
        [string]$FirstName,
        [string]$LastName,
        [string]$Name,
        [string]$UPN,
        [string]$LastSignIn,
        [string]$Enabled,
        [string]$LastSeen,
        [string]$OrgUnit,
        [string]$Title,
        [string]$Manager,
        [string]$Department,
        [bool]$AccessRequired,
        [bool]$NeedMailbox
    ) {
        $this.UserName = $UserName
        $this.FirstName = $FirstName
        $this.LastName = $LastName
        $this.Name = $Name
        $this.UPN = $UPN
        $this.LastSignIn = ([DateTime]::FromFileTime($LastSignIn))
        $this.Enabled = $Enabled
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
        $this.OrgUnit = $OrgUnit -replace '^.*?,(?=[A-Z]{2}=)'
        $this.Title = $Title
        $this.Manager = $(
            switch ($Manager) {
                # Over 90 Days
                { if ($_) { return $true } } { "$((Get-ADUser -Identity $Manager).Name)"; break }
                # Over 60 Days
                default { 'NotFound' }
            }
        ) # End Manager
        $this.AccessRequired = $AccessRequired
        $this.NeedMailbox = $NeedMailbox
        $this.Department = $Department
    }
}
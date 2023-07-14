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

    [string] ToString() {
        return "ADAuditTasksUser: UserName=$($this.UserName), FirstName=$($this.FirstName), LastName=$($this.LastName), Name=$($this.Name), UPN=$($this.UPN), LastSignIn=$($this.LastSignIn), Enabled=$($this.Enabled), LastSeen=$($this.LastSeen), OrgUnit=$($this.OrgUnit), Title=$($this.Title), Manager=$($this.Manager), Department=$($this.Department), AccessRequired=$($this.AccessRequired), NeedMailbox=$($this.NeedMailbox)"
    }
    ADAuditTasksUser() {
        $this.UserName = 'DefaultUser'
    }

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
                { ($_ -lt (Get-Date).Adddays(-90)) } { '3+ months'; break }
                { ($_ -lt (Get-Date).Adddays(-60)) } { '2+ months'; break }
                { ($_ -lt (Get-Date).Adddays(-30)) } { '1+ month'; break }
                default { 'Recently' }
            }
        )
        $this.OrgUnit = $OrgUnit -replace '^.*?,(?=[A-Z]{2}=)'
        $this.Title = $Title
        $this.Manager = $(
            switch ($Manager) {
                { if ($_) { return $true } } { "$((Get-ADUser -Identity $Manager).Name)"; break }
                default { 'NotFound' }
            }
        )
        $this.AccessRequired = $AccessRequired
        $this.NeedMailbox = $NeedMailbox
        $this.Department = $Department
    }
}

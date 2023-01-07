function Get-ADUserLogonAudit {
    <#
    .SYNOPSIS
    Takes SamAccountName as input to retrieve most recent LastLogon from all DC's and output as DateTime.
    .DESCRIPTION
    Will check if DC's are available for queries. Best run on PDC. To add: Verbose output of all datetime objects.
    .EXAMPLE
    Get-ADUsersLastLogon -SamAccountName "UserName"
    .PARAMETER SamAccountName
    The SamAccountName of the user being checked for LastLogon.
    #>
    [CmdletBinding()]
    [OutputType([datetime])]
    param (
        [Alias("Identity", "UserName", "Account")]
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter the SamAccountName',
            ValueFromPipeline = $true
        )]
        $SamAccountName
    )
    process {
        #Create logging object
        $ADLogString = @()
        #Begin Logging
        $DomainControllers = Get-ADDomainController -Filter { Name -like "*" }
        $Comps = $DomainControllers.name
        $Params = @{}
        $Params.ComputerName = @()
        $NoRemoteAccess = @{}
        $NoRemoteAccess.NoRemoteAccess = @()
        foreach ($comp in $comps) {
            $testRemoting = Test-WSMan -ComputerName $comp -ErrorAction SilentlyContinue
            if ($null -ne $testRemoting ) {
                $params.ComputerName += $comp
            }
            else {
                $NoRemoteAccess.NoRemoteAccess += $comp
            }
        }
        if ($params.ComputerName) {
            $ADLogString += Write-AuditLog -Message "The following DC's were available for WSMan:"
            $ADLogString += Write-AuditLog -Message "$($params.ComputerName)"
        }
        if ($NoRemoteAccess.NoRemoteAccess) {
            $ADLogString += Write-AuditLog -Message "The following DC's were unavailable and weren't included:"
            $ADLogString += Write-AuditLog -Message "$($NoRemoteAccess.NoRemoteAccess)"
        }
        $user = Get-ADUser -Identity $SamAccountName
        $time = 0
        $dt = @()
        foreach ($dc in $params.ComputerName) {
            $user | Get-ADObject -Server $dc -Properties lastLogon -OutVariable usertime -ErrorAction SilentlyContinue | Out-Null
            if ($usertime.LastLogon -gt $time) {
                $time = $usertime.LastLogon
            }
            $dt += [DateTime]::FromFileTime($time)
        }
        return ($dt | Sort-Object -Descending)[0]
    }
}
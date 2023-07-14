function Get-ADUserLogonAudit {
<#
    .SYNOPSIS
    Retrieves the most recent LastLogon timestamp for a specified Active Directory user
    account from all domain controllers and outputs it as a DateTime object.
    .DESCRIPTION
    This function takes a SamAccountName input parameter for a specific user account and
    retrieves the most recent LastLogon timestamp for that user from all domain controllers
    in the Active Directory environment. It then returns the LastLogon timestamp as a DateTime
    object. The function also checks the availability of each domain controller before querying
    it, and writes an audit log with a list of available and unavailable domain controllers.
    .PARAMETER SamAccountName
    Specifies the SamAccountName of the user account to be checked for the most recent LastLogon timestamp.
    .INPUTS
    A SamAccountName string representing the user account to be checked.
    .OUTPUTS
    A DateTime object representing the most recent LastLogon timestamp for the specified user account.
    .EXAMPLE
    Get-ADUserLogonAudit -SamAccountName "jdoe"
    Retrieves the most recent LastLogon timestamp for the user account with the SamAccountName
    "jdoe" from all domain controllers in the Active Directory environment.
    .NOTES
    This function is designed to be run on the primary domain controller, but it can be run on
    any domain controller in the environment. It requires the Active Directory PowerShell module
    and appropriate permissions to read user account data. The function may take some time to complete
    if the Active Directory environment is large or the domain controllers are geographically distributed.
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-ADUserLogonAudit
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-ADUserLogonAudit
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
        Write-AuditLog -Start

        Write-AuditLog "###############################################"
        # Check if the Active Directory module is installed and install it if necessary
        try {
            Install-ADModule -ErrorAction Stop -Verbose
        }
        catch {
            throw $_.Exception
        } ### End ADModule Install
        #Get all domain controllers
        $DomainControllers = Get-ADDomainController -Filter { Name -like "*" }
        $Comps = $DomainControllers.name
        #Create a hash table to store the parameters for Get-ADObject command
        $Params = @{}
        $Params.ComputerName = @()
        #Create a hash table to store domain controllers that are not available for queries
        $NoRemoteAccess = @{}
        $NoRemoteAccess.NoRemoteAccess = @()
        #Loop through all domain controllers to check for remote access
        foreach ($comp in $comps) {
            $testRemoting = Test-WSMan -ComputerName $comp -ErrorAction SilentlyContinue
            if ($null -ne $testRemoting ) {
                $params.ComputerName += $comp
            }
            else {
                $NoRemoteAccess.NoRemoteAccess += $comp
            }
        }
        #Write audit logs for domain controllers that are available for queries
        if ($params.ComputerName) {
            Write-AuditLog "The following DC's were available for WSMan:"
            Write-AuditLog "$($params.ComputerName)"
        }
        #Write audit logs for domain controllers that are not available for queries
        if ($NoRemoteAccess.NoRemoteAccess) {
            Write-AuditLog "The following DC's were unavailable and weren't included:"
            Write-AuditLog "$($NoRemoteAccess.NoRemoteAccess)"
        }
        #Get the AD user object based on the given SamAccountName
        $user = Get-ADUser -Identity $SamAccountName
        #Initialize a variable to store the latest lastLogon time
        $time = 0
        #Initialize an array to store DateTime objects from all domain controllers
        $dt = @()
        #Loop through all domain controllers to get the lastLogon time of the user
        foreach ($dc in $params.ComputerName) {
            $user | Get-ADObject -Server $dc -Properties lastLogon -OutVariable usertime -ErrorAction SilentlyContinue | Out-Null
            if ($usertime.LastLogon -gt $time) {
                $time = $usertime.LastLogon
            }
            $dt += [DateTime]::FromFileTime($time)
        }
        Write-AuditLog -EndFunction
        #Sort the array of DateTime objects in descending order and return the latest DateTime object
        return ($dt | Sort-Object -Descending)[0]
    }
}

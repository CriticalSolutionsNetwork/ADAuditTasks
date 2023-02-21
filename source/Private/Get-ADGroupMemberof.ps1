function Get-ADGroupMemberof {
    <#
    .SYNOPSIS
    Gets the names of the groups that a user or computer is a member of.
    .DESCRIPTION
    The Get-ADGroupMemberof function gets the names of the groups that a user or computer is a member of.
    The function takes two parameters: $SamAccountName (the name of the user or computer) and $AccountType
    (the type of account, either ADUser or ADComputer). The function uses a switch statement to determine
    whether to get the groups that a user or computer is a member of, and returns a string containing the
    names of the groups.
    .PARAMETER SamAccountName
    Specifies the name of the user or computer to get the group membership for.
    .PARAMETER AccountType
    Specifies the type of account, either ADUser or ADComputer. The default value is ADUser.
    .OUTPUTS
    The function returns a string containing the names of the groups that the specified user or computer is a member of.
    .EXAMPLE
    PS C:\> Get-ADGroupMemberof -SamAccountName "jdoe" -AccountType "ADUser"
    In this example, the Get-ADGroupMemberof function is used to get the names of the groups that the user "jdoe" is a
    member of. The type of account is specified using the $AccountType parameter.
    .NOTES
    This function requires the ActiveDirectory PowerShell module.
    .LINK
    https://docs.microsoft.com/en-us/powershell/module/activedirectory/
    #>
    [CmdletBinding()]
    # Define function parameters
    param (
        [string]$SamAccountName,
        [ValidateSet("ADUser", "ADComputer")]
        [string]$AccountType = "ADUser"
    )
    # Process the account name and type
    process {
        switch ($AccountType) {
            "ADComputer" {
                # Get the groups that the computer is a member of
                $GroupStringArray = ((Get-ADComputer -Identity $SamAccountName -Properties memberof).memberof | Get-ADGroup | Select-Object name | Sort-Object name).name
                $GroupString = $GroupStringArray -join " | "
            }
            Default {
                # Get the groups that the user is a member of
                $GroupStringArray = ((Get-ADUser -Identity $SamAccountName -Properties memberof).memberof | Get-ADGroup | Select-Object name | Sort-Object name).name
                $GroupString = $GroupStringArray -join " | "
            }
        }
        # Return a string containing the names of the groups
        return $GroupString
    }
} # End Function

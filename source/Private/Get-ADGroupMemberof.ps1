function Get-ADGroupMemberof {
    [CmdletBinding()]
    param (
        [string]$SamAccountName,
        [ValidateSet("ADUser", "ADComputer")]
        [string]$AccountType = "ADUser"
    )
    process {
        switch ($AccountType) {
            "ADComputer" {
                $GroupStringArray = ((Get-ADComputer -Identity $SamAccountName -Properties memberof).memberof | Get-ADGroup | Select-Object name | Sort-Object name).name
                $GroupString = $GroupStringArray -join " | "
            }
            Default {
                $GroupStringArray = ((Get-ADUser -Identity $SamAccountName -Properties memberof).memberof | Get-ADGroup | Select-Object name | Sort-Object name).name
                $GroupString = $GroupStringArray -join " | "
            }
        }
        return $GroupString
    }
}
<#
.SYNOPSIS
Builds ADAuditTasksComputer objects from Active Directory computer objects.
.DESCRIPTION
This function takes an array of Active Directory computer objects and creates
an array of ADAuditTasksComputer objects.
.PARAMETER ADComputers
An array of Active Directory computer objects.
.OUTPUTS
Returns an array of ADAuditTasksComputer objects.
.EXAMPLE
$ADComputers = Get-ADComputer -Filter {OperatingSystem -Like "Windows 10*"} -Properties *
$Export = Build-ADAuditTasksComputer -ADComputers $ADComputers
.NOTES
Author: DrIOSx
#>
function Build-ADAuditTasksComputer {
    param (
        [pscustomobject[]]$ADComputers
    )

    # Hash tables for Operating System version mapping
    $osVersionMapWorkstation = @{
        "5.1 (2600)"   = "Windows XP"
        "6.0 (6000)"   = "Windows Vista"
        "6.1 (7600)"   = "Windows 7"
        "6.1 (7601)"   = "Windows 7 SP1"
        "6.2 (9200)"   = "Windows 8"
        "6.3 (9600)"   = "Windows 8.1"
        "10.0 (10240)" = "Windows 10 1507"
        "10.0 (10586)" = "Windows 10 1511"
        "10.0 (14393)" = "Windows 10 1607"
        "10.0 (15063)" = "Windows 10 1703"
        "10.0 (16299)" = "Windows 10 1709"
        "10.0 (17134)" = "Windows 10 1803"
        "10.0 (17763)" = "Windows 10 1809"
        "10.0 (18362)" = "Windows 10 1903"
        "10.0 (18363)" = "Windows 10 1909"
        "10.0 (19041)" = "Windows 10 2004"
        "10.0 (19042)" = "Windows 10 20H2"
        "10.0 (19043)" = "Windows 10 21H1"
        "10.0 (19044)" = "Windows 10 21H2"
        "10.0 (19045)" = "Windows 10 22H2"
        "10.0 (22000)" = "Windows 11 21H2"
        "10.0 (22621)" = "Windows 11 22H2"
        "10.0 (22631)" = "Windows 11 23H2"
    }
    $osVersionMapServer = @{
        "5.2 (3790)"   = "Windows Server 2003"
        "6.0 (6000)"   = "Windows Server 2008"
        "6.0 (6001)"   = "Windows Server 2008 SP1"
        "6.0 (6002)"   = "Windows Server 2008 SP2"
        "6.1 (7600)"   = "Windows Server 2008 R2"
        "6.1 (7601)"   = "Windows Server 2008 R2 SP1"
        "6.2 (9200)"   = "Windows Server 2012"
        "6.3 (9600)"   = "Windows Server 2012 R2"
        "10.0 (14393)" = "Windows Server 2016"
        "10.0 (17763)" = "Windows Server 2019"
        "10.0 (20348)" = "Windows Server 2022"
    }

    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog "Begin ADAuditTasksComputer object creation."

    $Export = $ADComputers | ForEach-Object {

        $osVersion = $_.OperatingSystemVersion -replace '^\s+|\s+$', '' # Trim whitespace
        if (-not $osVersion) { $osVersion = "Unknown" } # Handle null/empty values

        $osBuildName = if ($_.OperatingSystem -like "*Server*") {
            if ($null -ne $osVersionMapServer[$osVersion]) {
                $osVersionMapServer[$osVersion]
            }
            else {
                "Unknown Server OS"
            }
        }
        elseif ($_.OperatingSystem -notlike "*windows*") {
            "Non-Windows OS" # Default for non-Windows
        }
        else {
            if ($null -ne $osVersionMapWorkstation[$osVersion]) {
                $osVersionMapWorkstation[$osVersion]
            }
            else {
                "Unknown Workstation OS"
            }
        }


        # Convert LastLogonTimestamp and LastSeen to DateTime
        $lastLogonDateTime = [DateTime]::FromFileTime($_.lastLogonTimestamp)

        $lastSeenString = $(
            switch (([DateTime]::FromFileTime($_.lastLogonTimestamp))) {
                # Over 90 Days
                { ($_ -lt (Get-Date).Adddays( - (90))) } { '3+ months'; break }
                # Over 60 Days
                { ($_ -lt (Get-Date).Adddays( - (60))) } { '2+ months'; break }
                # Over 30 Days
                { ($_ -lt (Get-Date).Adddays( - (30))) } { '1+ month'; break }
                default { 'Recently' }
            } # End Switch
        ) # End LastSeen
        # GroupMemberships processing (adjust as needed)
        $groupMemberships = $(Get-ADGroupMemberof -SamAccountName $_.Name -AccountType ADComputer)

        # Construct the ADAuditTasksComputer object
        [ADAuditTasksComputer]::new(
            $_.DNSHostName,
            $_.Name,
            $_.Enabled,
            $_.IPv4Address,
            $_.IPv6Address,
            $_.OperatingSystem,
            $lastLogonDateTime,
            $lastSeenString, # Now passing the string representation
            $_.Created,
            $_.whenChanged,
            $_.Description,
            $_.DistinguishedName,
            (($_.KerberosEncryptionType | Out-String) -replace "`n" -replace "`r"),
            ($_.servicePrincipalName -join " | "),
            $groupMemberships, # Now using processed group memberships
            $osVersion, # New OperatingSystemVersion
            $osBuildName # New OperatingSystemBuildName
        )
    } # End ForEach-Object

    Write-AuditLog "The ADAuditTasksComputer objects were built successfully."
    Write-AuditLog -EndFunction
    return $Export
}

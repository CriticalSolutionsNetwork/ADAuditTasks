Function Get-AdExtendedRight([Microsoft.ActiveDirectory.Management.ADObject] $ADObject) {
    # Initialize an empty array to store extended rights
    $ExportER = @()
    # Loop through each access control entry in the object's security descriptor
    Foreach ($Access in $ADObject.ntsecurityDescriptor.Access) {
        # Ignore deny permissions, well-known identities, and inherited permissions
        if ($Access.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny) { continue }
        if ($Access.IdentityReference -eq "NT AUTHORITY\SYSTEM") { continue }
        if ($Access.IdentityReference -eq "NT AUTHORITY\SELF") { continue }
        if ($Access.IsInherited) { continue }
        # Check if the access control entry grants an extended right
        if ($Access.ActiveDirectoryRights -band [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight) {
            # Initialize an empty string to store the name of the extended right
            $Right = ""
            # Map the object type of the access control entry to a name of a dangerous extended attribute
            # (see https://technet.microsoft.com/en-us/library/ff405676.aspx)
            switch ($Access.ObjectType) {
                "00299570-246d-11d0-a768-00aa006e0529" { $Right = "User-Force-Change-Password" }
                "45ec5156-db7e-47bb-b53f-dbeb2d03c40" { $Right = "Reanimate-Tombstones" }
                "bf9679c0-0de6-11d0-a285-00aa003049e2" { $Right = "Self-Membership" }
                "ba33815a-4f93-4c76-87f3-57574bff8109" { $Right = "Manage-SID-History" }
                "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" { $Right = "DS-Replication-Get-Changes-All" }
            }
            # If the access control entry grants a dangerous extended right, add it to the array
            if ($Right -ne "") {
                $Rights = [ordered]@{
                    Actor                   = $($Access.IdentityReference)
                    CanActOnThePermissionof = "$($ADObject.name)" + " " + "($($ADObject.DistinguishedName))"
                    WithExtendedRight       = $Right
                }
                $ExportER += New-Object -TypeName PSObject -Property $Rights
                #"$($Access.IdentityReference) can act on the permission of $($ADObject.name) ($($ADObject.DistinguishedName)) with extended right: $Right"
            }
        }
    }
    # Return the array of dangerous extended rights
    return $ExportER
} # End Function
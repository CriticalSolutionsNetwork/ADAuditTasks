Function Get-AdExtendedRight([Microsoft.ActiveDirectory.Management.ADObject] $ADObject) {
    $ExportER = @()
    Foreach ($Access in $ADObject.ntsecurityDescriptor.Access) {
        # Ignore well known and normal permissions
        if ($Access.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Deny) { continue }
        if ($Access.IdentityReference -eq "NT AUTHORITY\SYSTEM") { continue }
        if ($Access.IdentityReference -eq "NT AUTHORITY\SELF") { continue }
        if ($Access.IsInherited) { continue }
        # Check extended right
        if ($Access.ActiveDirectoryRights -band [System.DirectoryServices.ActiveDirectoryRights]::ExtendedRight) {
            $Right = "";
            # This is the list of dangerous extended attributs
            # see : https://technet.microsoft.com/en-us/library/ff405676.aspx
            switch ($Access.ObjectType) {
                "00299570-246d-11d0-a768-00aa006e0529" { $Right = "User-Force-Change-Password" }
                "45ec5156-db7e-47bb-b53f-dbeb2d03c40" { $Right = "Reanimate-Tombstones" }
                "bf9679c0-0de6-11d0-a285-00aa003049e2" { $Right = "Self-Membership" }
                "ba33815a-4f93-4c76-87f3-57574bff8109" { $Right = "Manage-SID-History" }
                "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" { $Right = "DS-Replication-Get-Changes-All" }
            } # End switch
            if ($Right -ne "") {
                $Rights = [ordered]@{
                    Actor                   = $($Access.IdentityReference)
                    CanActOnThePermissionof = "$($ADObject.name)" + " " + "($($ADObject.DistinguishedName))"
                    WithExtendedRight       = $Right
                }
                $ExportER += New-Object -TypeName PSObject -Property $Rights
                #"$($Access.IdentityReference) can act on the permission of $($ADObject.name) ($($ADObject.DistinguishedName)) with extended right: $Right"
            } # Endif
        } # Endif
    } # End Foreach
    return $ExportER
} # End Function
$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Get-AdExtendedRight" {
        It "Should exist" {
            Test-Path function:\Get-AdExtendedRight | Should -Be $true
        }
        <#
                # Mock the AD module and cmdlets
        Mock Get-ADUser { return @{ name = "Test User"; distinguishedName = "CN=Test User,DC=contoso,DC=com" } }
        Mock Get-Acl { return @{ Access = @(
                                    @{ AccessControlType = "Allow"; IdentityReference = "CONTOSO\ITAdmin"; ObjectType = "00299570-246d-11d0-a768-00aa006e0529" },
                                    @{ AccessControlType = "Allow"; IdentityReference = "CONTOSO\ITAdmin"; ObjectType = "45ec5156-db7e-47bb-b53f-dbeb2d03c40" },
                                    @{ AccessControlType = "Allow"; IdentityReference = "CONTOSO\Domain Admins"; ObjectType = "bf9679c0-0de6-11d0-a285-00aa003049e2" },
                                    @{ AccessControlType = "Allow"; IdentityReference = "CONTOSO\ITAdmin"; ObjectType = "ba33815a-4f93-4c76-87f3-57574bff8109" },
                                    @{ AccessControlType = "Allow"; IdentityReference = "CONTOSO\ITAdmin"; ObjectType = "1131f6ad-9c07-11d1-f79f-00c04fc2dcd2" }
                                )
                            }
                        }
        $adObject = Get-ADUser -Identity "Test User"
        $result = Get-AdExtendedRight -ADObject $adObject
        It "should return an array of extended rights" {
            $result | Should -BeOfType "System.Object[]"
            $result.Length | Should -Be 4
        }

        It "should return the correct extended rights" {
            $result[0].Actor | Should -Be "CONTOSO\ITAdmin"
            $result[0].CanActOnThePermissionof | Should -Be "Test User (CN=Test User,DC=contoso,DC=com)"
            $result[0].WithExtendedRight | Should -Be "User-Force-Change-Password"
            $result[1].Actor | Should -Be "CONTOSO\ITAdmin"
            $result[1].CanActOnThePermissionof | Should -Be "Test User (CN=Test User,DC=contoso,DC=com)"
            $result[1].WithExtendedRight | Should -Be "Reanimate-Tombstones"
            $result[2].Actor | Should -Be "CONTOSO\Domain Admins"
            $result[2].CanActOnThePermissionof | Should -Be "Test User (CN=Test User,DC=contoso,DC=com)"
            $result[2].WithExtendedRight | Should -Be "Self-Membership"
            $result[3].Actor | Should -Be "CONTOSO\ITAdmin"
            $result[3].CanActOnThePermissionof | Should -Be "Test User (CN=Test User,DC=contoso,DC=com)"
            $result[3].WithExtendedRight | Should -Be "Manage-SID-History"
        }
        #>

    }

}
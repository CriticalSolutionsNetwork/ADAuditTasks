$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Get-ADGroupMemberof" {
        Context "when the account type is not specified" {
            It "should return the groups that the user is a member of" {
                # Arrange
                $expectedGroups = "Group1 | Group2 | Group3"
                Mock Get-ADUser {
                    param($Identity)
                    return @{memberof = @("Group1", "Group2", "Group3") }
                }

                # Act
                $result = Get-ADGroupMemberof -SamAccountName "jdoe"

                # Assert
                $result | Should -Be $expectedGroups
            }
        }

        Context "when the account type is ADUser" {
            It "should return the groups that the user is a member of" {
                # Arrange
                $expectedGroups = "Group1 | Group2 | Group3"
                Mock Get-ADUser {
                    param($Identity)
                    return @{memberof = @("Group1", "Group2", "Group3") }
                }

                # Act
                $result = Get-ADGroupMemberof -SamAccountName "jdoe" -AccountType "ADUser"

                # Assert
                $result | Should -Be $expectedGroups
            }
        }

        Context "when the account type is ADComputer" {
            It "should return the groups that the computer is a member of" {
                # Arrange
                $expectedGroups = "Group1 | Group2 | Group3"
                Mock Get-ADComputer {
                    param($Identity)
                    return @{memberof = @("Group1", "Group2", "Group3") }
                }

                # Act
                $result = Get-ADGroupMemberof -SamAccountName "comp1" -AccountType "ADComputer"

                # Assert
                $result | Should -Be $expectedGroups
            }
        }
    }
}

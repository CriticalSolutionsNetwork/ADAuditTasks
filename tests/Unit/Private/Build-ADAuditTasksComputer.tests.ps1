$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Build-ADAuditTasksComputer" {
        BeforeEach {
                $mockADComputer = @{
                    DNSHostName            = 'TestComputer.example.com'
                    Name                   = 'TestComputer'
                    Enabled                = $true
                    IPv4Address            = '192.168.1.1'
                    IPv6Address            = '::1'
                    OperatingSystem        = 'Windows 10'
                    lastLogonTimestamp     = 132590514759230000
                    Created                = '2021-01-01'
                    whenChanged            = '2021-05-01'
                    Description            = 'Test computer'
                    DistinguishedName      = 'CN=TestComputer,OU=Computers,DC=example,DC=com'
                    KerberosEncryptionType = 'AES128, AES256'
                    servicePrincipalName   = 'computer1.example.com'
                }
                $inputADComputers = [PSCustomObject]$mockADComputer
                $SamAccountName = 'TestComputer'
                $AccountType = 'ADComputer'
                    Mock -CommandName Get-ADGroupMemberof {
                        return "Group1 | Group2 | Group3"
                    }
                    $result = Build-ADAuditTasksComputer -ADComputers $inputADComputers
        }

        Context "ADComputer Tests" {
            It "Returns a single object" {
                    ($result | Measure-Object).Count | Should -Be 1
            }
            It "Returns an object with the correct DNSHostName" {
                $result.DNSHostName | Should -Be 'TestComputer.example.com'
            }
            It "Returns an object with the correct ComputerName" {
                $result.ComputerName | Should -Be 'TestComputer'
            }
            It "Returns an object with the correct Enabled status" {
                $result.Enabled | Should -Be $true
            }
            It "Returns an object with the correct GroupMembershipsstatus" {
                write-verbose $Result -Verbose
                $result.GroupMemberships | Should -Be "Group1 | Group2 | Group3"
            }
            # Add more tests for other properties as needed
        }
    }
}

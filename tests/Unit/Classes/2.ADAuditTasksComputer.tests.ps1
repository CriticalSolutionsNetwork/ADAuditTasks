$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'ADAuditTasksComputer' {
        Context 'Type creation' {
            It 'Has created a type named ADAuditTasksComputer' {
                'ADAuditTasksComputer' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [ADAuditTasksComputer]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'ADAuditTasksComputer'
            }
            It 'Has a constructor with parameters' {
                $instance = [ADAuditTasksComputer]::new(
                    'computer1.example.com', 'computer1', $true, '192.168.1.2', '::1', 'Windows Server 2019', '132764234000000000', '132764234000000000',
                    (Get-Date).AddDays(-10), '132764234000000000', 'Test computer', 'OU=Computers,DC=example,DC=com', 'AES256', 'computer1.example.com', $null
                )
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'ADAuditTasksComputer'
            }
        }
        Context 'Methods' {
            It 'Overrides the ToString method' {
                $expectedOutput = "ADAuditTasksComputer: DefaultComputer, DNS Host Name: , Enabled: False, IPv4 Address: , IPv6 Address: , Operating System: , Last Logon: , Last Seen: , Created: , Modified: , Description: , Group Memberships: , Org Unit: , Kerberos Encryption Type: , SPNs: "
                ([ADAuditTasksComputer]::new()).ToString() | Should -Be $expectedOutput
            }
        }
        Context 'Properties' {
            It 'Has a Name property' {
                ([ADAuditTasksComputer]::new()).ComputerName | Should -Be 'DefaultComputer'
            }
        }
    }
}

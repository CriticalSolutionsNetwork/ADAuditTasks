$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe 'ADAuditTasksUser' {
        Context 'Type creation' {
            It 'Has created a type named ADAuditTasksUser' {
                'ADAuditTasksUser' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a default constructor' {
                $instance = [ADAuditTasksUser]::new()
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'ADAuditTasksUser'
            }


            It 'Has a constructor with parameters' {
                $instance = [ADAuditTasksUser]::new(
                    'jdoe', 'John', 'Doe', 'John Doe', 'jdoe@example.com', '132764234000000000', 'Enabled', '132764234000000000',
                    'OU=Users,DC=example,DC=com', 'Developer', $null, 'IT', $true, $true
                )
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'ADAuditTasksUser'
                $instance.Manager | Should -Be 'NotFound'
            }
        }

        Context 'Methods' {
            It 'Overrides the ToString method' {
                $expectedOutput = "ADAuditTasksUser: UserName=DefaultUser, FirstName=, LastName=, Name=, UPN=, LastSignIn=, Enabled=, LastSeen=, OrgUnit=, Title=, Manager=, Department=, AccessRequired=False, NeedMailbox=False"
                ([ADAuditTasksUser]::new()).ToString() | Should -Be $expectedOutput
            }
        }

        Context 'Properties' {
            It 'Has a Name property' {
                ([ADAuditTasksUser]::new()).Name | Should -Be $null
            }
        }
    }
}

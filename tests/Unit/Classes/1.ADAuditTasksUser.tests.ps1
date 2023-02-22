$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop }catch { $false }) }
).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe ADAuditTasksUser {
        Context 'Type creation' {
            It 'Has created a type named ADAuditTasksUser' {
                'ADAuditTasksUser' -as [Type] | Should -BeOfType [Type]
            }
        }
        Context 'Constructors' {
            It 'Has a constructor that sets all properties' {
                $user = [ADAuditTasksUser]::new(
                    "johndoe",
                    "John",
                    "Doe",
                    "John Doe",
                    "johndoe@example.com",
                    "131496012909954874",
                    "True",
                    "131496012909954874",
                    "OU=Users,DC=example,DC=com",
                    "Manager",
                    "CN=Jane Smith,OU=Users,DC=example,DC=com",
                    "Department",
                    $false,
                    $true
                )
                $user | Should -Not -BeNullOrEmpty
                $user.GetType().Name | Should -Be 'ADAuditTasksUser'
                $user.UserName | Should Be "johndoe"
                $user.FirstName | Should Be "John"
                $user.LastName | Should Be "Doe"
                $user.Name | Should Be "John Doe"
                $user.UPN | Should Be "johndoe@example.com"
                $user.LastSignIn | Should Be [DateTime]::FromFileTime("131496012909954874")
                $user.Enabled | Should Be "True"
                $user.LastSeen | Should Be "3+ months"
                $user.OrgUnit | Should Be "OU=Users,DC=example,DC=com"
                $user.Title | Should Be "Manager"
                $user.Manager | Should Be "Jane Smith"
                $user.Department | Should Be "Department"
                $user.AccessRequired | Should Be $false
                $user.NeedMailbox | Should Be $true
            }
        }
        Context 'Methods' {
            # No methods defined in the class
        }
        Context 'Properties' {
            BeforeEach {
                $user = [ADAuditTasksUser]::new(
                    "johndoe",
                    "John",
                    "Doe",
                    "John Doe",
                    "johndoe@example.com",
                    "131496012909954874",
                    "True",
                    "131496012909954874",
                    "OU=Users,DC=example,DC=com",
                    "Manager",
                    "CN=Jane Smith,OU=Users,DC=example,DC=com",
                    "Department",
                    $false,
                    $true
                )
            }
            It 'Has a UserName property' {
                $user.UserName | Should Be "johndoe"
            }
            It 'Has a FirstName property' {
                $user.FirstName | Should Be "John"
            }
            It 'Has a LastName property' {
                $user.LastName | Should Be "Doe"
            }
            It 'Has a Name property' {
                $user.Name | Should Be "John Doe"
            }
            It 'Has a UPN property' {
                $user.UPN | Should Be "johndoe@example.com"
            }
            It 'Has a LastSignIn property' {
                $user.LastSignIn | Should Be [DateTime]::FromFileTime("131496012909954874")
            }
            It 'Has an Enabled property' {
                $user.Enabled | Should Be "True"
            }
            It 'Has a LastSeen property' {
                $user.LastSeen | Should Be "3+ months"
            }
            It 'Has an OrgUnit property' {
                $user.OrgUnit | Should Be "OU=Users,DC=example,DC=com"
            }
            It 'Has a Title property' {
                $user.Title | Should Be "Manager"
            }
            It 'Has a Manager property' {
                $user.Manager | Should Be "Jane Smith"
            }
            It 'Has a Department property' {
                $user.Department | Should Be "Department"
            }
            It 'Has an AccessRequired property' {
                $user.AccessRequired | Should Be $false
            }
            It 'Has a NeedMailbox property' {
                $user.NeedMailbox | Should Be $true
            }
        }
    }
}

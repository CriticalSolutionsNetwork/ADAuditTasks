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
            It 'Has a constructor that sets all properties' {
                $comp = [ADAuditTasksComputer]::new(
                    "computer01",
                    "computer01.example.com",
                    $true,
                    "10.0.0.1",
                    "::1",
                    "Windows Server 2019 Standard",
                    "131496012909954874",
                    [DateTime]::Now,
                    [DateTime]::Now,
                    "Computer 01",
                    "OU=Servers,DC=example,DC=com",
                    "RC4_HMAC, AES128_HMAC_SHA1, AES256_HMAC_SHA1",
                    "HTTP/computer01,HTTP/computer01.example.com",
                    "computer01$",
                    "131496012909954874"
                )
                $comp | Should -Not -BeNullOrEmpty
                $comp.GetType().Name | Should -Be 'ADAuditTasksComputer'
                $comp.ComputerName | Should Be "computer01"
                $comp.DNSHostName | Should Be "computer01.example.com"
                $comp.Enabled | Should Be $true
                $comp.IPv4Address | Should Be "10.0.0.1"
                $comp.IPv6Address | Should Be "::1"
                $comp.OperatingSystem | Should Be "Windows Server 2019 Standard"
                $comp.LastLogon | Should Be [DateTime]::FromFileTime("131496012909954874")
                $comp.Created | Should Be [DateTime]::Now
                $comp.Modified | Should Be [DateTime]::Now
                $comp.Description | Should Be "Computer 01"
                $comp.OrgUnit | Should Be "OU=Servers>DC=example>DC=com"
                $comp.KerberosEncryptionType | Should Be "RC4_HMAC | AES128_HMAC_SHA1 | AES256_HMAC_SHA1"
                $comp.SPNs | Should Be "HTTP/computer01,HTTP/computer01.example.com"
                $comp.GroupMemberships | Should Be "Domain Computers"
                $comp.LastSeen | Should Be "Recently"
            }
        }
        Context 'Methods' {
            # No methods defined in the class
        }
        Context 'Properties' {
            BeforeEach {
                $comp = [ADAuditTasksComputer]::new(
                    "computer01",
                    "computer01.example.com",
                    $true,
                    "10.0.0.1",
                    "::1",
                    "Windows Server 2019 Standard",
                    "131496012909954874",
                    [DateTime]::Now,
                    [DateTime]::Now,
                    "Computer 01",
                    "OU=Servers,DC=example,DC=com",
                    "RC4_HMAC, AES128_HMAC
                    _SHA1, AES256_HMAC_SHA1",
                    "HTTP/computer01,HTTP/computer01.example.com",
                    "computer01$",
                    "131496012909954874"
                )
            }
            It 'Has a ComputerName property' {
                $comp.ComputerName | Should Be "computer01"
            }
            It 'Has a DNSHostName property' {
                $comp.DNSHostName | Should Be "computer01.example.com"
            }
            It 'Has an Enabled property' {
                $comp.Enabled | Should Be $true
            }
            It 'Has an IPv4Address property' {
                $comp.IPv4Address | Should Be "10.0.0.1"
            }
            It 'Has an IPv6Address property' {
                $comp.IPv6Address | Should Be "::1"
            }
            It 'Has an OperatingSystem property' {
                $comp.OperatingSystem | Should Be "Windows Server 2019 Standard"
            }
            It 'Has a LastLogon property' {
                $comp.LastLogon | Should Be [DateTime]::FromFileTime("131496012909954874")
            }
            It 'Has a Created property' {
                $comp.Created | Should Be [DateTime]::Now
            }
            It 'Has a Modified property' {
                $comp.Modified | Should Be [DateTime]::Now
            }
            It 'Has a Description property' {
                $comp.Description | Should Be "Computer 01"
            }
            It 'Has an OrgUnit property' {
                $comp.OrgUnit | Should Be "OU=Servers>DC=example>DC=com"
            }
            It 'Has a KerberosEncryptionType property' {
                $comp.KerberosEncryptionType | Should Be "RC4_HMAC | AES128_HMAC_SHA1 | AES256_HMAC_SHA1"
            }
            It 'Has an SPNs property' {
                $comp.SPNs | Should Be "HTTP/computer01,HTTP/computer01.example.com"
            }
            It 'Has a GroupMemberships property' {
                $comp.GroupMemberships | Should Be "Domain Computers"
            }
            It 'Has a LastSeen property' {
                $comp.LastSeen | Should Be "Recently"
            }
        }
    }
}
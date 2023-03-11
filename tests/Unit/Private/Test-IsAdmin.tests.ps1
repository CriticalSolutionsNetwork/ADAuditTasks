$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Test-IsAdmin" {
        It "Returns true if the current user is an administrator" {
            # Mock WindowsPrincipal and WindowsIdentity
            $WindowsIdentityMock = New-Object System.Security.Principal.WindowsIdentity('TestUser')
            Mock System.Security.Principal.WindowsIdentity -MockWith { return $WindowsIdentityMock }
            $WindowsPrincipalMock = New-Object System.Security.Principal.WindowsPrincipal($WindowsIdentityMock)
            Mock System.Security.Principal.WindowsPrincipal -MockWith { return $WindowsPrincipalMock }

            # Call the function and check the result
            Test-IsAdmin | Should Be $true
        }

        It "Returns false if the current user is not an administrator" {
            # Mock WindowsPrincipal and WindowsIdentity
            $WindowsIdentityMock = New-Object System.Security.Principal.WindowsIdentity('TestUser')
            Mock System.Security.Principal.WindowsIdentity -MockWith { return $WindowsIdentityMock }
            $WindowsPrincipalMock = New-Object System.Security.Principal.WindowsPrincipal($WindowsIdentityMock)
            $WindowsPrincipalMock.IsInRole = {param($role) $false}
            Mock System.Security.Principal.WindowsPrincipal -MockWith { return $WindowsPrincipalMock }

            # Call the function and check the result
            Test-IsAdmin | Should Be $false
        }
    }
}


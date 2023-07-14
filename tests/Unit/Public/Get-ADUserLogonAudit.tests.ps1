BeforeAll {
    $script:moduleName = 'ADAUditTasks'
    Write-Output "Modulename is: $script:moduleName"
    Write-Output "Buildfile is: $PSScriptRoot/../../build.ps1"
    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable)) {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')
    Write-Host "Removing module: $script:moduleName"
    Remove-Module -Name $script:moduleName
}

Describe Get-ADUserLogonAudit {
    # Mock the required functions
    Mock Install-ADModule {}
    Mock Get-ADDomainController { return @((New-Object PSObject -Property @{
                    Name = "DC1"
                }), (New-Object PSObject -Property @{
                    Name = "DC2"
                })) }
    Mock Test-WSMan { return $true }
    Mock Get-ADUser { return (New-Object PSObject -Property @{
                SamAccountName = "jdoe"
            }) }
    Mock Get-ADObject { return (New-Object PSObject -Property @{
                LastLogon = 132456789012345678
            }) }

    Describe Get-ADUserLogonAudit {
        It 'Returns the latest LastLogon DateTime object for the specified user' {
            $result = Get-ADUserLogonAudit -SamAccountName "jdoe"
            $expected = [DateTime]::FromFileTime(132456789012345678)
            $result | Should -Be $expected
        }
    }
}
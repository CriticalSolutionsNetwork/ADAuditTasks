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


    Describe 'Get-ADUserPrivilegeAudit' {
        It 'returns 3 PSCustomObject objects when -Report switch is not used' {
            $a, $b, $c = Get-ADUserPrivilegeAudit
            $a | Should -BeOfType [pscustomobject]
            $b | Should -BeOfType [pscustomobject]
            $c | Should -BeOfType [pscustomobject]
        }

        It 'returns a string when -Report switch is used' {
            $zipPath = Get-ADUserPrivilegeAudit -Report
            $zipPath | Should -BeOfType [string]
        }
        Context 'when run without arguments' {
            It 'should return three objects' {
                $a, $b, $c = Get-ADUserPrivilegeAudit -Verbose
                $a.Count | Should -BeGreaterThan 0
                $b.Count | Should -BeGreaterThan 0
                $c.Count | Should -BeGreaterThan 0
            }
        }
    }


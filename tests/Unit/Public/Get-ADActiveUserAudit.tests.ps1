BeforeAll {
    $script:moduleName = '<% $PLASTER_PARAM_ModuleName %>'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
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

    Remove-Module -Name $script:moduleName
}

Describe "Get-ADActiveUserAudit" {
    It "Returns an object of type ADAuditTasksUser" {
        # Call the function and check the return type
        $result = Get-ADActiveUserAudit
        $result.GetType().Name | Should Be "ADAuditTasksUser"
    }

    It "Returns an object with the expected properties" {
        # Call the function and check the returned object properties
        $result = Get-ADActiveUserAudit
        $result | Should have property SamAccountName
        $result | Should have property GivenName
        $result | Should have property Surname
        $result | Should have property Name
        $result | Should have property UserPrincipalName
        $result | Should have property LastLogonTimeStamp
        $result | Should have property Enabled
        $result | Should have property DistinguishedName
        $result | Should have property Title
        $result | Should have property Manager
        $result | Should have property Department
        $result | Should have property HasBeenEmailed
        $result | Should have property HasBeenEmailedValue
    }

    It "Calls Write-AuditLog with the expected message and severity" {
        # Mock Write-AuditLog function
        Mock Write-AuditLog { [PSCustomObject]@{Message="Test message"; Severity="Warning"} }

        # Call the function
        $result = Get-ADActiveUserAudit -Report -Verbose

        # Check that Write-AuditLog was called with the expected message and severity
        Assert-MockCalled Write-AuditLog -Exactly 1 -ParameterFilter { $args[0] -eq "Begin Log" }
        Assert-MockCalled Write-AuditLog -Exactly 1 -ParameterFilter { $args[0] -eq "The Get-ADActiveUserAudit Export was successful." }
        Assert-MockCalled Write-AuditLog -Exactly 1 -ParameterFilter { $args[0] -eq "Returning output object." }
        Assert-MockCalled Write-AuditLog -Exactly 1 -ParameterFilter { $args[0] -eq "End Log" }
        Assert-MockCalled Write-AuditLog -AtLeast 1 -ParameterFilter { $args[0] -eq "Test message" }
        Assert-MockCalled Write-AuditLog -AtLeast 1 -ParameterFilter { $args[1] -eq "Warning" }
    }
}



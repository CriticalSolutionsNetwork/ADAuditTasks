$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Write-AuditLog" {
        It "Returns a pscustomobject" {
            # Mock Test-IsAdmin function
            Mock Test-IsAdmin { $true }

            # Call the function and check the return type
            $result = Write-AuditLog -Message "Test message"
            $result.GetType().Name | Should Be "pscustomobject"
        }

        It "Logs an audit entry with the specified message and severity" {
            # Mock Write-Verbose, Write-Warning and Write-Error functions
            Mock Write-Verbose { $null }
            Mock Write-Warning { $null }
            Mock Write-Error { $null }

            # Mock Test-IsAdmin function
            Mock Test-IsAdmin { $true }

            # Call the function with a warning message and check the result
            $result = Write-AuditLog -Message "Test warning message" -Severity "Warning"
            $result.Message | Should Be "Test warning message"
            $result.Severity | Should Be "Warning"

            # Call the function with an error message and check the result
            $result = Write-AuditLog -Message "Test error message" -Severity "Error"
            $result.Message | Should Be "Test error message"
            $result.Severity | Should Be "Error"

            # Call the function with an information message and check the result
            $result = Write-AuditLog -Message "Test information message" -Severity "Information"
            $result.Message | Should Be "Test information message"
            $result.Severity | Should Be "Information"
        }
    }
}

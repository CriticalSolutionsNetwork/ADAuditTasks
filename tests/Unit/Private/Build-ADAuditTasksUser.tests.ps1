$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName



Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe Build-ADAuditTasksUser {
        It "Should exist" {
            Test-Path function:\Build-ADAuditTasksUser | Should -Be $true
        }
    }
}

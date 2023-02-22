$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName

Import-Module $ProjectName

InModuleScope $ProjectName {
    Describe "Build-ReportArchive" {
        Context "When exporting data to CSV and archiving CSV and log files" {
            BeforeAll {
                $export = Get-Process
                $csvFile = "C:\Temp\ExportedData.csv"
                $zipFile = "C:\Temp\ExportedData.zip"
                $logFile = "C:\Temp\ExportedData.log"
                $result = Build-ReportArchive -Export $export -csv $csvFile -zip $zipFile -log $logFile
            }

            It "should create a zip file containing the archived CSV and log files" {
                $result | Should -BeOfType "String"
                Test-Path $result | Should -Be $true
            }

            It "should contain a CSV file inside the zip file" {
                $zipContents = (Expand-Archive $result -PassThru).FullName
                $zipContents | Should -Contain $csvFile
            }

            It "should contain a log file inside the zip file" {
                $zipContents = (Expand-Archive $result -PassThru).FullName
                $zipContents | Should -Contain $logFile
            }

            AfterAll {
                # Clean up test files
                Remove-Item "C:\Temp\ExportedData.*" -Force
            }
        }
    }

}

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

Describe 'Join-CSVFile' {
    BeforeAll {
        Mock -CommandName Write-AuditLog -MockWith {}
        Mock -CommandName Initialize-DirectoryPath -MockWith {}
    }

    Context 'CSV file merging' {
        BeforeEach {
            $csv1 = "Id,Name`n1,Alice`n2,Bob"
            $csv2 = "Id,Name`n3,Charlie`n4,David"
            Set-Content -Path TestDrive:/csv1.csv -Value $csv1
            Set-Content -Path TestDrive:/csv2.csv -Value $csv2
            $csvFilePaths = @("TestDrive:/csv1.csv", "TestDrive:/csv2.csv")
            $tempOutputFolderPath = Join-Path -Path (Get-Item -Path "TestDrive:\").FullName -ChildPath "temp"
            New-Item -Path $tempOutputFolderPath -ItemType Directory -Force | Out-Null
        }

        It 'Processes valid CSV files' {
            Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $tempOutputFolderPath
            Assert-MockCalled Write-AuditLog -Times 4 -Scope It
        }
        It 'Throws an exception for empty CSV files' {
            $csvEmpty = ""
            Set-Content -Path TestDrive:/csvEmpty.csv -Value $csvEmpty
            $csvFilePaths = @("TestDrive:/csv1.csv", "TestDrive:/csvEmpty.csv", "TestDrive:/csv2.csv")
            { Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $tempOutputFolderPath } | Should -Throw -ExpectedMessage "Empty CSV file: TestDrive:/csvEmpty.csv"
        }
        It 'Uses custom AttachmentFolderPath' {
            $customOutputFolderPath = Join-Path -Path (Get-Item -Path "TestDrive:\").FullName -ChildPath "custom"
            New-Item -Path $customOutputFolderPath -ItemType Directory -Force | Out-Null
            Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $customOutputFolderPath
            $outputCsv = Get-ChildItem -Path $customOutputFolderPath -Filter "*.JoinedCSVs.csv"
            $outputCsv | Should -Not -BeNullOrEmpty
        }
        It 'Creates a merged CSV file' {
            Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $tempOutputFolderPath
            $outputCsv = Get-ChildItem -Path $tempOutputFolderPath -Filter "*.JoinedCSVs.csv"
            $outputCsv | Should -Not -BeNullOrEmpty
            $mergedData = Import-Csv -Path $outputCsv.FullName

            $mergedData.Count | Should -Be 4
            $mergedData[0].Id | Should -Be 1
            $mergedData[0].Name | Should -Be 'Alice'
            $mergedData[1].Id | Should -Be 2
            $mergedData[1].Name | Should -Be 'Bob'
            $mergedData[2].Id | Should -Be 3
            $mergedData[2].Name | Should -Be 'Charlie'
            $mergedData[3].Id | Should -Be 4
            $mergedData[3].Name | Should -Be 'David'
        }

        It 'Throws an exception for a file not found' {
            $csvFilePaths = @("TestDrive:/csv1.csv", "TestDrive:/nonexistent.csv", "TestDrive:/csv2.csv")
            { Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $tempOutputFolderPath } | Should -Throw -ExpectedMessage "File not found: TestDrive:/nonexistent.csv"
        }
        It 'Skips CSV files with mismatched headers' {
            $csv3 = "Id,FullName`n5,Eve`n6,Frank"
            Set-Content -Path TestDrive:/csv3.csv -Value $csv3
            $csvFilePaths = @("TestDrive:/csv1.csv", "TestDrive:/csv3.csv")
            Join-CSVFile -CSVFilePaths $csvFilePaths -AttachmentFolderPath $tempOutputFolderPath
            Assert-MockCalled Write-AuditLog -Times 3 -Scope It
        }
    }
}

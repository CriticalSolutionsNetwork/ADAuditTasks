function Initialize-DirectoryPath {
    <#
.SYNOPSIS
Initializes one or more directory paths if they do not already exist.
.DESCRIPTION
The `Initialize-DirectoryPath` function checks if the specified directory
paths exist. If a path does not exist, the function will create the directory.
If a directory already exists, no action is taken.
.PARAMETER DirectoryPath
The `DirectoryPath` parameter specifies an array of directory paths to be checked
and created if they do not already exist.
.EXAMPLE
Initialize-DirectoryPath -DirectoryPath "C:\Output"

This example checks if the "C:\Output" directory exists. If it does not exist,
the function creates the directory. If the directory already exists, no action
is taken.
.EXAMPLE
Initialize-DirectoryPath -DirectoryPath "C:\Output1", "C:\Output2"

This example checks if the "C:\Output1" and "C:\Output2" directories exist. If a directory
does not exist, the function creates it. If a directory already exists, no action
is taken.
.NOTES
This function is not visible outside of the module.
.NOTES
Author: DrIOSx
Date: 15-Apr-2023
#>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[]]$DirectoryPath
    )
    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        Write-AuditLog "Testing $($DirectoryPath.Count) directory path/s:"
    }
    process {
        $processedPaths = @()
        foreach ($Path in $DirectoryPath) {
            $AttachmentFolderPathCheck = Test-Path -Path $Path
            If (!($AttachmentFolderPathCheck)) {
                Try {
                    # If not present then create the dir
                    New-Item -ItemType Directory $Path -Force -ErrorAction Stop | Out-Null
                    Write-AuditLog "The following directory did not exist and will be created: "
                    Write-AuditLog "$($Path)"
                }
                Catch {
                    Write-AuditLog -Message "Directory was not created: $Path" -Severity Error
                    Write-AuditLog "End Log"
                    throw $_.Exception
                }
            }
            $processedPaths += $Path
        }
        Write-AuditLog "Processed directories:"
        $processedPaths | ForEach-Object { Write-AuditLog $_ }
    }
    end {
        Write-AuditLog "Finished testing path/s."
        Write-AuditLog -EndFunction
    }
}
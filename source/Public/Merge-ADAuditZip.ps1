function Merge-ADAuditZip {
    <#
    .SYNOPSIS
    Combines multiple audit report files into a single compressed ZIP file.
    .DESCRIPTION
    The Merge-ADAuditZip function combines multiple audit report files into a single
    compressed ZIP file. The function takes an array of file paths, a maximum file
    size for the output ZIP file, an output folder for the merged file, and an optional
    switch to open the directory of the merged file after creation.
    .PARAMETER FilePaths
    Specifies an array of file paths to be merged into a single compressed ZIP file.
    .PARAMETER MaxFileSize
    Specifies the maximum file size (in bytes) for the output ZIP file. The default value is 24 MB.
    .PARAMETER OutputFolder
    Specifies the output folder for the merged compressed ZIP file. The default folder is C:\temp.
    .PARAMETER OpenDirectory
    Specifies an optional switch to open the directory of the merged compressed ZIP file after creation.
    .EXAMPLE
    $workstations = Get-ADHostAudit -HostType WindowsWorkstations -Report
    $servers = Get-ADHostAudit -HostType WindowsServers -Report
    $nonWindows = Get-ADHostAudit -HostType "Non-Windows" -Report
    Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows

    This example combines three audit reports for Windows workstations, Windows servers,
    and non-Windows hosts into a single compressed ZIP file.
    .EXAMPLE
    Merge-ADAuditZip -FilePaths C:\AuditReports\Report1.csv,C:\AuditReports\Report2.csv -MaxFileSize 50MB -OutputFolder C:\MergedReports -OpenDirectory

    This example merges two audit reports into a single compressed ZIP file with a maximum file size of 50 MB, an output folder of C:\MergedReports,
    and opens the directory of the merged compressed ZIP file after creation.
    .NOTES
    This may or may not work with various types of input.
#>
    param(
        [string[]]$FilePaths, # Array of file paths to be merged into a single zip file
        [int]$MaxFileSize = 24MB, # Maximum size (in bytes) of the output zip file
        [string]$OutputFolder = "C:\temp", # Output path of the merged zip file
        [switch]$OpenDirectory  # Optional switch to open the directory of the merged zip file after creation
    )
    [string]$OutputPath = "$($OutputFolder)\$((Get-Date).ToString('yyyy-MM-dd_hh.mm.ss'))_$($env:USERDNSDOMAIN)_CombinedAudit.zip"
    # Create the output directory if it doesn't exist
    if (-not (Test-Path -Path $OutputFolder)) {
        $Script:ADLogString += Write-AuditLog -Message "Would you like to create the directory $($OutputFolder)?" -Severity Warning
        Try {
            # If not present then create the dir
            New-Item -ItemType Directory $OutputFolder -Force -ErrorAction Stop -ErrorVariable CreateDirErr | Out-Null
        }
        Catch {
            $Script:ADLogString += Write-AuditLog -Message "Unable to create output directory $($OutputFolder)" -Severity Error
            throw $CreateDirErr
        }
    }
    # Create a hashtable to store the file sizes
    $fileSizes = @{}
    foreach ($filePath in $FilePaths) {
        # Check if the file is not empty
        if (Get-Content $filePath) {
            $fileSizes[$filePath] = (Get-Item $filePath).Length  # Get the size of each file and store in hashtable
        }
        else {
            $Script:ADLogString += Write-AuditLog -Message  "File $filePath is empty and will be skipped."
        }
    }
    # Sort the files by size in descending order
    $sortedFiles = $fileSizes.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -ExpandProperty Name
    # Add files to the zip until the maximum size is reached
    $currentSize = 0
    $filesToAdd = @()
    foreach ($filePath in $sortedFiles) {
        if (($currentSize + $fileSizes[$filePath]) -gt $MaxFileSize) {
            # If adding the next file would exceed the maximum size
            # Create a zip file with the current batch of files
            Compress-Archive -Path $filesToAdd -DestinationPath $OutputPath -Update
            $filesToAdd = @()  # Clear the list of files to add
            $currentSize = 0  # Reset current size counter
        }
        $filesToAdd += $filePath  # Add the current file to the list of files to add
        $currentSize += $fileSizes[$filePath]  # Add the size of the current file to the current size counter
    }
    # Create a zip file with the remaining files
    Compress-Archive -Path $filesToAdd -DestinationPath $OutputPath -Update
    # Remove the original files
    foreach ($filePath in $FilePaths) {
        Remove-Item -Path $filePath -Force
    }
    if ($OpenDirectory) {
        # If the OpenDirectory switch is used
        Invoke-Item (Split-Path $OutputPath)  # Open the directory of the merged zip file
    }
    else {
        return $OutputPath  # Otherwise, return the path of the merged zip file
    }
}
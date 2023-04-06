function Build-DirectoryPath {
    param (
        $DirectoryPath
    )
    $AttachmentFolderPathCheck = Test-Path -Path $DirectoryPath
    If (!($AttachmentFolderPathCheck)) {
        $Script:LogString += Write-AuditLog -Message "Would you like to create the directory $($DirectoryPath)?" -Severity Warning
        Try {
            # If not present then create the dir
            New-Item -ItemType Directory $DirectoryPath -Force -ErrorAction Stop | Out-Null
            $Script:LogString += Write-AuditLog -Message $("Directory: " + $DirectoryPath + " was created.")
        }
        Catch {
            $Script:LogString += Write-AuditLog -Message $("Directory: " + $DirectoryPath + " was not created.") -Severity Error
            $Script:LogString += Write-AuditLog -Message "End Log"
            throw $_.Exception
        }
        # Log creation of output directory
        $outputMsg = "$("Output Folder created at: `n" + $DirectoryPath)"
        $Script:LogString += Write-AuditLog -Message $outputMsg
    }
    else {
        $Script:LogString += Write-AuditLog -Message $("Directory: " + $DirectoryPath + " exists already and will be used.")
    }

}
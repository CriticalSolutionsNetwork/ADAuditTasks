function Test-ADModuleInstall {
    # Create logging object
    $Script:LogString = @()
    # Begin Logging
    $Script:LogString += Write-AuditLog -Message "Begin Log"
    Install-ADModule
}
function Install-ADModule {
    $Script:ADLogString += Write-AuditLog -Message "The $modName module version $modVer is not installed. Would you like to install it?" -Severity Warning
    try {
        Import-Module ServerManager -ErrorAction Stop
        Add-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
        Import-Module "ActiveDirectory" -Global -ErrorAction Stop
    }
    catch {
        $Script:ADLogString += Write-AuditLog -Message "The ActiveDirectory module failed to install."
        throw $Script:ADLogString += Write-AuditLog -Message "$($Error[0].Exception)" -Severity Error
    } # End Region try/catch ActiveDirectory
}
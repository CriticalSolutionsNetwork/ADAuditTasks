function Install-ADModule {
    try {
        if (!(Get-Module -Name ActiveDirectory -ListAvailable)) {
            if (!(Test-IsAdmin)) {
                $Script:LogString += Write-AuditLog -Message "You must be run the script as an administrator to install ActiveDirectory module!"
                $Script:LogString += Write-AuditLog -Message "Once you've installed the module, susequent runs will not need elevation!"
                Exit
            }
            throw
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
        # $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module is not installed, would you like to install it?" -Severity Warning
        try {
            $osName = (Get-WmiObject -Class Win32_OperatingSystem -ErrorAction Stop).Name.Split('|')[0]
            # $Script:LogString += Write-AuditLog -Message "Installing ActiveDirectory Module."
            # Run the command to install AD module based on OS type
            if ($osName -match "Windows Server") {
                Import-Module ServerManager -ErrorAction Stop
                Install-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
            }
            else {
                Enable-WindowsOptionalFeature -Online -FeatureName RSATClient-Roles-AD-Powershell -ErrorAction Stop
            }
        }
        catch {
            # $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module failed to install."
            # $Script:LogString += Write-AuditLog -Message "Install Remote Server Administration Tools at:"
            # $Script:LogString += Write-AuditLog -Message "https://www.microsoft.com/en-us/download/details.aspx?id=45520"
            throw $_.Exception
        } # End Region try/catch ActiveDirectory import
    }
    finally {
        <#Do this after the try block regardless of whether an exception occurred or not#>
        try {
            # $Script:LogString += Write-AuditLog -Message "Importing the ActiveDirectory module."
            Import-Module "ActiveDirectory" -Global -ErrorAction Stop
            # $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module was imported!"
            Write-Output "The ActiveDirectory module was imported!"
        }
        catch {
            # $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module failed to import."
            throw $_.Exception
        }
    }
}



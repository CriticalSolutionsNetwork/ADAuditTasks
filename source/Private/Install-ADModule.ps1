function Install-ADModule {
    # Setup Variables
    $SaveVerbosePreference = $script:VerbosePreference
    $script:VerbosePreference = 'SilentlyContinue'
    Get-CimInstance -Class Win32_OperatingSystem -ErrorAction Stop -OutVariable OS -Verbose:$false | Out-Null
    $script:VerbosePreference = $SaveVerbosePreference
    $OSName = ($OS).Name.Split('|')[0]
    $OSBuildNumber = $($OS.BuildNumber)
    $OSVersion = $($OS.Version)
    try {
        $SaveVerbosePreference = $script:VerbosePreference
        Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
        $script:VerbosePreference = $SaveVerbosePreference

        $Script:LogString += Write-AuditLog -Message "The ActiveDirectory Module was successfully imported."
        $Script:LogString += Write-AuditLog -Message "OS: $OSName Build: $OSBuildNumber, Version: $OSVersion"
    }
    catch {
        if (!(Test-IsAdmin)) {
            $Script:LogString += Write-AuditLog -Message "You must be run the script as an administrator to install ActiveDirectory module!"
            $Script:LogString += Write-AuditLog -Message "Once you've installed the module, susequent runs will not need elevation!"
            throw "Installation requires elevation."
        }
        if (($OSBuildNumber -lt 17763) -and ($OSName -notmatch "Windows Server") ) {
            # Exit Function if windows version is less than Windows 10 October 2018 (1809)
            $Script:LogString += Write-AuditLog -Message "Get installation instructions and download Remote Server Administration Tools (RSAT):"
            $Script:LogString += Write-AuditLog -Message "https://www.microsoft.com/en-us/download/details.aspx?id=45520"
            throw "Install the appropriate RSAT module for $OSName Build: $OSBuildNumber, Version: $OSVersion."
        }
        # Write-AuditLog Warning (-WarningAction Inquire)
        $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module is not installed, would you like attempt to install it?" -Severity Warning
        try {
            $Script:LogString += Write-AuditLog -Message "Potentially compatible OS: $OSName Build: $OSBuildNumber, Version: $OSVersion."
            $Script:LogString += Write-AuditLog -Message "Installing ActiveDirectory Module."
            # Run the command to install AD module based on OS
            if ($OSName -match "Windows Server") {
                # If Windows Server
                $Script:LogString += Write-AuditLog -Message "OS matched `"Windows Server`"."
                $Script:LogString += Write-AuditLog -Message "Importing ServerManager Module."
                Import-Module ServerManager -ErrorAction Stop
                $Script:LogString += Write-AuditLog -Message "Using Install-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature to install ActiveDirectory Module."
                Install-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
            }
            else {
                # If Windows Client
                $Script:LogString += Write-AuditLog -Message "OperatingSystem: $OSName is not like `"Windows Server`" and"
                $Script:LogString += Write-AuditLog -Message "OSBuild: $OSBuildNumber is greater than 17763 (Windows 10 October 2018 (1809) Update)."
                $Script:LogString += Write-AuditLog -Message "Retrieving RSAT.ActiveDirectory Feature using Get-WindowsCapability -Online"
                Get-WindowsCapability -Online | `
                    Where-Object { $_.Name -like "Rsat.ActiveDirectory*" } -ErrorAction Stop -OutVariable ADRSATModule | Out-Null
                $RSATModuleName = $($ADRSATModule.Name)
                $Script:LogString += Write-AuditLog -Message "Installing $RSATModuleName features."
                Add-WindowsCapability -Online -Name $RSATModuleName -ErrorAction Stop
            }
        }
        catch {
            $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module failed to install."
            throw $_.Exception
        } # End Region try/catch ActiveDirectory import
        finally {
            try {
                $Script:LogString += Write-AuditLog -Message "Attempting to import the ActiveDirectory module."
                $SaveVerbosePreference = $script:VerbosePreference
                Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
                $script:VerbosePreference = $SaveVerbosePreference
                $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module was imported!"
            }
            catch {
                $Script:LogString += Write-AuditLog -Message "The ActiveDirectory module failed to import."
                throw $_.Exception
            }
        }
    } # End Import Catch
}
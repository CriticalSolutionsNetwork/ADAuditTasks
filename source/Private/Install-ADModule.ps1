<#
.SYNOPSIS
    Installs the Active Directory module on a Windows computer.
.DESCRIPTION
    This function installs the Active Directory module on a Windows computer.
    The appropriate installation method is determined based on the operating
    system version and build number.
.NOTES
    The function requires elevation to install the Active Directory module.
.EXAMPLE
    Install-ADModule
.INPUTS
    None.
.OUTPUTS
    None.
.NOTES
    Author: DrIOSx
#>
function Install-ADModule {
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
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

        Write-AuditLog "The ActiveDirectory Module was successfully imported."
        Write-AuditLog "OS: $OSName Build: $OSBuildNumber, Version: $OSVersion"
    }
    catch {
        if (!(Test-IsAdmin)) {
            Write-AuditLog "You must be run the script as an administrator to install ActiveDirectory module!"
            Write-AuditLog "Once you've installed the module, susequent runs will not need elevation!"
            throw "Installation requires elevation."
        }
        if (($OSBuildNumber -lt 17763) -and ($OSName -notmatch "Windows Server") ) {
            # Exit Function if windows version is less than Windows 10 October 2018 (1809)
            Write-AuditLog "Get installation instructions and download Remote Server Administration Tools (RSAT):"
            Write-AuditLog "https://www.microsoft.com/en-us/download/details.aspx?id=45520"
            throw "Install the appropriate RSAT module for $OSName Build: $OSBuildNumber, Version: $OSVersion."
        }
        # Write-AuditLog Warning (-WarningAction Inquire)
        Write-AuditLog "The ActiveDirectory module is not installed, would you like attempt to install it?" -Severity Warning
        try {
            Write-AuditLog "Potentially compatible OS: $OSName Build: $OSBuildNumber, Version: $OSVersion."
            Write-AuditLog "Installing ActiveDirectory Module."
            # Run the command to install AD module based on OS
            if ($OSName -match "Windows Server") {
                # If Windows Server
                Write-AuditLog "OS matched `"Windows Server`"."
                Write-AuditLog "Importing ServerManager Module."
                Import-Module ServerManager -ErrorAction Stop
                Write-AuditLog "Using Install-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature to install ActiveDirectory Module."
                Install-WindowsFeature RSAT-AD-PowerShell -IncludeAllSubFeature -ErrorAction Stop
            }
            else {
                # If Windows Client
                Write-AuditLog "OperatingSystem: $OSName is not like `"Windows Server`" and"
                Write-AuditLog "OSBuild: $OSBuildNumber is greater than 17763 (Windows 10 October 2018 (1809) Update)."
                Write-AuditLog "Retrieving RSAT.ActiveDirectory Feature using Get-WindowsCapability -Online"
                Get-WindowsCapability -Online | `
                    Where-Object { $_.Name -like "Rsat.ActiveDirectory*" } -ErrorAction Stop -OutVariable ADRSATModule | Out-Null
                $RSATModuleName = $($ADRSATModule.Name)
                Write-AuditLog "Installing $RSATModuleName features."
                Add-WindowsCapability -Online -Name $RSATModuleName -ErrorAction Stop
            }
        }
        catch {
            Write-AuditLog "The ActiveDirectory module failed to install."
            throw $_.Exception
        } # End Region try/catch ActiveDirectory import
        finally {
            try {
                Write-AuditLog "Attempting to import the ActiveDirectory module."
                $SaveVerbosePreference = $script:VerbosePreference
                Import-Module ActiveDirectory -ErrorAction Stop -Verbose:$false
                $script:VerbosePreference = $SaveVerbosePreference
                Write-AuditLog "The ActiveDirectory module was imported!"
                Write-AuditLog -EndFunction
            }
            catch {
                Write-AuditLog "The ActiveDirectory module failed to import."
                throw $_.Exception
            }
        }
    } # End Import Catch
}
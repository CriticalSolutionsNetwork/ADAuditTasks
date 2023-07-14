function Initialize-ModuleEnv {
<#
    .SYNOPSIS
    Initializes the environment by installing required PowerShell modules.
    .DESCRIPTION
    This function installs PowerShell modules required by the script. It can install public or pre-release versions of the module, and it supports installation for all users or current user.
    .PARAMETER PublicModuleNames
    An array of module names to be installed. Required when using the Public parameter set.
    .PARAMETER PublicRequiredVersions
    An array of required module versions to be installed. Required when using the Public parameter set.
    .PARAMETER PrereleaseModuleNames
    An array of pre-release module names to be installed. Required when using the Prerelease parameter set.
    .PARAMETER PrereleaseRequiredVersions
    An array of required pre-release module versions to be installed. Required when using the Prerelease parameter set.
    .PARAMETER Scope
    The scope of the module installation. Possible values are "AllUsers" and "CurrentUser". This determines the installation scope of the module.
    .PARAMETER ImportModuleNames
    The specific modules you'd like to import from the installed package to streamline imports. This is used when you want to import only specific modules from a package, rather than all of them.
    .EXAMPLE
    Initialize-ModuleEnv -PublicModuleNames "PSnmap", "Microsoft.Graph" -PublicRequiredVersions "1.3.1","1.23.0" -Scope AllUsers

    This example installs the PSnmap and Microsoft.Graph modules in the AllUsers scope with the specified versions.
    .EXAMPLE
    $params1 = @{
        PublicModuleNames      = "PSnmap","Microsoft.Graph"
        PublicRequiredVersions = "1.3.1","1.23.0"
        ImportModuleNames      = "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns"
        Scope                  = "CurrentUser"
    }
    Initialize-ModuleEnv @params1

    This example installs Microsoft.Graph and Pester Modules in the CurrentUser scope with the specified versions.
    It will attempt to only import Microsoft.Graph Modules matching the names in the "ImportModulesNames" array.
    .EXAMPLE
    $params2 = @{
        PrereleaseModuleNames      = "Sampler", "Pester"
        PrereleaseRequiredVersions = "2.1.5", "4.10.1"
        Scope                       = "CurrentUser"
    }
    Initialize-ModuleEnv @params2
    This example installs the PreRelease Sampler and Pester Modules in the CurrentUser scope with the specified versions.
    Double check https://www.powershellgallery.com/packages/<ModuleName>/<ModuleVersionNumber>
    to verify if the "-PreRelease" switch is needed.
    .INPUTS
    None
    .OUTPUTS
    None
    .NOTES
    Author: DrIOSx
    This function makes extensive use of the Write-AuditLog function for logging actions, warnings, and errors. It also uses a script-scope variable $script:VerbosePreference for controlling verbose output.
#>
    [CmdletBinding(DefaultParameterSetName = "Public")]
    param (
        [Parameter(ParameterSetName = "Public", Mandatory)]
        [string[]]$PublicModuleNames,
        [Parameter(ParameterSetName = "Public", Mandatory)]
        [string[]]$PublicRequiredVersions,
        [Parameter(ParameterSetName = "Prerelease", Mandatory)]
        [string[]]$PrereleaseModuleNames,
        [Parameter(ParameterSetName = "Prerelease", Mandatory)]
        [string[]]$PrereleaseRequiredVersions,
        [ValidateSet(
            "AllUsers",
            "CurrentUser"
        )]
        [string]$Scope,
        [string[]]$ImportModuleNames = $null
    )
    # Start logging function execution
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    # Function limit needs to be set higher if installing graph module and if powershell is version 5.1.
    # The Microsoft.Graph module requires an increased function limit.
    # If we're installing this module, set the function limit to 8192.
    if ($PublicModuleNames -match 'Microsoft.Graph' -or $PrereleaseModuleNames -match "Microsoft.Graph") {
        if ($script:MaximumFunctionCount -lt 8192) {
            $script:MaximumFunctionCount = 8192
        }
    }
    # Check and install PowerShellGet.
    # PowerShellGet is required for module management in PowerShell.
    ### https://learn.microsoft.com/en-us/powershell/scripting/gallery/installing-psget?view=powershell-7.3
    # Get all available versions of PowerShellGet
    $PSGetVer = Get-Module -Name PowerShellGet -ListAvailable

    # Initialize flag to false
    $notOneFlag = $false

    # For each module version
    foreach ($module in $PSGetVer) {
        # Check if version is different from "1.0.0.1"
        if ($module.Version -ne "1.0.0.1") {
            $notOneFlag = $true
            break
        }
    }

    # If any version is different from "1.0.0.1", import the latest one
    if ($notOneFlag) {
        # Sort by version in descending order and select the first one (the latest)
        $latestModule = $PSGetVer | Sort-Object Version -Descending | Select-Object -First 1
        # Import the latest version
        Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version
    }
    else {
        switch (Test-IsAdmin) {
            $false {
                Write-AuditLog "PowerShellGet is version 1.0.0.1. Please run this once as an administrator, to update PowershellGet." -Severity Error
                throw "Elevation required to update PowerShellGet!"
            }
            Default {
                Write-AuditLog "You have sufficient privileges to install to the PowershellGet"
            }
        }
        try {
            Write-AuditLog "Install the latest version of PowershellGet from the PSGallery?" -Severity Warning
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
            Install-Module PowerShellGet -AllowClobber -Force -ErrorAction Stop
            Write-AuditLog "PowerShellGet was installed successfully!"
            $PSGetVer = Get-Module -Name PowerShellGet -ListAvailable
            $latestModule = $PSGetVer | Sort-Object Version -Descending | Select-Object -First 1
            Import-Module -Name $latestModule.Name -RequiredVersion $latestModule.Version -ErrorAction Stop
        }
        catch {
            throw $_.Exception
        }
    }
    # End Region PowershellGet Install
    if ($Scope -eq "AllUsers") {
        switch (Test-IsAdmin) {
            $false {
                Write-AuditLog "You must be an administrator to install in the `'AllUsers`' scope." -Severity Error
                Write-AuditLog "If you intended to install the module only for this user, select the `'CurrentUser`' scope." -Severity Error
                throw "Elevation required for `'AllUsers`' scope"
            }
            Default {
                Write-AuditLog "You have sufficient privileges to install to the `'AllUsers`' scope."
            }
        }
    }
    if ($PSCmdlet.ParameterSetName -eq "Public") {
        $modules = $PublicModuleNames
        $versions = $PublicRequiredVersions
    }
    elseif ($PSCmdlet.ParameterSetName -eq "Prerelease") {
        $modules = $PrereleaseModuleNames
        $versions = $PrereleaseRequiredVersions
        $prerelease = $true
    }
    foreach ($module in $modules) {
        $name = $module
        $version = $versions[$modules.IndexOf($module)]
        $installedModule = Get-Module -Name $name -ListAvailable
        switch (($null -eq $ImportModuleNames)) {
            $false {
                $SelectiveImports = $ImportModuleNames | Where-Object { $_ -match $name }
                Write-AuditLog "Attempting to selecively install module/s:"
            }
            Default {
                $SelectiveImports = $null
                Write-AuditLog "Selective imports were not specified. All functions and commands will be imported."
            }
        }
        # Get Module Object
        switch ($prerelease) {
            $true {
                $message = "The PreRelease module $name version $version is not installed. Would you like to install it?"
                $throwmsg = "You must install the PreRelease module $name version $version to continue"
            }
            Default {
                $message = "The $name module version $version is not installed. Would you like to install it?"
                $throwmsg = "You must install the $name module version $version to continue."
            }
        }
        if (!$installedModule) {
            # Install Required Module
            Write-AuditLog $message -Severity Warning
            try {
                Write-AuditLog "Installing $name module/s version $version -AllowPrerelease:$prerelease."
                $SaveVerbosePreference = $script:VerbosePreference
                Install-Module $name -Scope $Scope -RequiredVersion $version -AllowPrerelease:$prerelease -ErrorAction Stop -Verbose:$false
                $script:VerbosePreference = $SaveVerbosePreference
                Write-AuditLog "$name module successfully installed!"
                if ($SelectiveImports) {
                    foreach ($Mod in $SelectiveImports) {
                        $name = $Mod
                        Write-AuditLog "Selectively importing the $name module."
                        $SaveVerbosePreference = $script:VerbosePreference
                        Import-Module $name -ErrorAction Stop -Verbose:$false
                        $script:VerbosePreference = $SaveVerbosePreference
                        Write-AuditLog "Successfully imported the $name module."
                    }
                }
                else {
                    Write-AuditLog "Importing the $name module."
                    $SaveVerbosePreference = $script:VerbosePreference
                    Import-Module $name -ErrorAction Stop -Verbose:$false
                    $script:VerbosePreference = $SaveVerbosePreference
                    Write-AuditLog "Successfully imported the $name module."
                }
            }
            catch {
                Write-AuditLog $throwmsg -Severity Error
                throw $_.Exception
            }
        }
        else {
            try {
                if ($SelectiveImports) {
                    foreach ($Mod in $SelectiveImports) {
                        $name = $Mod
                        Write-AuditLog "The $name module was found to be installed."
                        Write-AuditLog "Selectively importing the $name module."
                        $SaveVerbosePreference = $script:VerbosePreference
                        Import-Module $name -ErrorAction Stop -Verbose:$false
                        $script:VerbosePreference = $SaveVerbosePreference
                        Write-AuditLog "Successfully imported the $name module."
                        Write-AuditLog -EndFunction
                    }
                }
                else {
                    Write-AuditLog "The $name module was found to be installed."
                    Write-AuditLog "Importing the $name module."
                    $SaveVerbosePreference = $script:VerbosePreference
                    Import-Module $name -ErrorAction Stop -Verbose:$false
                    $script:VerbosePreference = $SaveVerbosePreference
                    Write-AuditLog "Successfully imported the $name module."
                    write-auditlog -EndFunction
                }
            }
            catch {
                Write-AuditLog $throwmsg -Severity Error
                throw $_.Exception
            }
        }
    }
}
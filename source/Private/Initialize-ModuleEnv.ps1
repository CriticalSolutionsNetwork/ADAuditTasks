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
    The scope of the module installation. Possible values are "AllUsers" and "CurrentUser".
    .PARAMETER ImportModuleNames
    The specific modules you'd like to import from the installed package to streamline imports.
    Example "Microsoft.Graph.Authentication","Microsoft.Graph.Identity.SignIns"
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
    if ($global:MaximumFunctionCount -lt 8192) {
        $global:MaximumFunctionCount = 8192
    }
    if ($Scope -eq "AllUsers") {
        switch (Test-IsAdmin) {
            $false {
                $Script:LogString += Write-AuditLog -Message "You must be an administrator to install in the `'AllUsers`' scope." -Severity Error
                $Script:LogString += Write-AuditLog -Message "If you intended to install the module only for this user, select the `'CurrentUser`' scope." -Severity Error
                throw "Elevation required for `'AllUsers`' scope"
            }
            Default {
                $Script:LogString += Write-AuditLog -Message "You have sufficient privileges to install to the `'AllUsers`' scope."
            }
        }
    }
    if ($PSCmdlet.ParameterSetName -eq "Public") {
        $modules = $PublicModuleNames
        $versions = $PublicRequiredVersions
        $prerelease = $false
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
                $Script:LogString += Write-AuditLog -Message "Attempting to selecively install module/s:"
            }
            Default {
                $SelectiveImports = $null
                $Script:LogString += Write-AuditLog -Message "Selective imports were not specified. All functions and commands will be imported."
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
            $Script:LogString += Write-AuditLog -Message $message -Severity Warning
            try {
                $Script:LogString += Write-AuditLog -Message "Installing $name module/s version $version -AllowPrerelease:$prerelease."
                $SaveVerbosePreference = $script:VerbosePreference
                Install-Module $name -Scope $Scope -RequiredVersion $version -AllowPrerelease:$prerelease -ErrorAction Stop -Verbose:$false
                $script:VerbosePreference = $SaveVerbosePreference
                $Script:LogString += Write-AuditLog -Message "$name module successfully installed!"
                if ($SelectiveImports) {
                    foreach ($Mod in $SelectiveImports) {
                        $name = $Mod
                        $Script:LogString += Write-AuditLog -Message "Selectively importing the $name module."
                        $SaveVerbosePreference = $script:VerbosePreference
                        Import-Module $name -ErrorAction Stop -Verbose:$false
                        $script:VerbosePreference = $SaveVerbosePreference
                        $Script:LogString += Write-AuditLog -Message "Successfully imported the $name module."
                    }
                }
                else {
                    $Script:LogString += Write-AuditLog -Message "Importing the $name module."
                    $SaveVerbosePreference = $script:VerbosePreference
                    Import-Module $name -ErrorAction Stop -Verbose:$false
                    $script:VerbosePreference = $SaveVerbosePreference
                    $Script:LogString += Write-AuditLog -Message "Successfully imported the $name module."
                }
            }
            catch {
                $Script:LogString += Write-AuditLog -Message $throwmsg -Severity Error
                throw $_.Exception
            }
        }
        else {
            try {
                if ($SelectiveImports) {
                    foreach ($Mod in $SelectiveImports) {
                        $name = $Mod
                        $Script:LogString += Write-AuditLog -Message "The $name module was found to be installed."
                        $Script:LogString += Write-AuditLog -Message "Selectively importing the $name module."
                        $SaveVerbosePreference = $script:VerbosePreference
                        Import-Module $name -ErrorAction Stop -Verbose:$false
                        $script:VerbosePreference = $SaveVerbosePreference
                        $Script:LogString += Write-AuditLog -Message "Successfully imported the $name module."
                    }
                }
                else {
                    $Script:LogString += Write-AuditLog -Message "The $name module was found to be installed."
                    $Script:LogString += Write-AuditLog -Message "Importing the $name module."
                    $SaveVerbosePreference = $script:VerbosePreference
                    Import-Module $name -ErrorAction Stop -Verbose:$false
                    $script:VerbosePreference = $SaveVerbosePreference
                    $Script:LogString += Write-AuditLog -Message "Successfully imported the $name module."
                }
            }
            catch {
                $Script:LogString += Write-AuditLog -Message $throwmsg -Severity Error
                throw $_.Exception
            }
        }
    }
}
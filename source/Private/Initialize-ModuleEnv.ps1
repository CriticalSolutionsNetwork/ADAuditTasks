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
    .EXAMPLE
    Initialize-ModuleEnv -PublicModuleNames "AzureRM", "Az" -PublicRequiredVersions "6.7.0", "4.4.0" -Scope AllUsers

    This example installs the AzureRM and Az modules in the AllUsers scope with the specified versions.
    .EXAMPLE
    $params1 = @{
        $PublicModuleNames      = "Microsoft.Graph", "Pester"
        $PublicRequiredVersions = "2.1.5", "4.10.1"
        Scope                   = "CurrentUser"
    }
    Initialize-ModuleEnv @params1

    This example installs Microsoft.Graph and Pester Modules in the CurrentUser scope with the specified versions.
    .EXAMPLE
    $params2 = @{
        $PrereleaseModuleNames      = "Sampler", "Pester"
        $PrereleaseRequiredVersions = "2.1.5", "4.10.1"
        Scope                       = "CurrentUser"
    }
    Initialize-ModuleEnv @params1
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
        [string]$Scope
    )
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
        # Get Module Object
        $installedModule = Get-Module -Name $name -ListAvailable -RequiredVersion $version -AllowPrerelease:$prerelease

        if (!$installedModule) {
            switch ($prerelease) {
                $true {
                    $message = "The PreRelease module $name version $version is not installed. Would you like to install it?"
                    $throwmsg = "You must install the PreRelease module $name version $version to continue"
                }
                Default {
                    $message = "The $name module version $version is not installed. Would you like to install it?"
                    $throwmsg = "You must install the $name module version $version to continue"
                }
            }
            # Install Required Module
            $install = Read-Host -Prompt $message
            if ($install -eq "y" -or $install -eq "yes") {
                try {
                    Install-Module $name -Scope $Scope -RequiredVersion $version -AllowPrerelease:$prerelease -ErrorAction Stop
                    Import-Module $name -ErrorAction Stop
                }
                catch {
                    $Script:ADLogString += Write-AuditLog -Message $throwmsg -Severity Error
                    throw
                }
            }
            else {
                $Script:ADLogString += Write-AuditLog -Message "The $name module is required to continue" -Severity Error
                throw "The $name module is required to continue"
            }
        }
    }
}
#Region './Private/Get-SamplerProjectModuleManifest.ps1' 0

<#
    .SYNOPSIS
        Gets the path to the Module manifest in the source folder.

    .DESCRIPTION
        This command finds the Module Manifest of the current Sampler project,
        regardless of the name of the source folder (src, source, or MyProjectName).
        It looks for psd1 that are not build.psd1 or analyzersettings, 1 folder under
        the $BuildRoot, and where a property ModuleVersion is set.

        This allows to deduct the Module name's from that module Manifest.

    .PARAMETER BuildRoot
        Root folder where the build is called, usually the root of the repository.

    .EXAMPLE
        Get-SamplerProjectModuleManifest -BuildRoot .

#>
function Get-SamplerProjectModuleManifest
{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    $excludeFiles = @(
        'build.psd1'
        'analyzersettings.psd1'
    )

    $moduleManifestItem = Get-ChildItem -Path "$BuildRoot\*\*.psd1" -Exclude $excludeFiles |
            Where-Object -FilterScript {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(Test-ModuleManifest -Path $_.FullName -ErrorAction 'SilentlyContinue' ).Version
            }

    if ($moduleManifestItem.Count -gt 1)
    {
        throw ("Found more than one project folder containing a module manifest, please make sure there are only one; `n Manifest: {0}" -f ($moduleManifestItem.FullName -join "`n Manifest: "))
    }
    else
    {
        return $moduleManifestItem
    }
}
#EndRegion './Private/Get-SamplerProjectModuleManifest.ps1' 52
#Region './Private/New-SamplerXmlJaCoCoCounter.ps1' 0

<#
    .SYNOPSIS
        Returns a new JaCoCo XML counter node with the specified covered and missed
        attributes.

    .DESCRIPTION
        Returns a new JaCoCo XML counter node with the specified covered and missed
        attributes.

    .PARAMETER XmlNode
        The XML node that the element should be part appended to as a child.

    .PARAMETER CounterType
        The JaCoCo counter type.

    .PARAMETER Covered
        The number of covered lines to be used as the value for the covered XML
        attribute.

    .PARAMETER Missed
        The number of missed lines to be used as the value for the missed XML
        attribute.

    .PARAMETER PassThru
        Returns the element that was created.

    .EXAMPLE
        New-SamplerXmlJaCoCoCounter -XmlDocument $myXml -CounterType 'CLASS' -Covered 1 -Missed 2
#>
function New-SamplerXmlJaCoCoCounter
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([System.Xml.XmlElement])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlNode]
        $XmlNode,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CLASS', 'LINE', 'METHOD', 'INSTRUCTION')]
        [System.String]
        $CounterType,

        [Parameter()]
        [System.UInt32]
        $Covered = 0,

        [Parameter()]
        [System.UInt32]
        $Missed = 0,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru

    )

    $xmlElement = $XmlNode.OwnerDocument.CreateElement('counter')

    $xmlElement.SetAttribute('type', $CounterType)
    $xmlElement.SetAttribute('missed', $Missed)
    $xmlElement.SetAttribute('covered', $Covered)

    $XmlNode.AppendChild($xmlElement) | Out-Null

    if ($PassThru.IsPresent)
    {
        return $xmlElement
    }
}
#EndRegion './Private/New-SamplerXmlJaCoCoCounter.ps1' 74
#Region './Public/Add-Sample.ps1' 0

<#
    .SYNOPSIS
        Adding code elements (function, enum, class, DSC Resource, tests...) to a module's source.

    .DESCRIPTION
        Add-Sample is an helper function to invoke a plaster template built-in the Sampler module.
        With this function you can bootstrap your module project by adding classes, functions and
        associated tests, examples and configuration elements.

    .PARAMETER Sample
        Specifies a sample component based on the Plaster templates embedded with this module.
        The available types of module elements are:
            - Classes: A sample of 4 classes with inheritence and how to manage the orders to avoid parsing errors.
            - ClassResource: A Class-Based DSC Resources showing some best practices including tests, Reasons, localized strings.
            - Composite: A DSC Composite Resource (a configuration block) packaged the right way to make sure it's visible by Get-DscResource.
            - Enum: An example of a simple Enum.
            - MofResource: A sample of a MOF-Based DSC Resource following the DSC Community practices.
            - PrivateFunction: A sample of a Private function (not exported from the module) and its test.
            - PublicCallPrivateFunctions: A sample of 2 functions where the exported one (public) calls the private one, with the tests.
            - PublicFunction: A sample public function and its test.

    .PARAMETER DestinationPath
        Destination of your module source root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files.

    .EXAMPLE
        C:\src\MyModule> Add-Sample -Sample PublicFunction -PublicFunctionName Get-MyStuff

    .NOTES
        This module requires and uses Plaster.
#>
function Add-Sample
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter()]
        # Add a sample component based on the Plaster templates embedded with this module.
        [ValidateSet(
            'Classes',
            'ClassFolderResource',
            'ClassResource',
            'Composite',
            'Enum',
            'Examples',
            'GithubConfig',
            'GCPackage',
            'HelperSubModules',
            'MofResource',
            'PrivateFunction',
            'PublicCallPrivateFunctions',
            'PublicFunction',
            'VscodeConfig',
            'ChocolateyPackage'
        )]
        [string]
        $Sample,

        [Parameter()]
        [System.String]
        $DestinationPath = '.'
    )

    dynamicparam
    {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Sample)
        {
            return
        }

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

        $previousErrorActionPreference = $ErrorActionPreference

        try
        {
            <#
                Let's convert non-terminating errors in this function to terminating so we
                catch and format the error message as a warning.
            #>
            $ErrorActionPreference = 'Stop'

            <#
                The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
                since we are only evaluating the parameters in the manifest - no need for EvaluateConditionAttribute as we
                are not building up multiple parameter sets.  And no need for EvaluateAttributeValue since we are only
                grabbing the parameter's value which is static.
            #>
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)

            if (-not (Test-Path -LiteralPath $templateAbsolutePath -PathType 'Container'))
            {
                throw ("Can't find plaster template at {0}." -f $templateAbsolutePath)
            }

            $plasterModule = Get-Module -Name 'Plaster'

            <#
                Load manifest file using culture lookup (using Plaster module private function GetPlasterManifestPathForCulture).
                This is the current function that is called:
                https://github.com/PowerShellOrg/Plaster/blob/0506a26ffb532a335a4e62a8da31d9ca0177ae2a/src/InvokePlaster.ps1#L1478
            #>
            $manifestPath = & $plasterModule {
                param
                (
                    [Parameter()]
                    [System.String]
                    $templateAbsolutePath,

                    [Parameter()]
                    [System.String]
                    $Culture
                )

                GetPlasterManifestPathForCulture -TemplatePath $templateAbsolutePath -Culture $Culture
            } $templateAbsolutePath $PSCulture

            if (($null -eq $manifestPath) -or (-not (Test-Path -Path $manifestPath)))
            {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            <#
                The user-defined parameters in the Plaster manifest are converted to dynamic parameters
                which allows the user to provide the parameters via the command line.
                This enables non-interactive use cases.
            #>
            foreach ($node in $manifest.plasterManifest.Parameters.ChildNodes)
            {
                if ($node -isnot [System.Xml.XmlElement])
                {
                    continue
                }

                $name = $node.name
                $type = $node.type

                if ($node.prompt)
                {
                    $prompt = $node.prompt
                }
                else
                {
                    $prompt = "Missing Parameter $name"
                }

                if (-not $name -or -not $type)
                {
                    continue
                }

                # Configure ParameterAttribute and add to attr collection.
                $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type)
                {
                    'text|user-fullname|user-email'
                    {
                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, [System.String], $attributeCollection)

                        break
                    }

                    'choice|multichoice'
                    {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object -TypeName System.String[] -ArgumentList $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes)
                        {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $setValues
                        $attributeCollection.Add($validateSetAttr)

                        if ($type -eq 'multichoice')
                        {
                            $type = [System.String[]]
                        }
                        else
                        {
                            $type = [System.String]
                        }

                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, $type, $attributeCollection)

                        break
                    }

                    default
                    {
                        throw "Unrecognized Parameter Type $type for attribute $name."
                    }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch
        {
            Write-Warning "Error processing Dynamic Parameters. $($_.Exception.Message)"
        }
        finally
        {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $paramDictionary
    }

    end
    {
        # Clone the the bound parameters.
        $plasterParameter = @{} + $PSBoundParameters

        $null = $plasterParameter.Remove('Sample')

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

        $plasterParameter.Add('TemplatePath', $templatePath)

        if (-not $plasterParameter.ContainsKey('DestinationPath'))
        {
            $plasterParameter['DestinationPath'] = $DestinationPath
        }

        Invoke-Plaster @plasterParameter
    }
}
#EndRegion './Public/Add-Sample.ps1' 246
#Region './Public/Convert-SamplerHashtableToString.ps1' 0

<#
    .SYNOPSIS
        Converts an Hashtable to its string representation, recursively.

    .DESCRIPTION
        Convert an Hashtable to a string representation.
        For instance, this hashtable:
        @{a=1;b=2; c=3; d=@{dd='abcd'}}
        Becomes:
        a=1; b=2; c=3; d={dd=abcd}

    .PARAMETER Hashtable
        Hashtable to convert to string.

    .EXAMPLE
        Convert-SamplerhashtableToString -Hashtable @{a=1;b=2; c=3; d=@{dd='abcd'}}

    .NOTES
        This command is not specific to Sampler projects, but is named that way
        to avoid conflict with other modules.
#>
function Convert-SamplerHashtableToString
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $Hashtable
    )
    $values = @()
    foreach ($pair in $Hashtable.GetEnumerator())
    {
        if ($pair.Value -is [System.Array])
        {
            $str = "$($pair.Key)=($($pair.Value -join ","))"
        }
        elseif ($pair.Value -is [System.Collections.Hashtable])
        {
            $str = "$($pair.Key)={$(Convert-SamplerHashtableToString -Hashtable $pair.Value)}"
        }
        else
        {
            $str = "$($pair.Key)=$($pair.Value)"
        }
        $values += $str
    }

    [array]::Sort($values)
    return ($values -join "; ")
}
#EndRegion './Public/Convert-SamplerHashtableToString.ps1' 52
#Region './Public/Get-BuildVersion.ps1' 0

<#
    .SYNOPSIS
        Calculates or retrieves the version of the Repository.

    .DESCRIPTION
        Attempts to retrieve the version associated with the repository or the module within
        the repository.
        If the Version is not provided, the preferred way is to use GitVersion if available,
        but alternatively it will locate a module manifest in the source folder and read its version.

    .PARAMETER ModuleManifestPath
        Path to the Module Manifest that should determine the version if GitVersion is not available.

    .PARAMETER ModuleVersion
        Provide the Version to be splitted and do not rely on GitVersion or the Module's manifest.

    .EXAMPLE
        Get-BuildVersion -ModuleManifestPath source\MyModule.psd1

#>
function Get-BuildVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        $ModuleManifestPath,

        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    if ([System.String]::IsNullOrEmpty($ModuleVersion))
    {
        Write-Verbose -Message 'Module version is not determined yet. Evaluating methods to get new module version.'

        $gitVersionAvailable = Get-Command -Name 'gitversion' -ErrorAction 'SilentlyContinue'
        $donetGitversionAvailable = Get-Command -Name 'dotnet-gitversion' -ErrorAction 'SilentlyContinue'

        # If dotnet-gitversion is available and gitversion is not, alias it to gitversion.
        if ($donetGitversionAvailable -and -not $gitVersionAvailable)
        {
            New-Alias -Name 'gitversion' -Value 'dotnet-gitversion' -Scope 'Script' -ErrorAction 'SilentlyContinue'
        }

        if ($gitVersionAvailable -or $donetGitversionAvailable)
        {
            Write-Verbose -Message 'Using the version from GitVersion.'

            $ModuleVersion = (gitversion | ConvertFrom-Json -ErrorAction 'Stop').NuGetVersionV2
        }
        elseif (-not [System.String]::IsNullOrEmpty($ModuleManifestPath))
        {
            Write-Verbose -Message (
                "GitVersion is not installed. Trying to use the version from module manifest in path '{0}'." -f $ModuleManifestPath
            )

            $moduleInfo = Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'

            $ModuleVersion = $moduleInfo.ModuleVersion

            if ($moduleInfo.PrivateData.PSData.Prerelease)
            {
                $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
            }
        }
        else
        {
            throw 'Could not determine the module version because neither GitVersion or a module manifest was present. Please provide the ModuleVersion parameter manually in the file build.yaml with the property ''SemVer:''.'
        }
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
#EndRegion './Public/Get-BuildVersion.ps1' 85
#Region './Public/Get-BuiltModuleVersion.ps1' 0

<#
    .SYNOPSIS
        Get the module version from the module built by Sampler.

    .DESCRIPTION
        Will read the ModuleVersion and PrivateData.PSData.Prerelease tag of the Module Manifest
        that has been built by Sampler, by looking into the OutputDirectory where the Project's
        Module should have been built.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .EXAMPLE
        Get-BuiltModuleVersion -OutputDirectory 'output' -ProjectName Sampler

#>
function Get-BuiltModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory
    )

    $BuiltModuleManifestPath = Get-SamplerBuiltModuleManifest @PSBoundParameters

    Write-Verbose -Message (
        "Get the module version from module manifest in path '{0}'." -f $BuiltModuleManifestPath
    )

    $moduleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifestPath -ErrorAction 'Stop'

    $ModuleVersion = $moduleInfo.ModuleVersion

    if ($moduleInfo.PrivateData.PSData.Prerelease)
    {
        $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
#EndRegion './Public/Get-BuiltModuleVersion.ps1' 83
#Region './Public/Get-ClassBasedResourceName.ps1' 0

<#
    .SYNOPSIS
        Get the Names of the Class-based DSC Resources defined in a file using AST.

    .DESCRIPTION
        This command returns all Class-based Resource Names in a file,
        by parsing the file and looking for classes with the [DscResource()] attribute.

        For MOF-based DSC Resources, look at the `Get-MofSchemaName` function.

    .PARAMETER Path
        Path of the file to parse and search the Class-Based DSC Resources.

    .EXAMPLE
        Get-ClassBasedResourceName -Path source/Classes/MyDscResource.ps1

        Get-ClassBasedResourceName -Path (Join-Path -Path (Get-Module MyResourceModule).ModuleBase -ChildPath (Get-Module MyResourceModule).RootModule)

#>
function Get-ClassBasedResourceName
{
   [CmdletBinding()]
   [OutputType([String[]])]
   param
   (
       [Parameter(Mandatory = $true)]
       [Alias('FilePath')]
       [System.String]
       $Path
   )

   $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

   $classDefinition = $ast.FindAll(
       {
           ($args[0].GetType().Name -like "TypeDefinitionAst") -and `
           ($args[0].Attributes.TypeName.Name -contains 'DscResource')
       },
       $true
   )

   return $classDefinition.Name

}
#EndRegion './Public/Get-ClassBasedResourceName.ps1' 46
#Region './Public/Get-CodeCoverageThreshold.ps1' 0

<#
    .SYNOPSIS
        Gets the CodeCoverageThreshod from Runtime parameter or from BuildInfo.

    .DESCRIPTION
        This function will override the CodeCoverageThreshold by the value
        provided at runtime if any.

    .PARAMETER RuntimeCodeCoverageThreshold
        Runtime value for the Pester CodeCoverageThreshold (can be $null).

    .PARAMETER BuildInfo
        BuildInfo object as defined by the Build.yml.

    .EXAMPLE
        Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold 0

#>
function Get-CodeCoverageThreshold
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        [AllowNull()]
        $RuntimeCodeCoverageThreshold,

        [Parameter()]
        [PSObject]
        $BuildInfo
    )

    # If no codeCoverageThreshold configured at runtime, look for BuildInfo settings.
    if ([String]::IsNullOrEmpty($RuntimeCodeCoverageThreshold))
    {
        if ($BuildInfo -and $BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageThreshold'))
        {
            $codeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold

            Write-Debug -Message "Loaded Code Coverage Threshold from Config file: $codeCoverageThreshold %."
        }
        elseif ($BuildInfo -and $BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('Configuration') -and $BuildInfo.Pester.Configuration.CodeCoverage.CoveragePercentTarget)
        {
            $codeCoverageThreshold = $BuildInfo.Pester.Configuration.CodeCoverage.CoveragePercentTarget

            Write-Debug -Message "Loaded Code Coverage Threshold from Config file in Pester advanced configuration: $codeCoverageThreshold %."
        }
        else
        {
            $codeCoverageThreshold = 0

            Write-Debug -Message "No code coverage threshold value found (param nor config), using the default value."
        }
    }
    else
    {
        $codeCoverageThreshold = [int] $RuntimeCodeCoverageThreshold

        Write-Debug -Message "Loading CodeCoverage Threshold from Parameter ($codeCoverageThreshold %)."
    }

    return $codeCoverageThreshold
}
#EndRegion './Public/Get-CodeCoverageThreshold.ps1' 67
#Region './Public/Get-MofSchemaName.ps1' 0

<#
    .SYNOPSIS
        Gets the Name and Friendly Name of MOF-Based resources from their Schemas.

    .DESCRIPTION
        This function looks within a DSC resource's .MOF schema to find the name and
        friendly name of the class.

    .PARAMETER Path
        Path to the DSC Resource Schema MOF.

    .EXAMPLE
        Get-MofSchemaName -Path Source/DSCResources/MyResource/MyResource.schema.mof

#>
function Get-MofSchemaName
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $Path
    )

    begin
    {
        $temporaryPath = $null

        # Determine the correct $env:TEMP drive
        switch ($true)
        {
            (-not (Test-Path -Path variable:IsWindows) -or $IsWindows)
            {
                # Windows PowerShell or PowerShell 6+
                $temporaryPath = $env:TEMP
            }

            $IsMacOS
            {
                $temporaryPath = $env:TMPDIR

                throw 'NotImplemented: Currently there is an issue using the type [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache] on macOS. See issue https://github.com/PowerShell/PowerShell/issues/5970 and issue https://github.com/PowerShell/MMI/issues/33.'
            }

            $IsLinux
            {
                $temporaryPath = '/tmp'
            }

            default
            {
                throw 'Cannot set the temporary path. Unknown operating system.'
            }
        }

        $tempFilePath = Join-Path -Path $temporaryPath -ChildPath "DscMofHelper_$((New-Guid).Guid).tmp"
    }

    process
    {
        #region Workaround for OMI_BaseResource inheritance not resolving.
        $rawContent = (Get-Content -Path $Path -Raw) -replace '\s*:\s*OMI_BaseResource'
        Set-Content -LiteralPath $tempFilePath -Value $rawContent -ErrorAction 'Stop'

        # .NET methods don't like PowerShell drives
        $tempFilePath = Convert-Path -Path $tempFilePath

        #endregion

        try
        {
            $exceptionCollection = [System.Collections.ObjectModel.Collection[System.Exception]]::new()
            $moduleInfo = [System.Tuple]::Create('Module', [System.Version] '1.0.0')

            $class = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses(
                $tempFilePath, $moduleInfo, $exceptionCollection
            )

            if ($exceptionCollection.Count -gt 0)
            {
                throw $exceptionCollection
            }
        }
        catch
        {
            Remove-Item -LiteralPath $tempFilePath -Force
            throw "Failed to import classes from file $Path. Error $_"
        }

        <#
            For most efficiency, we re-use the same temp file.
            We need to be sure that the file is empty before the next import.
            If no, we risk to import the same class twice.
        #>
        Set-Content -LiteralPath $tempFilePath -Value ''

        return @{
            Name = $class.CimClassName
            FriendlyName = ($class.Cimclassqualifiers | Where-Object -FilterScript { $_.Name -eq 'FriendlyName' }).Value
        }
    }

    end
    {
        Remove-Item -LiteralPath $tempFilePath -Force
    }
}
#EndRegion './Public/Get-MofSchemaName.ps1' 114
#Region './Public/Get-OperatingSystemShortName.ps1' 0

<#
    .SYNOPSIS
        Returns the Platform name.

    .DESCRIPTION
        Gets whether the platform is Windows, Linux or MacOS.

    .EXAMPLE
        Get-OperatingSystemShortName # no Parameter needed

    .NOTES
        General notes
#>
function Get-OperatingSystemShortName
{
    [CmdletBinding()]
    param ()

    $osShortName = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5)
    {
        'Windows'
    }
    elseif ($IsMacOS)
    {
        'MacOS'
    }
    else
    {
        'Linux'
    }

    return $osShortName
}
#EndRegion './Public/Get-OperatingSystemShortName.ps1' 35
#Region './Public/Get-PesterOutputFileFileName.ps1' 0

<#
    .SYNOPSIS
        Gets a descriptive file name to be used as Pester Output file name.

    .DESCRIPTION
        Creates a file name to be used as Pester Output xml file composed like so:
        "${ProjectName}_v${ModuleVersion}.${OsShortName}.${PowerShellVersion}.xml"

    .PARAMETER ProjectName
        Name of the Project or module being built.

    .PARAMETER ModuleVersion
        Module Version currently defined (including pre-release but without the metadata).

    .PARAMETER OsShortName
        Platform name either Windows, Linux, or MacOS.

    .PARAMETER PowerShellVersion
        Version of PowerShell the tests have been running on.

    .EXAMPLE
        Get-PesterOutputFileFileName -ProjectName 'Sampler' -ModuleVersion 0.110.4-preview001 -OsShortName Windows -PowerShellVersion 5.1

    .NOTES
        General notes
#>
function Get-PesterOutputFileFileName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OsShortName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PowerShellVersion
    )

    return '{0}_v{1}.{2}.{3}.xml' -f $ProjectName, $ModuleVersion, $OsShortName, $PowerShellVersion
}
#EndRegion './Public/Get-PesterOutputFileFileName.ps1' 51
#Region './Public/Get-Psm1SchemaName.ps1' 0
<#
    .SYNOPSIS
        Gets the Name of composite DSC resources from their *.schema.psm1 file.

    .DESCRIPTION
        This function looks within a composite DSC resource's *.schema.psm1 file
        to find the name and friendly name of the class.

    .PARAMETER Path
        Path to the DSC Resource *.schema.psm1 file.

    .EXAMPLE
        Get-Psm1SchemaName -Path Source/DSCResources/MyCompositeResource/MyCompositeResource.schema.psm1

#>

function Get-Psm1SchemaName
{
    [CmdletBinding()]
    [OutputType([string[]])]
    param
    (
        [Parameter(
                Mandatory = $true,
                ValueFromPipeline = $true
        )]
        [System.String]
        $Path
    )

    process
    {
        $rawContent = Get-Content -Path $Path -Raw
        $parseErrors = $null
        $tokens = $null

        $ast = [System.Management.Automation.Language.Parser]::ParseInput($rawContent, [ref]$tokens, [ref]$parseErrors)
        $configurations = $ast.FindAll( { $args[0] -is [System.Management.Automation.Language.ConfigurationDefinitionAst] }, $true)

        if ($configurations.Count -ne 1)
        {
            Write-Error "It is expected to find only 1 configuration in the file '$Path' but found $($configurations.Count)"
        }
        else
        {
            Write-Verbose "Found Configuration '$($configurations[0].InstanceName)'"
            $configurations[0].InstanceName.Value
        }
    }

}
#EndRegion './Public/Get-Psm1SchemaName.ps1' 52
#Region './Public/Get-SamplerAbsolutePath.ps1' 0

<#
    .SYNOPSIS
        Gets the absolute value of a path, that can be relative to another folder
        or the current Working Directory `$PWD` or Drive.

    .DESCRIPTION
        This function will resolve the Absolute value of a path, whether it's
        potentially relative to another path, relative to the current working
        directory, or it's provided with an absolute Path.

        The Path does not need to exist, but the command will use the right
        [System.Io.Path]::DirectorySeparatorChar for the OS, and adjust the
        `..` and `.` of a path by removing parts of a path when needed.

    .PARAMETER Path
        Relative or Absolute Path to resolve, can also be $null/Empty and will
        return the RelativeTo absolute path.
        It can be Absolute but relative to the current drive: i.e. `/Windows`
        would resolve to `C:\Windows` on most Windows systems.

    .PARAMETER RelativeTo
        Path to prepend to $Path if $Path is not Absolute.
        If $RelativeTo is not absolute either, it will first be resolved
        using [System.Io.Path]::GetFullPath($RelativeTo) before
        being pre-pended to $Path.

    .EXAMPLE
        Get-SamplerAbsolutePath -Path '/src' -RelativeTo 'C:\Windows'
        # C:\src

    .EXAMPLE
        Get-SamplerAbsolutePath -Path 'MySubFolder' -RelativeTo '/src'
        # C:\src\MySubFolder

    .NOTES
        When the root drive is omitted on Windows, the path is not considered absolute.
        `Split-Path -IsAbsolute -Path '/src/`
        # $false
#>
function Get-SamplerAbsolutePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $RelativeTo
    )

    if (-not [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not rooted it's a relative path
        $RelativeTo = Join-Path -Path ([System.Io.Path]::GetFullPath($PWD.Path)) -ChildPath $RelativeTo
    }
    elseif (-not (Split-Path -IsAbsolute -Path $RelativeTo) -and [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $RelativeTo = Join-Path -Path $CurrentDriveRoot -ChildPath $RelativeTo
    }

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $RelativeTo = [System.io.Path]::GetFullPath($RelativeTo)
    }

    if (-not [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not rooted it's a relative path (relative to $RelativeTo)
        $Path = Join-Path -Path $RelativeTo -ChildPath $Path
    }
    elseif (-not (Split-Path -IsAbsolute -Path $Path) -and [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $Path = Join-Path -Path $CurrentDriveRoot -ChildPath $Path
    }
    # Else The Path is Absolute

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $Path = [System.io.Path]::GetFullPath($Path)
    }

    return $Path
}
#EndRegion './Public/Get-SamplerAbsolutePath.ps1' 98
#Region './Public/Get-SamplerBuiltModuleBase.ps1' 0

<#
    .SYNOPSIS
        Get the ModuleBase of a module built with Sampler (directory where the module
        manifest is).

    .DESCRIPTION
        Based on a project's configuration of OutputDirectory, BuiltModuleSubdirectory,
        ModuleName and whether the built module is within a VersionedOutputDirectory;
        this function will resolve the expected ModuleBase of that Module.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleVersion
        Allows to specify a specific ModuleVersion to search the ModuleBase if known.
        If the ModuleVersion is not known but the VersionedOutputDirectory is set to $true,
        a wildcard (*) will be used so that the path can be resolved by Get-Item or similar commands.

    .EXAMPLE
        Get-SamplerBuiltModuleBase -OutputDirectory C:\src\output -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion 3.1.2-preview001
        # C:\src\output\Module\stuff\3.1.2

#>
function Get-SamplerBuiltModuleBase
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [ValidateNotNull()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [System.String]
        $ModuleVersion = '*'
    )

    $BuiltModuleOutputPath = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory
    $BuiltModulePath = Get-SamplerAbsolutePath -Path $ModuleName -RelativeTo $BuiltModuleOutputPath

    if ($VersionedOutputDirectory -or ($PSBoundParameters.ContainsKey('ModuleVersion') -and $ModuleVersion -ne '*'))
    {
        if ($ModuleVersion -eq '*' -or [System.String]::IsNullOrEmpty($ModuleVersion))
        {
            $ModuleVersion = '*'
        }
        else
        {
            $ModuleVersion = (Split-ModuleVersion -ModuleVersion $ModuleVersion).Version
        }

        $BuiltModuleBase = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $BuiltModulePath
    }
    else
    {
        $BuiltModuleBase = $BuiltModulePath
    }

    return $BuiltModuleBase
}
#EndRegion './Public/Get-SamplerBuiltModuleBase.ps1' 95
#Region './Public/Get-SamplerBuiltModuleManifest.ps1' 0

<#
    .SYNOPSIS
        Get the module manifest from a module built by Sampler.

    .DESCRIPTION
        Based on a project's OutputDirectory, BuiltModuleSubdirectory,
        ModuleName and whether the built module is within a VersionedOutputDirectory;
        this function will resolve the expected ModuleManifest of that Module.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleVersion
        Allows to specify a specific ModuleVersion to search the ModuleBase if known.
        If the ModuleVersion is not known but the VersionedOutputDirectory is set to $true,
        a wildcard (*) will be used so that the path can be resolved by Get-Item or similar commands.

    .EXAMPLE
        Get-SamplerBuiltModuleManifest -OutputDirectory C:\src\output -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion 3.1.2-preview001
        # C:\src\output\Module\stuff\3.1.2\stuff.psd1

    .NOTES
        See Get-SamplerBuiltModuleBase as this command only extrapolates the Manifest file from the
        Build module base, using the ModuleName parameter.
#>
function Get-SamplerBuiltModuleManifest
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [ValidateNotNull()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [System.String]
        $ModuleVersion = '*'
    )

    $BuiltModuleBase = Get-SamplerBuiltModuleBase @PSBoundParameters

    Get-SamplerAbsolutePath -Path ('{0}.psd1' -f $ModuleName) -RelativeTo $BuiltModuleBase
}
#EndRegion './Public/Get-SamplerBuiltModuleManifest.ps1' 78
#Region './Public/Get-SamplerCodeCoverageOutputFile.ps1' 0

<#
    .SYNOPSIS
        Resolves the CodeCoverage output file path from the project's BuildInfo.

    .DESCRIPTION
        When the Pester CodeCoverageOutputFile is configured in the
        buildinfo (aka Build.yml), this function will expand the path
        (if it contains variables), and resolve to it's absolute path if needed.

    .PARAMETER BuildInfo
        The BuildInfo object represented in the Build.yml.

    .PARAMETER PesterOutputFolder
        The Pester output folder (that can be overridden at runtime).

    .EXAMPLE
        Get-SamplerCodeCoverageOutputFile -BuildInfo $buildInfo -PesterOuputFolder 'C:\src\MyModule\Output\testResults

#>
function Get-SamplerCodeCoverageOutputFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PesterOutputFolder
    )

    $codeCoverageOutputFile = $null

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFile'))
    {
        $codeCoverageOutputFile = $ExecutionContext.InvokeCommand.ExpandString($BuildInfo.Pester.CodeCoverageOutputFile)
    }
    elseif ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('Configuration') -and $BuildInfo.Pester.Configuration.CodeCoverage.OutputPath)
    {
        $codeCoverageOutputFile = $ExecutionContext.InvokeCommand.ExpandString($BuildInfo.Pester.Configuration.CodeCoverage.OutputPath)
    }

    if (-not [System.String]::IsNullOrEmpty($codeCoverageOutputFile))
    {
        if (-not (Split-Path -Path $codeCoverageOutputFile -IsAbsolute))
        {
            $codeCoverageOutputFile = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputFile

            Write-Debug -Message "Absolute path to code coverage output file is $codeCoverageOutputFile."
        }
    }
    else
    {
        # Make sure to return the value as $null if it for some reason was set to an empty string.
        $codeCoverageOutputFile = $null
    }

    return $codeCoverageOutputFile
}
#EndRegion './Public/Get-SamplerCodeCoverageOutputFile.ps1' 63
#Region './Public/Get-SamplerCodeCoverageOutputFileEncoding.ps1' 0

<#
    .SYNOPSIS
        Returns the Configured encoding for Pester code coverage file from BuildInfo.

    .DESCRIPTION
        This function returns the CodeCoverageOutputFileEncoding (Pester v5+) as
        configured in the BuildInfo (build.yml).

    .PARAMETER BuildInfo
        Build Configuration object as defined in the Build.yml.

    .EXAMPLE
        Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo $buildInfo

#>
function Get-SamplerCodeCoverageOutputFileEncoding
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFileEncoding'))
    {
        $codeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding
    }
    else
    {
        $codeCoverageOutputFileEncoding = $null
    }

    return $codeCoverageOutputFileEncoding
}
#EndRegion './Public/Get-SamplerCodeCoverageOutputFileEncoding.ps1' 38
#Region './Public/Get-SamplerModuleInfo.ps1' 0

<#
    .SYNOPSIS
        Loads the PowerShell data file of a module manifest.

    .DESCRIPTION
        This function loads a psd1 (usually a module manifest), and return the hashtable.
        This implementation works around the issue where Windows PowerShell version have issues
        with the pwsh $Env:PSModulePath such as in vscode with the vscode powershell extension.

    .PARAMETER ModuleManifestPath
        Path to the ModuleManifest to load. This will not use Import-Module because the
        module may not be finished building, and might be missing some information to make
        it a valid module manifest.

    .EXAMPLE
        Get-SamplerModuleInfo -ModuleManifestPath C:\src\MyProject\output\MyProject\MyProject.psd1

#>
function Get-SamplerModuleInfo
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $isImportPowerShellDataFileAvailable = Get-Command -Name Import-PowerShellDataFile -ErrorAction SilentlyContinue

    if ($PSversionTable.PSversion.Major -le 5 -and -not $isImportPowerShellDataFileAvailable)
    {
        Import-Module -Name Microsoft.PowerShell.Utility -RequiredVersion 3.1.0.0
    }

    Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'
}
#EndRegion './Public/Get-SamplerModuleInfo.ps1' 42
#Region './Public/Get-SamplerModuleRootPath.ps1' 0

<#
    .SYNOPSIS
        Gets the absolute ModuleRoot path (the psm1) of a module.

    .DESCRIPTION
        This function reads the module manifest (.psd1) and if the ModuleRoot property
        is defined, it will resolve its absolute path based on the ModuleManifest's Path.

        If no ModuleRoot is defined, then this function will return $null.

    .PARAMETER ModuleManifestPath
        The path (relative to the current working directory or absolute) to the ModuleManifest to
        read to find the ModuleRoot.

    .EXAMPLE
        Get-SamplerModuleRootPath -ModuleManifestPath C:\src\MyModule\output\MyModule\2.3.4\MyModule.psd1
        # C:\src\MyModule\output\MyModule\2.3.4\MyModule.psm1

#>
function Get-SamplerModuleRootPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $moduleInfo = Get-SamplerModuleInfo @PSBoundParameters

    if ($moduleInfo.Keys -contains 'RootModule')
    {
        Get-SamplerAbsolutePath -Path $moduleInfo.RootModule -RelativeTo (Split-Path -Parent -Path $ModuleManifestPath)
    }
    else
    {
        return $null
    }
}
#EndRegion './Public/Get-SamplerModuleRootPath.ps1' 45
#Region './Public/Get-SamplerProjectName.ps1' 0

<#
    .SYNOPSIS
        Gets the Project Name based on the ModuleManifest if Available.

    .DESCRIPTION
        Finds the Module Manifest through `Get-SamplerProjectModuleManifest`
        and deduce ProjectName based on the BaseName of that manifest.

    .PARAMETER BuildRoot
        BuildRoot of the Sampler project to search the Module manifest from.

    .EXAMPLE
        Get-SamplerProjectName -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerProjectName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    return (Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot).BaseName
}
#EndRegion './Public/Get-SamplerProjectName.ps1' 30
#Region './Public/Get-SamplerSourcePath.ps1' 0

<#
    .SYNOPSIS
        Gets the project's source Path based on the ModuleManifest location.

    .DESCRIPTION
        By finding the ModuleManifest of the project using `Get-SamplerProjectModuleManifest`
        this function assumes that the source folder is the parent folder of
        that module manifest.
        This allows the source folder to be src, source, or the Module name's, without
        hardcoding the name.

    .PARAMETER BuildRoot
        BuildRoot of the Sampler project to search the Module manifest from.

    .EXAMPLE
        Get-SamplerSourcePath -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerSourcePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    $SamplerProjectModuleManifest = Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot
    $samplerSrcPathToTest = Join-Path -Path $BuildRoot -ChildPath 'src'
    $samplerSourcePathToTest = Join-Path -Path $BuildRoot -ChildPath 'source'

    if ($null -ne $SamplerProjectModuleManifest)
    {
        return $SamplerProjectModuleManifest.Directory.FullName
    }
    elseif ($null -eq $SamplerProjectModuleManifest -and (Test-Path -Path  $samplerSourcePathToTest))
    {
        Write-Debug -Message ('The ''source'' path ''{0}'' was found.' -f $samplerSourcePathToTest)
        return $samplerSourcePathToTest
    }
    elseif ($null -eq $SamplerProjectModuleManifest -and (Test-Path -Path $samplerSrcPathToTest))
    {
        Write-Debug -Message ('The ''src'' path ''{0}'' was found.' -f $samplerSrcPathToTest)
        return $samplerSrcPathToTest
    }
    else
    {
        throw 'Module Source Path not found.'
    }
}
#EndRegion './Public/Get-SamplerSourcePath.ps1' 54
#Region './Public/Invoke-SamplerGit.ps1' 0
<#
    .SYNOPSIS
        Executes git with the provided arguments.

    .DESCRIPTION
        This command executes git with the provided arguments and throws an error
        if the call failed.

    .PARAMETER Argument
        Specifies the arguments to call git with. It is passes as an array of strings,
        e.g. @('tag', 'v2.0.0').

    .EXAMPLE
        Invoke-SamplerGit -Argument @('config', 'user.name', 'MyName')

        Calls git to set user name in the git config.

    .NOTES
        Git does not throw an error that can be caught by the pipeline. For example
        this git command error but does not throw 'hello' as one would expect.
        ```
        PS> try { git describe --contains } catch { throw 'hello' }
        fatal: cannot describe '144e0422398e89cc8451ebba738c0a410b628302'
        ```
        So we have to determine if git worked or not by checking the last exit code
        and then throw an error to stop the pipeline.
#>
function Invoke-SamplerGit
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Argument
    )

    # The catch is triggered only if 'git' can't be found.
    try
    {
        & git $Argument
    }
    catch
    {
        throw $_
    }

    <#
        This will trigger an error if git returned an error code from the above
        execution. Git will also have outputted an error message to the console
        so we just need to throw a generic error.
    #>
    if ($LASTEXITCODE)
    {
        throw "git returned exit code $LASTEXITCODE indicated failure."
    }
}
#EndRegion './Public/Invoke-SamplerGit.ps1' 57
#Region './Public/Merge-JaCoCoReport.ps1' 0

<#
    .SYNOPSIS
        Merge two JaCoCoReports into one.

    .DESCRIPTION
        When you run tests independently for the same module, you may want to
        get a unified report of all the code paths that were tested.
        For instance, you want to get a unified report when the runs
        where done on Linux and Windows.

        This function helps merge the results of two runs into one file.
        If you have more than two reports, keep merging them.

    .PARAMETER OriginalDocument
        One of the JaCoCoReports you would like to merge.

    .PARAMETER MergeDocument
        Second JaCoCoReports you would like to merge with the other one.

    .EXAMPLE
        Merge-JaCoCoReport -OriginalDocument 'C:\src\MyModule\Output\JaCoCoRun_linux.xml' -MergeDocument 'C:\src\MyModule\Output\JaCoCoRun_windows.xml'

    .NOTES
        See also Update-JaCoCoStatistic that will update the counter elements.
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Merge-JaCoCoReport
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $OriginalDocument,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $MergeDocument
    )

    # Loop through all existing packages in the document to merge.
    foreach ($mergePackage in $MergeDocument.report.package)
    {
        Write-Verbose -Message "  Processing package: $($mergePackage.Name)"

        # Get the package from the original document.
        $originalPackage = $OriginalDocument.report.package |
            Where-Object -FilterScript {
                $_.Name -eq $mergePackage.Name
            }

        # Evaluate if the package exist in the original document.
        if ($null -ne $originalPackage)
        {
            <#
                Package already exist, evaluate that the package in original
                document does not miss anything that the merge document contain.
            #>

            <#
                Loop through the package's <class> in the merge document and
                verify that they exist in the original document.
            #>
            foreach ($mergeClass in $mergePackage.class)
            {
                Write-Verbose -Message "    Processing class: $($mergeClass.Name)"

                $originalClass = $originalPackage.class |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeClass.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalClass)
                {
                    Write-Verbose -Message "      Adding class: $($mergeClass.name)"

                    # Add missing sourcefile from merge document to original document.
                    $null = $originalPackage.AppendChild($originalPackage.OwnerDocument.ImportNode($mergeClass, $true))
                }
                else
                {
                    <#
                        Loop through the sourcefile's <method> in the merge document and
                        verify that they exist in the original document.
                    #>
                    foreach ($mergeClassMethod in $mergeClass.method)
                    {
                        $originalClassMethod = $originalClass.method |
                            Where-Object -FilterScript {
                                $_.name -eq $mergeClassMethod.name
                            }

                        if ($null -eq $originalClassMethod)
                        {
                            # Missed line in origin, covered in merge.
                            Write-Verbose -Message "      Adding method: $($mergeClassMethod.name)"

                            $null = $originalClass.AppendChild($originalClass.OwnerDocument.ImportNode($mergeClassMethod, $true))

                            # Skip to next line.
                            continue
                        }
                    }
                }
            }

            <#
                Loop through the package's <sourcefile> in the merge document and
                verify that they exist in the original document.
            #>
            foreach ($mergeSourceFile in $mergePackage.sourcefile)
            {
                Write-Verbose -Message "    Processing sourcefile: $($mergeSourceFile.Name)"

                $originalSourceFile = $originalPackage.sourcefile |
                    Where-Object -FilterScript {
                        $_.name -eq $mergeSourceFile.name
                    }

                # Evaluate if the sourcefile exist in the original document.
                if ($null -eq $originalSourceFile)
                {
                    Write-Verbose -Message "      Adding sourcefile: $($mergeSourceFile.name)"

                    # Add missing sourcefile from merge document to original document.
                    $null = $originalPackage.AppendChild($originalPackage.OwnerDocument.ImportNode($mergeSourceFile, $true))
                }
                else
                {
                    <#
                        Loop through the sourcefile's <line> in the merge document and
                        verify that they exist in the original document.
                    #>
                    foreach ($mergeSourceFileLine in $mergeSourceFile.line)
                    {
                        $originalSourceFileLine = $originalSourceFile.line |
                            Where-Object -FilterScript {
                                $_.nr -eq $mergeSourceFileLine.nr
                            }

                        if ($null -eq $originalSourceFileLine)
                        {
                            # Missed line in origin, covered in merge.
                            Write-Verbose -Message "      Adding line: $($mergeSourceFileLine.nr)"

                            $null = $originalSourceFile.AppendChild($originalSourceFile.OwnerDocument.ImportNode($mergeSourceFileLine, $true))

                            # Skip to next line.
                            continue
                        }
                        else
                        {
                            if ($originalSourceFileLine.ci -eq 0 -and $mergeSourceFileLine.ci -ne 0 -and
                                $originalSourceFileLine.mi -ne 0 -and $mergeSourceFileLine.mi -eq 0)
                            {
                                # Missed line in origin, covered in merge

                                Write-Verbose -Message "      Updating missed line: $($mergeSourceFileLine.nr)"

                                $originalSourceFileLine.ci = $mergeSourceFileLine.ci
                                $originalSourceFileLine.mi = $mergeSourceFileLine.mi
                            }
                            elseif ($originalSourceFileLine.ci -lt $mergeSourceFileLine.ci)
                            {
                                # Missed line in origin, covered in merge

                                Write-Verbose -Message "      Updating line: $($mergeSourceFileLine.nr)"

                                <#
                                    There is an open issue tracking if this is the
                                    correct way to calculate hit count:
                                    https://github.com/gaelcolas/Sampler/issues/392
                                #>
                                $originalSourceFileLine.ci = $mergeSourceFileLine.ci
                                $originalSourceFileLine.mi = $mergeSourceFileLine.mi
                            }

                        }
                    }
                }
            }
        }
        else
        {
            <#
                New package, does not exist in origin. Add package.
            #>

            Write-Verbose -Message "    Package '$($mergePackage.Name)' does not exist in original file. Adding..."

            <#
                Must import the node with child elements first since it belongs
                to another XML document.
            #>
            $packageElementToMerge = $OriginalDocument.ImportNode($mergePackage, $true)

            <#
                Append the 'package' element to the 'report' element, there should
                only be one report element.

                The second item in the array of the 'report' property is the XmlElement
                object.
            #>
            $null = $OriginalDocument.report[1].AppendChild($packageElementToMerge)
        }
    }

    <#
        The counters at the 'report' element level need to be moved at the end
        of the document to comply with the DTD. Select out the counter elements
        under the report element, and move any that is found.
    #>
    $elementToMove = Select-XML -Xml $OriginalDocument -XPath '/report/counter'

    if ($elementToMove)
    {
        $elementToMove | ForEach-Object -Process {
            $elementToMove.Node.ParentNode.AppendChild($_.Node) | Out-Null
        }
    }

    return $OriginalDocument
}
#EndRegion './Public/Merge-JaCoCoReport.ps1' 227
#Region './Public/New-SampleModule.ps1' 0

<#
    .SYNOPSIS
        Create a module scaffolding and add samples & build pipeline.

    .DESCRIPTION
        New-SampleModule helps you bootstrap your PowerShell module project by
        creating a the folder structure of your module, and optionally add the
        pipeline files to help with compiling the module, publishing to PSGallery
        and GitHub and testing quality and style such as per the DSC Community
        guildelines.

    .PARAMETER DestinationPath
        Destination of your module source root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files.

    .PARAMETER ModuleType
        Specifies the type of module to create. The default value is 'SimpleModule'.
        Preset of module you would like to create:
            - CompleteSample
            - SimpleModule
            - SimpleModule_NoBuild
            - dsccommunity

    .PARAMETER ModuleAuthor
        The author of module that will be populated in the Module Manifest and will show in the Gallery.

    .PARAMETER ModuleName
        The Name of your Module.

    .PARAMETER ModuleDescription
        The Description of your Module, to be used in your Module manifest.

    .PARAMETER CustomRepo
        The Custom PS repository if you want to use an internal (private) feed to pull for dependencies.

    .PARAMETER ModuleVersion
        Version you want to set in your Module Manifest. If you follow our approach, this will be updated during compilation anyway.

    .PARAMETER LicenseType
        Type of license you would like to add to your repository. We recommend MIT for Open Source projects.

    .PARAMETER SourceDirectory
        How you would like to call your Source repository to differentiate from the output and the tests folder. We recommend to call it 'source',
        and the default value is 'source'.

    .PARAMETER Features
        If you'd rather select specific features from this template to build your module, use this parameter instead.

    .EXAMPLE
        C:\src> New-SampleModule -DestinationPath . -ModuleType CompleteSample -ModuleAuthor "Gael Colas" -ModuleName MyModule -ModuleVersion 0.0.1 -ModuleDescription "a sample module" -LicenseType MIT -SourceDirectory Source

    .NOTES
        See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SampleModule
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter(ParameterSetName = 'ByModuleType')]
        [string]
        [ValidateSet('SimpleModule', 'CompleteSample', 'SimpleModule_NoBuild', 'dsccommunity')]
        $ModuleType = 'SimpleModule',

        [Parameter()]
        [System.String]
        $ModuleAuthor = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ModuleDescription,

        [Parameter()]
        [System.String]
        $CustomRepo = 'PSGallery',

        [Parameter()]
        [System.String]
        $ModuleVersion = '0.0.1',

        [Parameter()]
        [System.String]
        [ValidateSet('MIT','Apache','None')]
        $LicenseType = 'MIT',

        [Parameter()]
        [System.String]
        [ValidateSet('source','src')]
        $SourceDirectory = 'source',

        [Parameter(ParameterSetName = 'ByFeature')]
        [ValidateSet(
            'All',
            'Enum',
            'Classes',
            'DSCResources',
            'ClassDSCResource',
            'SampleScripts',
            'git',
            'Gherkin',
            'UnitTests',
            'ModuleQuality',
            'Build',
            'AppVeyor',
            'TestKitchen'
            )]
        [System.String[]]
        $Features
    )

    $templateSubPath = 'Templates/Sampler'
    $samplerBase = $MyInvocation.MyCommand.Module.ModuleBase

    $invokePlasterParam = @{
        TemplatePath = Join-Path -Path $samplerBase -ChildPath $templateSubPath
        DestinationPath   = $DestinationPath
        NoLogo            = $true
        ModuleName        = $ModuleName
    }

    foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $paramValue = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue

        # if $paramName is $null, leave it to Plaster to ask the user.
        if ($paramvalue -and -not $invokePlasterParam.ContainsKey($paramName))
        {
            $invokePlasterParam.Add($paramName, $paramValue)
        }
    }

    if ($LicenseType -eq 'none')
    {
        $invokePlasterParam.Remove('LicenseType')
        $invokePlasterParam.add('License', 'false')
    }
    else
    {
        $invokePlasterParam.add('License', 'true')
    }

    Invoke-Plaster @invokePlasterParam
}
#EndRegion './Public/New-SampleModule.ps1' 158
#Region './Public/New-SamplerJaCoCoDocument.ps1' 0

<#
    .SYNOPSIS
        Creates a new JaCoCo XML document based on the provided missed and hit
        lines.

    .DESCRIPTION
        Creates a new JaCoCo XML document based on the provided missed and hit
        lines. This command is usually used together with the output object from
        Pester that also have been passed through ModuleBuilder's Convert-LineNumber.

    .PARAMETER MissedCommands
        An array of PSCustomObject that contain all the missed code lines.

    .PARAMETER HitCommands
        An array of PSCustomObject that contain all the code lines that were hit.

    .PARAMETER PackageName
        The name of package of the test source files, e.g. 'source', 'MyFunction',
        or '2.3.0'.

    .PARAMETER PackageDisplayName
        The display name of the package if it should be shown to the user differently,
        e.g. 'source' if the package name is '2.3.0'. Defaults to the same value as
        PackageName.

    .EXAMPLE
        $pesterObject = Invoke-Pester ./tests/unit -CodeCoverage
        $pesterObject.CodeCoverage.MissedCommands |
            Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
        $pesterObject.CodeCoverage.HitCommands |
            Convert-LineNumber -ErrorAction 'Stop' -PassThru | Out-Null
        New-SamplerJaCoCoDocument `
            -MissedCommands $pesterObject.CodeCoverage.MissedCommands `
            -HitCommands $pesterObject.CodeCoverage.HitCommands `
            -PackageName 'source'

    .EXAMPLE
        New-SamplerJaCoCoDocument `
            -MissedCommands @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 0
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 4
            } `
            -HitCommands @{
                Class            = 'ResourceBase'
                Function         = 'Compare'
                HitCount         = 2
                SourceFile       = '.\Classes\001.ResourceBase.ps1'
                SourceLineNumber = 3
            } `
            -PackageName 'source'
#>
function New-SamplerJaCoCoDocument
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object[]]
        $MissedCommands,

        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [System.Object[]]
        $HitCommands,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PackageName,

        [Parameter()]
        [System.String]
        $PackageDisplayName
    )

    if (-not $PSBoundParameters.ContainsKey('PackageDisplayName'))
    {
        $PackageDisplayName = $PackageName
    }

    [System.Xml.XmlDocument] $coverageXml = ''

    <#
        This need to be set on Windows PowerShell even if it is already $null
        otherwise 'CreateDocumentType()' below will try to load the DTD. This
        does not happen on PowerShell and this line is not needed it Windows
        PowerShell is not used at all. Seems that setting this property changes
        something internal in [System.Xml.XmlDocument].
        See https://stackoverflow.com/questions/11135343/xml-documenttype-method-createdocumenttype-crashes-if-dtd-is-absent-net-c-sharp.
    #>
    $coverageXml.XmlResolver = $null

    # XML header.
    $xmlDeclaration = $coverageXml.CreateXmlDeclaration('1.0', 'UTF-8', 'no')

    # DTD: https://www.jacoco.org/jacoco/trunk/coverage/report.dtd
    $xmlDocumentType = $coverageXml.CreateDocumentType('report', '-//JACOCO//DTD Report 1.1//EN', 'report.dtd', $null)

    $coverageXml.AppendChild($xmlDeclaration) | Out-Null
    $coverageXml.AppendChild($xmlDocumentType) | Out-Null

    # Root element 'report'.
    $xmlElementReport = $coverageXml.CreateNode('element', 'report', $null)
    $xmlElementReport.SetAttribute('name', 'Sampler ({0})' -f (Get-Date).ToString('yyyy-mm-dd HH:mm:ss'))

    <#
        Child element 'sessioninfo'.

        The attributes 'start' and 'dump' is the time it took to run the tests in
        milliseconds, but it is not used in the end, we just add a plausible number
        here so it passes the referenced DTD, or any other parsing that might be done
        in the future.
    #>
    $testRunLengthInMilliseconds = 1785237 # ~30 minutes

    [System.Int64] $sessionInfoEndTime = [System.Math]::Floor((New-TimeSpan -Start (Get-Date -Date '01/01/1970') -End (Get-Date)).TotalMilliseconds)
    [System.Int64] $sessionInfoStartTime = [System.Math]::Floor($sessionInfoEndTime - $testRunLengthInMilliseconds)

    $xmlElementSessionInfo = $coverageXml.CreateNode('element', 'sessioninfo', $null)
    $xmlElementSessionInfo.SetAttribute('id', 'this')
    $xmlElementSessionInfo.SetAttribute('start', $sessionInfoStartTime)
    $xmlElementSessionInfo.SetAttribute('dump', $sessionInfoEndTime)
    $xmlElementReport.AppendChild($xmlElementSessionInfo) | Out-Null

    <#
        This is how each object in $allCommands looks like:

        # A method in a PowerShell class located in the Classes folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 168
        StartLine        : 168
        EndLine          : 168
        StartColumn      : 25
        EndColumn        : 36
        Class            : ResourceBase
        Function         : Compare
        Command          : $currentState = $this.Get() | ConvertTo-HashTableFromObject
        HitCount         : 86
        SourceFile       : .\Classes\001.ResourceBase.ps1
        SourceLineNumber : 153

        # A function located in private or public folder.
        File             : C:\source\DnsServerDsc\output\MyModule\1.0.0\MyModule.psm1
        Line             : 2658
        StartLine        : 2658
        EndLine          : 2658
        StartColumn      : 26
        EndColumn        : 29
        Class            :
        Function         : Get-LocalizedDataRecursive
        Command          : $localizedData = @{}
        HitCount         : 225
        SourceFile       : .\Private\Get-LocalizedDataRecursive.ps1
        SourceLineNumber : 35
    #>
    $allCommands = $HitCommands + $MissedCommands

    $sourcePathFolderName = (Split-Path -Path $PackageDisplayName -Leaf) -replace '\\','/'

    $reportCounterInstruction = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterLine = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterMethod = @{
        Missed  = 0
        Covered = 0
    }

    $reportCounterClass = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterInstruction = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterLine = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterMethod = @{
        Missed  = 0
        Covered = 0
    }

    $packageCounterClass = @{
        Missed  = 0
        Covered = 0
    }

    $allSourceFileElements = @()

    # This is what the user expects to see.
    $packageDisplayName = $sourcePathFolderName

    # The module version is what is expected to be in the XML.
    $xmlPackageName = $PackageName

    Write-Debug -Message ('Creating XML output for JaCoCo package ''{0}''.' -f $packageDisplayName)

    <#
        Child element 'package'.

        This implementation assumes the attribute 'name' of the element 'package'
        should be the path to the folder that contains the PowerShell script files
        (relative from GitHub repository root).
    #>
    $xmlElementPackage = $coverageXml.CreateElement('package')
    $xmlElementPackage.SetAttribute('name', $xmlPackageName)

    $commandsGroupedOnSourceFile = $allCommands | Group-Object -Property 'SourceFile'

    foreach ($jaCocoClass in $commandsGroupedOnSourceFile)
    {
        $classCounterInstruction = @{
            Missed  = 0
            Covered = 0
        }

        $classCounterLine = @{
            Missed  = 0
            Covered = 0
        }

        $classCounterMethod = @{
            Missed  = 0
            Covered = 0
        }

        $classDisplayName = ($jaCocoClass.Name -replace '^\.', $sourcePathFolderName) -replace '\\','/'

        # The module version is what is expected to be in the XML.
        $sourceFilePath = ($jaCocoClass.Name -replace '^\.', $PackageName) -replace '\\','/'

        <#
            Get class name if it exist, otherwise use function name. The first
            object should in the array should give us the right information.
        #>
        $xmlClassName = if ([System.String]::IsNullOrEmpty($jaCocoClass.Group[0].Class))
        {
            if ([System.String]::IsNullOrEmpty($jaCocoClass.Group[0].Function))
            {
                '<script>'
            }
            else
            {
                $jaCocoClass.Group[0].Function
            }
        }
        else
        {
            $jaCocoClass.Group[0].Class
        }

        $sourceFileName = $sourceFilePath -replace [regex]::Escape('{0}/' -f $PackageName)

        Write-Debug -Message ("`tCreating XML output for JaCoCo class '{0}'." -f $classDisplayName)

        # Child element 'class'.
        $xmlElementClass = $coverageXml.CreateElement('class')
        $xmlElementClass.SetAttribute('name', $xmlClassName)
        $xmlElementClass.SetAttribute('sourcefilename', $sourceFileName)

        <#
            This assumes that a value in property Function is never $null. Test
            showed that commands at script level is assigned empty string in the
            Function property, so it should work for missed and hit commands at
            script level too.

            Sorting the objects after SourceLineNumber so they come in the order
            they appear in the code file. Also, it is necessary for the
            command Update-JoCaCoStatistic to work.
        #>
        $commandsGroupedOnFunction = $jaCocoClass.Group |
                Group-Object -Property 'Function' |
                Sort-Object -Property {
                    # Find the first line for each method.
                    ($_.Group.SourceLineNumber | Measure-Object -Minimum).Minimum
                }

        foreach ($jaCoCoMethod in $commandsGroupedOnFunction)
        {
            $functionName = if ([System.String]::IsNullOrEmpty($jaCoCoMethod.Name))
            {
                '<script>'
            }
            else
            {
                $jaCoCoMethod.Name
            }

            Write-Debug -Message ("`t`tCreating XML output for JaCoCo method '{0}'." -f $functionName)

            <#
                Sorting all commands in ascending order and using the first
                'SourceLineNumber' as the first line of the method. Assuming
                every code line for the method was in either $MissedCommands
                or $HitCommands which the sorting is based on.
            #>
            $methodFirstLine = $jaCoCoMethod.Group |
                Sort-Object -Property 'SourceLineNumber' |
                    Select-Object -First 1 -ExpandProperty 'SourceLineNumber'

            # Child element 'method'.
            $xmlElementMethod = $coverageXml.CreateElement('method')
            $xmlElementMethod.SetAttribute('name', $functionName)
            $xmlElementMethod.SetAttribute('desc', '()')
            $xmlElementMethod.SetAttribute('line', $methodFirstLine)

            <#
                Documentation for counters:
                https://www.jacoco.org/jacoco/trunk/doc/counters.html
            #>

            <#
                Child element 'counter' and type INSTRUCTION.

                Each command can be hit multiple times, the INSTRUCTION counts
                how many times the command was hit or missed.
            #>
            $numberOfInstructionsCovered = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                )
            ).Count

            $numberOfInstructionsMissed = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        }
                )
            ).Count

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'INSTRUCTION' -Covered $numberOfInstructionsCovered -Missed $numberOfInstructionsMissed

            $classCounterInstruction.Covered += $numberOfInstructionsCovered
            $classCounterInstruction.Missed += $numberOfInstructionsMissed

            $packageCounterInstruction.Covered += $numberOfInstructionsCovered
            $packageCounterInstruction.Missed += $numberOfInstructionsMissed

            $reportCounterInstruction.Covered += $numberOfInstructionsCovered
            $reportCounterInstruction.Missed += $numberOfInstructionsMissed

            <#
                Child element 'counter' and type LINE.

                The LINE counts how many unique lines that was hit or missed.
            #>
            $numberOfLinesCovered = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                )
            ).Count

            $numberOfLinesMissed = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -eq 0
                        } |
                            Sort-Object -Property 'SourceLineNumber' -Unique
                )
            ).Count

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'LINE' -Covered $numberOfLinesCovered -Missed $numberOfLinesMissed

            $classCounterLine.Covered += $numberOfLinesCovered
            $classCounterLine.Missed += $numberOfLinesMissed

            $packageCounterLine.Covered += $numberOfLinesCovered
            $packageCounterLine.Missed += $numberOfLinesMissed

            $reportCounterLine.Covered += $numberOfLinesCovered
            $reportCounterLine.Missed += $numberOfLinesMissed

            <#
                Child element 'counter' and type METHOD.

                The METHOD counts as covered if at least one line was hit in
                the method. This value seem not to be higher than 1, assuming
                that is true.
            #>
            $isLineInMethodCovered = (
                # Make sure to always return an array, even for just one object.
                @(
                    $jaCoCoMethod.Group |
                        Where-Object -FilterScript {
                            $_.HitCount -ge 1
                        }
                )
            ).Count

            <#
                If at least one instructions was covered in the method, then
                method was covered.
            #>
            if ($isLineInMethodCovered)
            {
                $methodCovered = 1
                $methodMissed = 0

                $classCounterMethod.Covered += 1

                $packageCounterMethod.Covered += 1

                $reportCounterMethod.Covered += 1
            }
            else
            {
                $methodCovered = 0
                $methodMissed = 1

                $classCounterMethod.Missed += 1

                $packageCounterMethod.Missed += 1

                $reportCounterMethod.Missed += 1
            }

            New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementMethod -CounterType 'METHOD' -Covered $methodCovered -Missed $methodMissed

            $xmlElementClass.AppendChild($xmlElementMethod) | Out-Null
        }

        $xmlElementCounter_ClassInstruction = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'INSTRUCTION' -Covered $classCounterInstruction.Covered -Missed $classCounterInstruction.Missed -PassThru
        $xmlElementCounter_ClassLine = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'LINE' -Covered $classCounterLine.Covered -Missed $classCounterLine.Missed -PassThru

        if ($classCounterLine.Covered -ge 1)
        {
            $classCovered = 1
            $classMissed = 0

            $packageCounterClass.Covered += 1

            $reportCounterClass.Covered += 1
        }
        else
        {
            $classCovered = 0
            $classMissed = 1

            $packageCounterClass.Missed += 1

            $reportCounterClass.Missed += 1
        }

        $xmlElementCounter_ClassMethod = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'METHOD' -Covered $classCounterMethod.Covered -Missed $classCounterMethod.Missed -PassThru
        $xmlElementCounter_Class = New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementClass -CounterType 'CLASS' -Covered $classCovered -Missed $classMissed -PassThru

        $xmlElementPackage.AppendChild($xmlElementClass) | Out-Null

        <#
            Child element 'sourcefile'.

            Add sourcefile element to an array for each class. The array
            will be added to the XML document at the end of the package
            loop.
        #>
        $xmlElementSourceFile = $coverageXml.CreateElement('sourcefile')
        $xmlElementSourceFile.SetAttribute('name', $sourceFileName)

        $linesToReport = @()

        # Get all instructions that was covered by grouping on 'SourceLineNumber'.
        $linesCovered = $jaCocoClass.Group |
            Sort-Object -Property 'SourceLineNumber' |
                Where-Object {
                    $_.HitCount -ge 1
                } |
                    Group-Object -Property 'SourceLineNumber' -NoElement

        # Add each covered line with its count of instructions covered.
        $linesCovered |
            ForEach-Object {
                $linesToReport += @{
                    Line    = [System.UInt32] $_.Name
                    Covered = $_.Count
                    Missed  = 0
                }
            }

        # Get all instructions that was missed by grouping on 'SourceLineNumber'.
        $linesMissed = $jaCocoClass.Group |
            Sort-Object -Property 'SourceLineNumber' |
                Where-Object {
                    $_.HitCount -eq 0
                } |
                    Group-Object -Property 'SourceLineNumber' -NoElement

        # Add each missed line with its count of instructions missed.
        $linesMissed |
            ForEach-Object {
                # Test if there are an existing line that is covered.
                if ($linesToReport.Line -contains $_.Name)
                {
                    $lineNumberToLookup = $_.Name

                    $coveredLineItem = $linesToReport |
                        Where-Object -FilterScript {
                            $_.Line -eq $lineNumberToLookup
                        }

                    $coveredLineItem.Missed += $_.Count
                }
                else
                {
                    $linesToReport += @{
                        Line    = [System.UInt32] $_.Name
                        Covered = 0
                        Missed  = $_.Count
                    }
                }
            }

        $linesToReport |
            Sort-Object -Property 'Line' |
                ForEach-Object -Process {
                    $xmlElementLine = $coverageXml.CreateElement('line')
                    $xmlElementLine.SetAttribute('nr', $_.Line)

                    <#
                        Child element 'line'.

                        These attributes are best explained here:
                        https://stackoverflow.com/questions/33868761/how-to-interpret-the-jacoco-xml-file
                    #>

                    $xmlElementLine.SetAttribute('mi', $_.Missed)
                    $xmlElementLine.SetAttribute('ci', $_.Covered)
                    $xmlElementLine.SetAttribute('mb', 0)
                    $xmlElementLine.SetAttribute('cb', 0)

                    $xmlElementSourceFile.AppendChild($xmlElementLine) |
                        Out-Null
                    }

        <#
            Add counters to sourcefile element. Reuses those element that was
            created for the class element, as they will be the same.
        #>
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassInstruction.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassLine.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_ClassMethod.CloneNode($false)) | Out-Null
        $xmlElementSourceFile.AppendChild($xmlElementCounter_Class.CloneNode($false)) | Out-Null

        $allSourceFileElements += $xmlElementSourceFile
    } # end class loop

    # Add all sourcefile elements that was generated in the class-element-loop.
    $allSourceFileElements |
        ForEach-Object -Process {
            $xmlElementPackage.AppendChild($_) | Out-Null
        }

    # Add counters at the package level.
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'INSTRUCTION' -Covered $packageCounterInstruction.Covered -Missed $packageCounterInstruction.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'LINE' -Covered $packageCounterLine.Covered -Missed $packageCounterLine.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'METHOD' -Covered $packageCounterMethod.Covered -Missed $packageCounterMethod.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementPackage -CounterType 'CLASS' -Covered $packageCounterClass.Covered -Missed $packageCounterClass.Missed

    $xmlElementReport.AppendChild($xmlElementPackage) | Out-Null

    # Add counters at the report level.
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'INSTRUCTION' -Covered $reportCounterInstruction.Covered -Missed $reportCounterInstruction.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'LINE' -Covered $reportCounterLine.Covered -Missed $reportCounterLine.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'METHOD' -Covered $reportCounterMethod.Covered -Missed $reportCounterMethod.Missed
    New-SamplerXmlJaCoCoCounter -XmlNode $xmlElementReport -CounterType 'CLASS' -Covered $reportCounterClass.Covered -Missed $reportCounterClass.Missed

    $coverageXml.AppendChild($xmlElementReport) | Out-Null

    return $coverageXml
}
#EndRegion './Public/New-SamplerJaCoCoDocument.ps1' 604
#Region './Public/New-SamplerPipeline.ps1' 0

<#
    .SYNOPSIS
        Create a Sampler scaffolding so you can add samples & build pipeline.

    .DESCRIPTION
        New-SamplerPipeline helps you bootstrap your project pipeline, whether it's for a Chocolatey
        package, Azure Policy Guest Configuration packages or just a pipeline for a CI process.

    .PARAMETER DestinationPath
        Destination of your project's root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files such as build.ps1, the entry point.

    .PARAMETER Pipeline
        Type of Pipeline you would like to create at the destination folder. You can create a base pipeline using th
        value `Build` that will include the bootstrap and resolve dependency process, but you will need to edit
        the `Build.Yaml` to call the tasks you desire.
        You can also create a Chocolatey pipeline, preconfigured to build Chocolatey packages, or call a Sampler pipeline.

    .EXAMPLE
        C:\src> New-SamplerPipeline -DestinationPath . -Pipeline Build -ProjectName MyBuild -License 'true' -LicenseType MIT -SourceDirectory Source  -MainGitBranch main -ModuleDescription 'some desc' -CustomRepo PSGallery -Features All

    .NOTES
        Other parameters will be displayed based on the Template used for the pipeline.
        See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SamplerPipeline
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([System.Void])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Build',
            'ChocolateyPipeline',
            'Sampler'
            )]
        [System.String]
        $Pipeline
    )

    dynamicparam
    {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Pipeline)
        {
            return
        }

        $PipelineTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Pipeline
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $PipelineTemplateFolder

        $previousErrorActionPreference = $ErrorActionPreference

        try
        {
            <#
                Let's convert non-terminating errors in this function to terminating so we
                catch and format the error message as a warning.
            #>
            $ErrorActionPreference = 'Stop'

            <#
                The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
                since we are only evaluating the parameters in the manifest - no need for EvaluateConditionAttribute as we
                are not building up multiple parameter sets.  And no need for EvaluateAttributeValue since we are only
                grabbing the parameter's value which is static.
            #>
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)

            if (-not (Test-Path -LiteralPath $templateAbsolutePath -PathType 'Container'))
            {
                throw ("Can't find plaster template at {0}." -f $templateAbsolutePath)
            }

            $plasterModule = Get-Module -Name 'Plaster'

            <#
                Load manifest file using culture lookup (using Plaster module private function GetPlasterManifestPathForCulture).
                This is the current function that is called:
                https://github.com/PowerShellOrg/Plaster/blob/0506a26ffb532a335a4e62a8da31d9ca0177ae2a/src/InvokePlaster.ps1#L1478
            #>
            $manifestPath = & $plasterModule {
                param
                (
                    [Parameter()]
                    [System.String]
                    $templateAbsolutePath,

                    [Parameter()]
                    [System.String]
                    $Culture
                )

                GetPlasterManifestPathForCulture -TemplatePath $templateAbsolutePath -Culture $Culture
            } $templateAbsolutePath $PSCulture

            if (($null -eq $manifestPath) -or (-not (Test-Path -Path $manifestPath)))
            {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            <#
                The user-defined parameters in the Plaster manifest are converted to dynamic parameters
                which allows the user to provide the parameters via the command line.
                This enables non-interactive use cases.
            #>
            foreach ($node in $manifest.plasterManifest.Parameters.ChildNodes)
            {
                if ($node -isnot [System.Xml.XmlElement])
                {
                    continue
                }

                $name = $node.name
                $type = $node.type

                if ($node.prompt)
                {
                    $prompt = $node.prompt
                }
                else
                {
                    $prompt = "Missing Parameter $name"
                }

                if (-not $name -or -not $type)
                {
                    continue
                }

                # Configure ParameterAttribute and add to attr collection.
                $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type)
                {
                    'text|user-fullname|user-email'
                    {
                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, [System.String], $attributeCollection)

                        break
                    }

                    'choice|multichoice'
                    {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object -TypeName System.String[] -ArgumentList $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes)
                        {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $setValues
                        $attributeCollection.Add($validateSetAttr)

                        if ($type -eq 'multichoice')
                        {
                            $type = [System.String[]]
                        }
                        else
                        {
                            $type = [System.String]
                        }

                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, $type, $attributeCollection)

                        break
                    }

                    default
                    {
                        throw "Unrecognized Parameter Type $type for attribute $name."
                    }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch
        {
            Write-Warning "Error processing Dynamic Parameters. $($_.Exception.Message)"
        }
        finally
        {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $paramDictionary
    }

    end
    {
        # Clone the the bound parameters.
        $plasterParameter = @{} + $PSBoundParameters

        $null = $plasterParameter.Remove('Pipeline')

        $PipelineTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Pipeline
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $PipelineTemplateFolder

        $plasterParameter.Add('TemplatePath', $templatePath)

        if (-not $plasterParameter.ContainsKey('DestinationPath'))
        {
            $plasterParameter['DestinationPath'] = $DestinationPath
        }

        Invoke-Plaster @plasterParameter
    }
}
#EndRegion './Public/New-SamplerPipeline.ps1' 228
#Region './Public/Out-SamplerXml.ps1' 0

<#
    .SYNOPSIS
        Outputs an XML document to a file.

    .DESCRIPTION
        Outputs an XML document to the file specified in the parameter Path.

    .PARAMETER XmlDocument
        The XML document to format.

    .PARAMETER Path
        The path to the file name to write to.

    .PARAMETER Encoding
        Specifies the encoding for the file.

    .EXAMPLE
        Out-SamplerXml -Path 'C:\temp\my.xml' -XmlDocument '<?xml version="1.0"?><a><b /></a>' -Encoding 'UTF8'
#>
function Out-SamplerXml
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $XmlDocument,

        [Parameter(Mandatory = $true)]
        [System.String]
        $Path,

        [Parameter()]
        [ValidateSet('ASCII', 'BigEndianUnicode', 'Default', 'Latin1', 'Unicode', 'UTF32', 'UTF7', 'UTF8')]
        [System.String]
        $Encoding = 'UTF8'
    )

    $xmlSettings = New-Object -TypeName 'System.Xml.XmlWriterSettings'

    $xmlSettings.Encoding = [System.Text.Encoding]::$Encoding

    $xmlWriter = [System.Xml.XmlWriter]::Create($Path, $xmlSettings)

    $XmlDocument.Save($xmlWriter)

    $XmlWriter.Flush()
    $xmlWriter.Close()
}
#EndRegion './Public/Out-SamplerXml.ps1' 52
#Region './Public/Set-SamplerPSModulePath.ps1' 0
<#
    .SYNOPSIS
        Sets the PSModulePath for the build environment.

    .DESCRIPTION
        This command let you define the PSModulePath for the build environment. This could
        be important for DSC related builds when there are conflicts with modules in the
        Program Files folder.

    .PARAMETER PSModulePath
        Makes the command to set the PSModulePath to the specified value.

    .PARAMETER BuiltModuleSubdirectory
        The BuiltModuleSubdirectory that should be added to the PSModulePath.

    .PARAMETER RequiredModulesDirectory
        The RequiredModulesDirectory that should be added to the PSModulePath.

    .PARAMETER RemovePersonal
        Removes the personal module path from the PSModulePath.

    .PARAMETER RemoveProgramFiles
        Removes the Program Files module path from the PSModulePath.

    .PARAMETER RemoveWindows
        Removes the Windows module path from the PSModulePath.

    .PARAMETER SetSystemDefault
        Sets the PSModulePath to the default value for the system.

    .PARAMETER PassThru
        Returns the PSModulePath after the command has been executed.

    .EXAMPLE
        Set-SamplerPSModulePath -PSModulePath "C:\Modules" -RemovePersonal -RemoveProgramFiles
#>

function Set-SamplerPSModulePath
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]
        $PSModulePath,

        [Parameter()]
        [string]
        $BuiltModuleSubdirectory,

        [Parameter()]
        [string]
        $RequiredModulesDirectory,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemovePersonal,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemoveProgramFiles,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $RemoveWindows,

        [Parameter(ParameterSetName = 'BySwitches')]
        [switch]
        $SetSystemDefault,

        [Parameter()]
        [switch]
        $PassThru
    )

    $pathSeparator = [System.IO.Path]::PathSeparator
    $directorySeparator = [System.IO.Path]::DirectorySeparatorChar

    if ($BuiltModuleSubdirectory)
    {
        $BuiltModuleSubdirectory = $BuiltModuleSubdirectory.TrimEnd($directorySeparator)
    }

    if ($RequiredModulesDirectory)
    {
        $RequiredModulesDirectory = $RequiredModulesDirectory.TrimEnd($directorySeparator)
    }

    $newModulePath = if ($PSCmdlet.ParameterSetName -eq 'ByPath')
    {
        $PSModulePath
    }
    elseif ($SetSystemDefault)
    {
        [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
    }
    else
    {
        $env:PSModulePath
    }

    $newModulePath = $newModulePath -split $pathSeparator |
        Select-Object -Unique |
            Where-Object { $_ }
    Write-Verbose "`t...The 'PSModulePath' has $($newModulePath.Count) paths"
    Write-Debug "The 'PSModulePath' is '$newModulePath'"

    if ($RemovePersonal)
    {
        $newModulePath = $newModulePath -notmatch '.+Documents.(Windows)?PowerShell.Modules'
        Write-Verbose "`t...Removing Personal from 'PSModulePath'"
    }

    if ($RemoveProgramFiles)
    {
        $newModulePath = $newModulePath -notmatch '.+Program Files.(Windows)?PowerShell.(7.)?Modules'
        Write-Verbose "`t...Removing Program Files from 'PSModulePath'"
    }

    if ($RemoveWindows)
    {
        $newModulePath = $newModulePath -ne 'C:\Windows\system32\WindowsPowerShell\v1.0\Modules'
        Write-Warning "It is not recommended to remove the Windows 'PSModulePath'"
        Write-Verbose "`t...Removing Windows from 'PSModulePath'"
    }
    Write-Verbose "`t...The 'PSModulePath' has $($newModulePath.Count) paths"
    Write-Debug "The 'PSModulePath' is '$newModulePath'"

    if ($RequiredModulesDirectory)
    {
        if ($newModulePath -contains $RequiredModulesDirectory)
        {
            Write-Verbose "`t...Removing RequiredModulesDirectory from 'PSModulePath'"
            $newModulePath = $newModulePath -ne $RequiredModulesDirectory
        }
        Write-Verbose "`t...Adding 'RequiredModulesDirectory' to 'PSModulePath'"
        $newModulePath = @($RequiredModulesDirectory) + $newModulePath
    }
    else
    {
        Write-Warning "The parameter 'RequiredModulesDirectory' is not set"
    }

    if ($BuiltModuleSubdirectory)
    {
        if ($newModulePath -contains $BuiltModuleSubdirectory)
        {
            Write-Verbose "`t...Removing BuiltModuleSubdirectory from 'PSModulePath'"
            $newModulePath = $newModulePath -ne $BuiltModuleSubdirectory
        }
        Write-Verbose "`t...Adding 'BuiltModuleSubdirectory' to 'PSModulePath'"
        $newModulePath = @($BuiltModuleSubdirectory) + $newModulePath
    }
    else
    {
        Write-Warning "The parameter 'BuiltModuleSubdirectory' is not set"
    }

    $newModulePath = $newModulePath -join $pathSeparator
    Write-Verbose "`t...Writing '`$env:PSModulePath' variable"

    if ($PSCmdlet.ShouldProcess($env:PSModulePath, "Set PSModulePath to '$newModulePath'"))
    {
        $env:PSModulePath = $newModulePath
    }

    if ($PassThru)
    {
        $newModulePath
    }
}
#EndRegion './Public/Set-SamplerPSModulePath.ps1' 172
#Region './Public/Split-ModuleVersion.ps1' 0

<#
    .SYNOPSIS
        Parse a SemVer2 Version string.

    .DESCRIPTION
        This function parses a SemVer (semver.org) version string into an object
        with the following properties:
        - Version: The version without tag or metadata, as used by folder versioning in PowerShell modules.
        - PreReleaseString: A Publish-Module compliant prerelease tag (see below).
        - ModuleVersion: The Version and Prerelease tag compliant with Publish-Module.

        For instance, this is a valid SemVer: `1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07`
        The Metadata is stripped: `1.15.0-pr0224-0022`
        The Version is `1.15.0`.
        The prerelease tag is `-pr0224-0022`
        However, Publish-Module (or NuGet/PSGallery) does not support such pre-release,
        so this function only keep the first part `-pr0224`

    .PARAMETER ModuleVersion
        Full SemVer version string with (optional) metadata and prerelease tag to be parsed.

    .EXAMPLE
        Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07'

        # Version PreReleaseString ModuleVersion
        # ------- ---------------- -------------
        # 1.15.0  pr0224           1.15.0-pr0224

#>
function Split-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    <#
        This handles a previous version of the module that suggested to pass
        a version string with metadata in the CI pipeline that can look like
        this: 1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
    #>
    $ModuleVersion = ($ModuleVersion -split '\+', 2)[0]

    $moduleVersion, $preReleaseString = $ModuleVersion -split '-', 2

    <#
        The cmldet Publish-Module does not yet support semver compliant
        pre-release strings. If the prerelease string contains a dash ('-')
        then the dash and everything behind is removed. For example
        'pr54-0012' is parsed to 'pr54'.
    #>
    $validPreReleaseString, $preReleaseStringSuffix = $preReleaseString -split '-'

    if ($validPreReleaseString)
    {
        $fullModuleVersion =  $moduleVersion + '-' + $validPreReleaseString
    }
    else
    {
        $fullModuleVersion =  $moduleVersion
    }

    $moduleVersionParts = [PSCustomObject]@{
        Version          = $moduleVersion
        PreReleaseString = $validPreReleaseString
        ModuleVersion    = $fullModuleVersion
    }

    return $moduleVersionParts
}
#EndRegion './Public/Split-ModuleVersion.ps1' 76
#Region './Public/Update-JaCoCoStatistic.ps1' 0

<#
    .SYNOPSIS
        Update the Statistics of a freshly merged JaCoCoReports.

    .DESCRIPTION
        When you merge two or several JaCoCoReports together
        using the Merge-JaCoCoReport, the calculated statistics
        of the Original document are not updated.

        This Command will re-calculate the JaCoCo statistics and
        update the Document.

        For the Package, Class, Method of all source files and the total it will update:
        - the Instruction Covered
        - the Instruction Missed
        - the Line Covered
        - the Line Missed
        - the Method Covered
        - the Method Missed
        - the Class Covered
        - the Class Missed

    .PARAMETER Document
        JaCoCo report XML document that needs its statistics recalculated.

    .EXAMPLE
        Update-JaCoCoStatistic -Document (Merge-JaCoCoReport $file1 $file2)

    .NOTES
        See also Merge-JaCoCoReport
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Update-JaCoCoStatistic
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $Document
    )

    Write-Verbose "Start updating statistics!"

    $totalInstructionCovered = 0
    $totalInstructionMissed = 0
    $totalLineCovered = 0
    $totalLineMissed = 0
    $totalMethodCovered = 0
    $totalMethodMissed = 0
    $totalClassCovered = 0
    $totalClassMissed = 0

    foreach ($oPackage in $Document.report.package)
    {
        Write-Verbose "Processing package $($oPackage.name)"

        $packageInstructionCovered = 0
        $packageInstructionMissed = 0
        $packageLineCovered = 0
        $packageLineMissed = 0
        $packageMethodCovered = 0
        $packageMethodMissed = 0
        $packageClassCovered = 0
        $packageClassMissed = 0

        foreach ($oPackageClass in $oPackage.class)
        {
            $classInstructionCovered = 0
            $classInstructionMissed = 0
            $classLineCovered = 0
            $classLineMissed = 0
            $classMethodCovered = 0
            $classMethodMissed = 0

            Write-Verbose "  Processing sourcefile $($oPackageClass.sourcefilename)"
            $oPackageSourcefile = $oPackage.sourcefile | Where-Object -FilterScript { $_.Name -eq $oPackageClass.sourcefilename }

            for ($i = 0; $i -lt ([array]($oPackageClass.method)).Count; $i++)
            {
                $methodInstructionCovered = 0
                $methodInstructionMissed = 0
                $methodLineCovered = 0
                $methodLineMissed = 0
                $methodCovered = 0
                $methodMissed = 0

                $currentMethod = [array]$oPackageClass.method
                $start = $currentMethod[$i].line
                if ($i -ne ($currentMethod.Count - 1))
                {
                    $end   = $currentMethod[$i+1].Line
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start -and [int]$_.nr -lt $end
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }
                else
                {
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }

                $classInstructionCovered += $methodInstructionCovered
                $classInstructionMissed += $methodInstructionMissed
                $classLineCovered += $methodLineCovered
                $classLineMissed += $methodLineMissed
                if ($methodInstructionCovered -ne 0)
                {
                    $methodCovered = 1
                    $methodMissed = 0
                    $classMethodCovered++
                }
                else
                {
                    $methodCovered = 0
                    $methodMissed = 1
                    $classMethodMissed++
                }

                # Update Method stats
                $counterInstruction = $currentMethod[$i].counter | Where-Object { $_.type -eq 'INSTRUCTION' }
                $counterInstruction.covered = [string]$methodInstructionCovered
                $counterInstruction.missed = [string]$methodInstructionMissed

                $counterLine = $currentMethod[$i].counter | Where-Object { $_.type -eq 'LINE' }
                $counterLine.covered = [string]$methodLineCovered
                $counterLine.missed = [string]$methodLineMissed

                $counterMethod = $currentMethod[$i].counter | Where-Object { $_.type -eq 'METHOD' }
                $counterMethod.covered = [string]$methodCovered
                $counterMethod.missed = [string]$methodMissed


                Write-Verbose "      Method Instruction Covered : $methodInstructionCovered"
                Write-Verbose "      Method Instruction Missed  : $methodInstructionMissed"
                Write-Verbose "      Method Line Covered        : $methodLineCovered"
                Write-Verbose "      Method Line Missed         : $methodLineMissed"
                Write-Verbose "      Method Covered             : $methodCovered"
                Write-Verbose "      Method Missed              : $methodMissed"
            }

            $packageInstructionCovered += $classInstructionCovered
            $packageInstructionMissed += $classInstructionMissed
            $packageLineCovered += $classLineCovered
            $packageLineMissed += $classLineMissed
            $packageMethodCovered += $classMethodCovered
            $packageMethodMissed += $classMethodMissed

            <#
                JaCoCo considers constructors as well as static initializers as
                methods, so any code run at script level (method '<script>') should
                be considered as the class was run.
            #>
            if ($classInstructionCovered -ne 0)
            {
                $packageClassCovered++
                $classClassCovered = 1
                $classClassMissed = 0
            }
            else
            {
                $classClassCovered = 0
                $classClassMissed = 1
            }

            # Update Class stats
            $counterInstruction = $oPackageClass.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageClass.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            # Update Sourcefile stats
            $counterInstruction = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            Write-Verbose "      Class Instruction Covered  : $classInstructionCovered"
            Write-Verbose "      Class Instruction Missed   : $classInstructionMissed"
            Write-Verbose "      Class Line Covered         : $classLineCovered"
            Write-Verbose "      Class Line Missed          : $classLineMissed"
            Write-Verbose "      Class Method Covered       : $classMethodCovered"
            Write-Verbose "      Class Method Missed        : $classMethodMissed"
        }

        $totalInstructionCovered += $packageInstructionCovered
        $totalInstructionMissed += $packageInstructionMissed
        $totalLineCovered += $packageLineCovered
        $totalLineMissed += $packageLineMissed
        $totalMethodCovered += $packageMethodCovered
        $totalMethodMissed += $packageMethodMissed
        $totalClassCovered += $packageClassCovered
        $totalClassMissed += $packageClassMissed

        # Update Package stats
        $counterInstruction = $oPackage.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
        $counterInstruction.covered = [string]$packageInstructionCovered
        $counterInstruction.missed = [string]$packageInstructionMissed

        $counterLine = $oPackage.counter | Where-Object { $_.type -eq 'LINE' }
        $counterLine.covered = [string]$packageLineCovered
        $counterLine.missed = [string]$packageLineMissed

        $counterMethod = $oPackage.counter | Where-Object { $_.type -eq 'METHOD' }
        $counterMethod.covered = [string]$packageMethodCovered
        $counterMethod.missed = [string]$packageMethodMissed

        $counterClass = $oPackage.counter | Where-Object { $_.type -eq 'CLASS' }
        $counterClass.covered = [string]$packageClassCovered
        $counterClass.missed = [string]$packageClassMissed

        Write-Verbose "  Package Instruction Covered: $packageInstructionCovered"
        Write-Verbose "  Package Instruction Missed : $packageInstructionMissed"
        Write-Verbose "  Package Line Covered       : $packageLineCovered"
        Write-Verbose "  Package Line Missed        : $packageLineMissed"
        Write-Verbose "  Package Method Covered     : $packageMethodCovered"
        Write-Verbose "  Package Method Missed      : $packageMethodMissed"
        Write-Verbose "  Package Class Covered      : $packageClassCovered"
        Write-Verbose "  Package Class Missed       : $packageClassMissed"
    }

    #Update Total stats
    $counterInstruction = $Document.report.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
    $counterInstruction.covered = [string]$totalInstructionCovered
    $counterInstruction.missed = [string]$totalInstructionMissed

    $counterLine = $Document.report.counter | Where-Object { $_.type -eq 'LINE' }
    $counterLine.covered = [string]$totalLineCovered
    $counterLine.missed = [string]$totalLineMissed

    $counterMethod = $Document.report.counter | Where-Object { $_.type -eq 'METHOD' }
    $counterMethod.covered = [string]$totalMethodCovered
    $counterMethod.missed = [string]$totalMethodMissed

    $counterClass = $Document.report.counter | Where-Object { $_.type -eq 'CLASS' }
    $counterClass.covered = [string]$totalClassCovered
    $counterClass.missed = [string]$totalClassMissed

    Write-Verbose "----------------------------------------"
    Write-Verbose " Totals"
    Write-Verbose "----------------------------------------"
    Write-Verbose "  Total Instruction Covered : $totalInstructionCovered"
    Write-Verbose "  Total Instruction Missed  : $totalInstructionMissed"
    Write-Verbose "  Total Line Covered        : $totalLineCovered"
    Write-Verbose "  Total Line Missed         : $totalLineMissed"
    Write-Verbose "  Total Method Covered      : $totalMethodCovered"
    Write-Verbose "  Total Method Missed       : $totalMethodMissed"
    Write-Verbose "  Total Class Covered       : $totalClassCovered"
    Write-Verbose "  Total Class Missed        : $totalClassMissed"
    Write-Verbose "----------------------------------------"

    Write-Verbose "Completed merging files and updating statistics!"

    return $Document
}
#EndRegion './Public/Update-JaCoCoStatistic.ps1' 306
#Region './suffix.ps1' 0
# Inspired from https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tasks\*') -Include '*.build.*' |
    ForEach-Object -Process {
        $ModuleName = ([System.IO.FileInfo] $MyInvocation.MyCommand.Name).BaseName
        $taskFileAliasName = "$($_.BaseName).$ModuleName.ib.tasks"

        Set-Alias -Name $taskFileAliasName -Value $_.FullName
    }

$SetSamplerTaskVariableAliasName = 'Set-SamplerTaskVariable'
$SetSamplerTaskVariableAliasValue = "$PSScriptRoot/scripts/Set-SamplerTaskVariable.ps1"
Set-Alias -Name $SetSamplerTaskVariableAliasName -Value $SetSamplerTaskVariableAliasValue
#EndRegion './suffix.ps1' 13

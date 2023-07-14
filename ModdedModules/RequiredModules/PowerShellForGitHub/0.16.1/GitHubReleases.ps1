# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReleaseTypeName = 'GitHub.Release'
    GitHubReleaseAssetTypeName = 'GitHub.ReleaseAsset'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubRelease
{
<#
    .SYNOPSIS
        Retrieves information about a release or list of releases on GitHub.

    .DESCRIPTION
        Retrieves information about a release or list of releases on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Release
        The ID of a specific release.
        This is an optional parameter which can limit the results to a single release.

    .PARAMETER Latest
        Retrieve only the latest release.
        This is an optional parameter which can limit the results to a single release.

    .PARAMETER Tag
        Retrieves a list of releases with the associated tag.
        This is an optional parameter which can filter the list of releases.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        Get-GitHubRelease

        Gets all releases for the default configured owner/repository.

    .EXAMPLE
        Get-GitHubRelease -Release 12345

        Get a specific release for the default configured owner/repository

    .EXAMPLE
        Get-GitHubRelease -OwnerName dotnet -RepositoryName core

        Gets all releases from the dotnet\core repository.

    .EXAMPLE
        Get-GitHubRelease -Uri https://github.com/microsoft/PowerShellForGitHub

        Gets all releases from the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubRelease -OwnerName dotnet -RepositoryName core -Latest

        Gets the latest release from the dotnet\core repository.

    .EXAMPLE
        Get-GitHubRelease -Uri https://github.com/microsoft/PowerShellForGitHub -Tag 0.8.0

        Gets the release tagged with 0.8.0 from the microsoft/PowerShellForGitHub repository.

    .NOTES
        Information about published releases are available to everyone. Only users with push
        access will receive listings for draft releases.
#>
    [CmdletBinding(DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubReleaseTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName="Elements-ReleaseId")]
        [Parameter(ParameterSetName="Elements-Latest")]
        [Parameter(ParameterSetName="Elements-Tag")]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName="Elements-ReleaseId")]
        [Parameter(ParameterSetName="Elements-Latest")]
        [Parameter(ParameterSetName="Elements-Tag")]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-ReleaseId")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-Latest")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-Tag")]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Elements-ReleaseId")]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName="Uri-ReleaseId")]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Latest')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Latest')]
        [switch] $Latest,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Tag')]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Tag')]
        [string] $Tag,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/releases"
    $description = "Getting releases for $OwnerName/$RepositoryName"

    if ($PSBoundParameters.ContainsKey('Release'))
    {
        $telemetryProperties['ProvidedRelease'] = $true

        $uriFragment += "/$Release"
        $description = "Getting release information for $Release from $OwnerName/$RepositoryName"
    }

    if ($Latest)
    {
        $telemetryProperties['GetLatest'] = $true

        $uriFragment += "/latest"
        $description = "Getting latest release from $OwnerName/$RepositoryName"
    }

    if (-not [String]::IsNullOrEmpty($Tag))
    {
        $telemetryProperties['ProvidedTag'] = $true

        $uriFragment += "/tags/$Tag"
        $description = "Getting releases tagged with $Tag from $OwnerName/$RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubReleaseAdditionalProperties)
}

filter New-GitHubRelease
{
<#
    .SYNOPSIS
        Create a new release for a repository on GitHub.

    .DESCRIPTION
        Create a new release for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Tag
        The name of the tag.  The tag will be created around the committish if it doesn't exist
        in the remote, and will need to be synced back to the local repository afterwards.

    .PARAMETER Committish
        The committish value that determines where the Git tag is created from.
        Can be any branch or commit SHA.  Unused if the Git tag already exists.
        Will default to the repository's default branch (usually 'master').

    .PARAMETER Name
        The name of the release.

    .PARAMETER Body
        Text describing the contents of the tag.

    .PARAMETER Draft
        Specifies if this should be a draft (unpublished) release or a published one.

    .PARAMETER PreRelease
        Indicates if this should be identified as a pre-release or as a full release.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        New-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 0.12.0

    .NOTES
        Requires push access to the repository.

        This endpoind triggers notifications.  Creating content too quickly using this endpoint
        may result in abuse rate limiting.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            Position = 2)]
        [string] $Tag,

        [Alias('Sha')]
        [Alias('BranchName')]
        [Alias('Commitish')] # git documentation says "committish", but GitHub uses "commitish"
        [string] $Committish,

        [string] $Name,

        [Alias('Description')]
        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedCommittish' = ($PSBoundParameters.ContainsKey('Committish'))
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedBody' = ($PSBoundParameters.ContainsKey('Body'))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{
        'tag_name' = $Tag
    }

    if ($PSBoundParameters.ContainsKey('Committish')) { $hashBody['target_commitish'] = $Committish }
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating release at $Tag"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($Tag, "Create release for $RepositoryName at tag"))
    {
        return
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReleaseAdditionalProperties)
}

filter Set-GitHubRelease
{
<#
    .SYNOPSIS
        Edits a release for a repository on GitHub.

    .DESCRIPTION
        Edits a release for a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Release
        The ID of the release to edit.

    .PARAMETER Tag
        The name of the tag.

    .PARAMETER Committish
        The committish value that determines where the Git tag is created from.
        Can be any branch or commit SHA.  Unused if the Git tag already exists.
        Will default to the repository's default branch (usually 'master').

    .PARAMETER Name
        The name of the release.

    .PARAMETER Body
        Text describing the contents of the tag.

    .PARAMETER Draft
        Specifies if this should be a draft (unpublished) release or a published one.

    .PARAMETER PreRelease
        Indicates if this should be identified as a pre-release or as a full release.

    .PARAMETER PassThru
        Returns the updated GitHub Release.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Release

    .EXAMPLE
        Set-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 0.12.0 -Body 'Adds core support for Projects'

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [string] $Tag,

        [Alias('Sha')]
        [Alias('BranchName')]
        [Alias('Commitish')] # git documentation says "committish", but GitHub uses "commitish"
        [string] $Committish,

        [string] $Name,

        [Alias('Description')]
        [string] $Body,

        [switch] $Draft,

        [switch] $PreRelease,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedTag' = ($PSBoundParameters.ContainsKey('Tag'))
        'ProvidedCommittish' = ($PSBoundParameters.ContainsKey('Committish'))
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedBody' = ($PSBoundParameters.ContainsKey('Body'))
        'ProvidedDraft' = ($PSBoundParameters.ContainsKey('Draft'))
        'ProvidedPreRelease' = ($PSBoundParameters.ContainsKey('PreRelease'))
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Tag')) { $hashBody['tag_name'] = $Tag }
    if ($PSBoundParameters.ContainsKey('Committish')) { $hashBody['target_commitish'] = $Committish }
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Body')) { $hashBody['body'] = $Body }
    if ($PSBoundParameters.ContainsKey('Draft')) { $hashBody['draft'] = $Draft.ToBool() }
    if ($PSBoundParameters.ContainsKey('PreRelease')) { $hashBody['prerelease'] = $PreRelease.ToBool() }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Creating release at $Tag"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if (-not $PSCmdlet.ShouldProcess($Release, "Update GitHub Release"))
    {
        return
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubReleaseAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubRelease
{
<#
    .SYNOPSIS
        Removes a release from a repository on GitHub.

    .DESCRIPTION
        Removes a release from a repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Release
        The ID of the release to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

    .EXAMPLE
        Remove-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890 -Confirm:$false

        Will not prompt for confirmation, as -Confirm:$false was specified.

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact='High')]
    [Alias('Delete-GitHubRelease')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/$Release"
        'Method' = 'Delete'
        'Description' = "Deleting release $Release"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Release, "Remove GitHub Release"))
    {
        return
    }

    return Invoke-GHRestMethod @params
}

filter Get-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Gets a a list of assets for a release, or downloads a single release asset.

    .DESCRIPTION
        Gets a a list of assets for a release, or downloads a single release asset.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Release
        The ID of a specific release to see the assets for.

    .PARAMETER Asset
        The ID of the specific asset to download.

    .PARAMETER Path
        The path where the downloaded asset should be stored.

    .PARAMETER Force
        If specified, will overwrite any file located at Path when downloading Asset.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        Get-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 1234567890

        Gets a list of all the assets associated with this release

    .EXAMPLE
        Get-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890 -Path 'c:\users\PowerShellForGitHub\downloads\asset.zip' -Force

        Downloads the asset 1234567890 to 'c:\users\PowerShellForGitHub\downloads\asset.zip' and
        overwrites the file that may already be there.
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements-List')]
        [Parameter(ParameterSetName='Elements-Info')]
        [Parameter(ParameterSetName='Elements-Download')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements-List')]
        [Parameter(ParameterSetName='Elements-Info')]
        [Parameter(ParameterSetName='Elements-Download')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Info',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Download',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-List',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-List',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-List',
            Position = 2)]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-Info',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements-Download',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Info',
            Position = 2)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri-Download',
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements-Download',
            Position = 2)]
        [Parameter(
            Mandatory,
            ParameterSetName='Uri-Download',
            Position = 3)]
        [string] $Path,

        [Parameter(ParameterSetName='Elements-Download')]
        [Parameter(ParameterSetName='Uri-Download')]
        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $shouldSave = $false
    $acceptHeader = $script:defaultAcceptHeader
    if ($PSCmdlet.ParameterSetName -in ('Elements-List', 'Uri-List'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/$Release/assets"
        $description = "Getting list of assets for release $Release"
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Elements-Info', 'Uri-Info'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        $description = "Getting information about release asset $Asset"
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Elements-Download', 'Uri-Download'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        $description = "Downloading release asset $Asset"
        $shouldSave = $true
        $acceptHeader = 'application/octet-stream'

        $Path = Resolve-UnverifiedPath -Path $Path
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Method' = 'Get'
        'Description' = $description
        'AcceptHeader' = $acceptHeader
        'Save' = $shouldSave
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params

    if ($PSCmdlet.ParameterSetName -in ('Elements-Download', 'Uri-Download'))
    {
        Write-Log -Message "Moving [$($result.FullName)] to [$Path]" -Level Verbose
        return (Move-Item -Path $result -Destination $Path -Force:$Force -ErrorAction Stop -PassThru)
    }
    else
    {
        return ($result | Add-GitHubReleaseAssetAdditionalProperties)
    }
}

filter New-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Uploads a new asset for a release on GitHub.

    .DESCRIPTION
        Uploads a new asset for a release on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Release
        The ID of the release that the asset is for.

    .PARAMETER UploadUrl
        The value of 'upload_url' from getting the asset details.

    .PARAMETER Path
        The path to the file to upload as a new asset.

    .PARAMETER Label
        An alternate short description of the asset.  Used in place of the filename.

    .PARAMETER ContentType
        The MIME Media Type for the file being uploaded.  By default, this will be inferred based
        on the file's extension.  If the extension is not known by this module, it will fallback to
        using text/plain.  You may specify a ContentType here to override the module's logic.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        New-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Release 123456 -Path 'c:\foo.zip'

        Uploads the file located at 'c:\foo.zip' to the 123456 release in microsoft/PowerShellForGitHub

    .EXAMPLE
        $release = New-GitHubRelease -OwnerName microsoft -RepositoryName PowerShellForGitHub -Tag 'stable'
        $release | New-GitHubReleaseAsset -Path 'c:\bar.txt'

        Creates a new release tagged as 'stable' and then uploads 'c:\bar.txt' as an asset for
        that release.

    .NOTES
        GitHub renames asset filenames that have special characters, non-alphanumeric characters,
        and leading or trailing periods. Get-GitHubReleaseAsset lists the renamed filenames.

        If you upload an asset with the same filename as another uploaded asset, you'll receive
        an error and must delete the old file before you can re-upload the new asset.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Elements',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 2)]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl')]
        [Alias('ReleaseId')]
        [int64] $Release,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UploadUrl',
            Position = 1)]
        [string] $UploadUrl,

        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateScript(
            {if (Test-Path -Path $_ -PathType Leaf) { $true }
            else { throw "$_ does not exist or is inaccessible." }})]
        [string] $Path,

        [string] $Label,

        [string] $ContentType,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        'ProvidedUploadUrl' = ($PSBoundParameters.ContainsKey('UploadUrl'))
        'ProvidedLabel' = ($PSBoundParameters.ContainsKey('Label'))
        'ProvidedContentType' = ($PSBoundParameters.ContainsKey('ContentType'))
    }

    # If UploadUrl wasn't provided, we'll need to query for it first.
    if ([String]::IsNullOrEmpty($UploadUrl))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties['OwnerName'] = (Get-PiiSafeString -PlainText $OwnerName)
        $telemetryProperties['RepositoryName'] = (Get-PiiSafeString -PlainText $RepositoryName)

        $params = @{
            'OwnerName' = $OwnerName
            'RepositoryName' = $RepositoryName
            'Release' = $Release
            'AccessToken' = $AccessToken
        }

        $releaseInfo = Get-GitHubRelease @params
        $UploadUrl = $releaseInfo.upload_url
    }

    # Remove the '{name,label}' from the Url if it's there
    if ($UploadUrl -match '(.*){')
    {
        $UploadUrl = $Matches[1]
    }

    $Path = Resolve-UnverifiedPath -Path $Path
    $file = Get-Item -Path $Path
    $fileName = $file.Name
    $fileNameEncoded = [Uri]::EscapeDataString($fileName)
    $queryParams = @("name=$fileNameEncoded")

    if ($PSBoundParameters.ContainsKey('Label'))
    {
        $labelEncoded = [Uri]::EscapeDataString($Label)
        $queryParams += "label=$labelEncoded"
    }

    if (-not $PSCmdlet.ShouldProcess($Path, "Create new GitHub Release Asset"))
    {
        return
    }

    $params = @{
        'UriFragment' = $UploadUrl + '?' + ($queryParams -join '&')
        'Method' = 'Post'
        'Description' = "Uploading release asset: $fileName"
        'InFile' = $Path
        'ContentType' = $ContentType
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubReleaseAssetAdditionalProperties)
}

filter Set-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Edits an existing asset for a release on GitHub.

    .DESCRIPTION
        Edits an existing asset for a release on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Asset
        The ID of the asset being updated.

    .PARAMETER Name
        The new filename of the asset.

    .PARAMETER Label
        An alternate short description of the asset.  Used in place of the filename.

    .PARAMETER PassThru
        Returns the updated Release Asset.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.ReleaseAsset

    .EXAMPLE
        Set-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 123456 -Name bar.zip

        Renames the asset 123456 to be 'bar.zip'.

    .NOTES
        Requires push access to the repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubReleaseAssetTypeName})]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [string] $Name,

        [string] $Label,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedName' = ($PSBoundParameters.ContainsKey('Name'))
        'ProvidedLabel' = ($PSBoundParameters.ContainsKey('Label'))
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Name')) { $hashBody['name'] = $Name }
    if ($PSBoundParameters.ContainsKey('Label')) { $hashBody['label'] = $Label }

    if (-not $PSCmdlet.ShouldProcess($Asset, "Update GitHub Release Asset"))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Editing asset $Asset"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubReleaseAssetAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubReleaseAsset
{
<#
    .SYNOPSIS
        Removes an asset from a release on GitHub.

    .DESCRIPTION
        Removes an asset from a release on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER Asset
        The ID of the asset to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Branch
        GitHub.Content
        GitHub.Event
        GitHub.Issue
        GitHub.IssueComment
        GitHub.Label
        GitHub.Milestone
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890

    .EXAMPLE
        Remove-GitHubReleaseAsset -OwnerName microsoft -RepositoryName PowerShellForGitHub -Asset 1234567890 -Confirm:$false

        Will not prompt for confirmation, as -Confirm:$false was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact='High')]
    [Alias('Delete-GitHubReleaseAsset')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri',
            Position = 1)]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('AssetId')]
        [int64] $Asset,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/releases/assets/$Asset"
        'Method' = 'Delete'
        'Description' = "Deleting asset $Asset"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Asset, "Delete GitHub Release Asset"))
    {
        return
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubReleaseAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Release objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Release
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubReleaseTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if (-not [String]::IsNullOrEmpty($item.html_url))
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'ReleaseId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'UploadUrl' -Value $item.upload_url -MemberType NoteProperty -Force

            if ($null -ne $item.author)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.author
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubReleaseAssetAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Release Asset objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.ReleaseAsset
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubReleaseAssetTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'AssetId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.uploader)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.uploader
            }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInmAYJKoZIhvcNAQcCoIIniTCCJ4UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDQm35nX5jiXyCp
# pA/dQ7I2irZNuoqduXf7vV+b/SjTPqCCDXYwggX0MIID3KADAgECAhMzAAACURR2
# zMWFg24LAAAAAAJRMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDBIpXR3b1IYAMunV9ZYBVYsaA7S64mqacKy/OJUf0Lr/LW/tWlJDzJH9nFAhs0
# zzSdQQcLhShOSTUxtlwZD9dnfIcx4pZgu0VHkqQw2dVc8Ob21GBo5sVrXgEAQxZo
# rlEuAl20KpSIFLUBwoZFGFSQNSMcqPudXOw+Mhvn6rXYv/pjXIjgBntn6p1f+0+C
# 2NXuFrIwjJIJd0erGefwMg//VqUTcRaj6SiCXSY6kjO1J9P8oaRQBHIOFEfLlXQ3
# a1ATlM7evCUvg3iBprpL+j1JMAUVv+87NRApprPyV75U/FKLlO2ioDbb69e3S725
# XQLW+/nJM4ihVQ0BHadh74/lAgMBAAGjggFzMIIBbzAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUMLgM7NX5EnpPfK5uU6FPvn2g/Ekw
# RQYDVR0RBD4wPKQ6MDgxHjAcBgNVBAsTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEW
# MBQGA1UEBRMNMjMwMDEyKzQ2NzU5NjAfBgNVHSMEGDAWgBRIbmTlUAXTgqoXNzci
# tW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3JsMGEG
# CCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDExXzIwMTEtMDctMDguY3J0
# MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIBAIVJlff+Fp0ylEJhmvap
# NVv1bYLSWf58OqRRIDnXbHQ+FobsOwL83/ncPC3xl8ySR5uK/af4ZDy7DcDw0yEd
# mKbRLzHIfcztZVSrlsg0GKwZuaB2MEI1VizNCoZlN+HlFZa4DNm3J0LhTWrZjVR0
# M6V57cFW0GsV4NlqmtelT9JFEae7PomwgAV9xOScz8HzvbZeERcoSRp9eRsQwOw7
# 8XeCLeglqjUnz9gFM7RliCYP58Fgphtkht9LNEcErLOVW17m6/Dj75zg/IS+//6G
# FEK2oXnw5EIIWZraFHqSaee+NMgOw/R6bwB8qLv5ClOJEpGKA3XPJvS9YgOpF920
# Vu4Afqa5Rv5UJKrsxA7HOiuH4TwpkP3XQ801YLMp4LavXnvqNkX5lhFcITvb01GQ
# lcC5h+XfCv0L4hUum/QrFLavQXJ/vtirCnte5Bediqmjx3lswaTRbr/j+KX833A1
# l9NIJmdGFcVLXp1en3IWG/fjLIuP7BqPPaN7A1tzhWxL+xx9yw5vQiT1Yn14YGmw
# OzBYYLX0H9dKRLWMxMXGvo0PWEuXzYyrdDQExPf66Fq/EiRpZv2EYl2gbl9fxc3s
# qoIkyNlL1BCrvmzunkwt4cwvqWremUtqTJ2B53MbBHlf4RfvKz9NVuh5KHdr82AS
# MMjU4C8KNTqzgisqQdCy8unTMIIHejCCBWKgAwIBAgIKYQ6Q0gAAAAAAAzANBgkq
# hkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5
# IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEwOTA5WjB+MQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYDVQQDEx9NaWNyb3NvZnQg
# Q29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIIC
# CgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+laUKq4BjgaBEm6f8MMHt03
# a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc6Whe0t+bU7IKLMOv2akr
# rnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4Ddato88tt8zpcoRb0Rrrg
# OGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+lD3v++MrWhAfTVYoonpy
# 4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nkkDstrjNYxbc+/jLTswM9
# sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6A4aN91/w0FK/jJSHvMAh
# dCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmdX4jiJV3TIUs+UsS1Vz8k
# A/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL5zmhD+kjSbwYuER8ReTB
# w3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zdsGbiwZeBe+3W7UvnSSmn
# Eyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3T8HhhUSJxAlMxdSlQy90
# lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS4NaIjAsCAwEAAaOCAe0w
# ggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRIbmTlUAXTgqoXNzcitW2o
# ynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMCAYYwDwYD
# VR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBDuRQFTuHqp8cx0SOJNDBa
# BgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2Ny
# bC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3JsMF4GCCsG
# AQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFfMDNfMjIuY3J0MIGfBgNV
# HSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEFBQcCARYzaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1hcnljcHMuaHRtMEAGCCsG
# AQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkAYwB5AF8AcwB0AGEAdABl
# AG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn8oalmOBUeRou09h0ZyKb
# C5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7v0epo/Np22O/IjWll11l
# hJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0bpdS1HXeUOeLpZMlEPXh6
# I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/KmtYSWMfCWluWpiW5IP0
# wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvyCInWH8MyGOLwxS3OW560
# STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBpmLJZiWhub6e3dMNABQam
# ASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJihsMdYzaXht/a8/jyFqGa
# J+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYbBL7fQccOKO7eZS/sl/ah
# XJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbSoqKfenoi+kiVH6v7RyOA
# 9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sLgOppO6/8MO0ETI7f33Vt
# Y5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtXcVZOSEXAQsmbdlsKgEhr
# /Xmfwb1tbWrJUnMTDXpQzTGCGXgwghl0AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAJRFHbMxYWDbgsAAAAAAlEwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILPgoHBcUZ5k78aGaquVudl1
# yJlvWTL22EZ4Nw5CtUi+MEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBAsiQps3eSQpteozybI3aLfBazK4zK5zsYWiyh0+wNOa/mA7m43dfP
# CXysaN/Gn70QouSVCA1XADRfdgFUEbuBUrrCw39q9XXFmlGxjyolIH5rbCJwFtqT
# DVjJS2zxfY0D4NGKe7Bf9BnBM5CKqrGh8MUlXBrZKhiBLRpYq8vU+WPCAZ9bhIFQ
# OohswlhLOqofoELLEL835ftlyrDquDjoKalcDNvsov1ybKhIle/yfrjf85ggcYel
# rK5fZgHVDTT1rHBmYX2FNlm1Nr2tBIfN5hOho245dGrogouwnZOVdgo4ChnOMM5D
# Y53Qz/WyY09os70zfaUNKoggr4sZdDxhoYIXADCCFvwGCisGAQQBgjcDAwExghbs
# MIIW6AYJKoZIhvcNAQcCoIIW2TCCFtUCAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEIOBHSCXAOynwQZQnJngBz/KmAEqXef2qYzkNdR6NVUqCAgZi1tCj
# gbcYEzIwMjIwNzI1MTcyNjIyLjgzNlowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkU1QTYt
# RTI3Qy01OTJFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVzCCBwwwggT0oAMCAQICEzMAAAGVt/wN1uM3MSUAAQAAAZUwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjExMjAyMTkw
# NTEyWhcNMjMwMjI4MTkwNTEyWjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTVBNi1FMjdDLTU5MkUxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCfbUEMZ7ZLOz9aoRCeJL4hhT9Q8JZB2xaVlMNCt3bw
# hcTI5GLPrt2e93DAsmlqOzw1cFiPPg6S5sLCXz7LbbUQpLha8S4v2qccMtTokEaD
# QS+QJErnAsl6VSmRvAy0nlj+C/PaZuLb3OzY0ARw7UeCZLpyWPPH+k5MdYj6NUDT
# NoXqbzQHCuPs+fgIoro5y3DHoO077g6Ir2THIx1yfVFEt5zDcFPOYMg4yBi4A6Xc
# 3hm9tZ6w849nBvVKwm5YALfH3y/f3n4LnN61b1wzAx3ZCZjf13UKbpE7p6DYJrHR
# B/+pwFjG99TwHH6uXzDeZT6/r6qH7AABwn8fpYc1TmleFY8YRuVzzjp9VkPHV8Vz
# vzLL7QK2kteeXLL/Y4lvjL6hzyOmE+1LVD3lEbYho1zCt+F7bU+FpjyBfTC4i/wH
# sptb218YlbkQt1i1B6llmJwVFwCLX7gxQ48QIGUacMy8kp1+zczY+SxlpaEgNmQk
# fc1raPh9y5sMa6X48+x0K7B8OqDoXcTiECIjJetxwtuBlQseJ05HRfisfgFm09kG
# 7vdHEo3NbUuMMBFikc4boN9Ufm0iUhq/JtqV0Kwrv9Cv3ayDgdNwEWiL2a65InEW
# SpRTYfsCQ03eqEh5A3rwV/KfUFcit+DrP+9VcDpjWRsCokZv4tgn5qAXNMtHa8Ni
# qQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFKuX02ICFFdXgrcCBmDJfH5v/KkXMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBAOCzNt4fJ+jOvQuq0Itn37IZrYNBGswAi+IAFM3YGK/wGQlEncgjmNBuac95
# W2fAL6xtFVfMfkeqSLMLqoidVsU9Bm4DEBjaWNOT9uX/tcYiJSfFQM0rDbrl8V4n
# M88RZF56G/qJW9g5dIqOSoimzKUt/Q7WH6VByW0sar5wGvgovK3qFadwKShzRYcE
# qTkHH2zip5e73jezPHx2+taYqJG5xJzdDErZ1nMixRjaHs3KpcsmZYuxsIRfBYOJ
# vAFGymTGRv5PuwsNps9Ech1Aasq84H/Y/8xN3GQj4P3MiDn8izUBDCuXIfHYk39b
# qnaAmFbUiCby+WWpuzdk4oDKz/sWwrnsoQ72uEGVEN7+kyw9+HSo5i8l8Zg1Ymj9
# tUgDpVUGjAduoLyHQ7XqknKmS9kJSBKk4okEDg0Id6LeKLQwH1e4aVeTyUYwcBX3
# wg7pLJQWvR7na2SGrtl/23YGQTudmWOryhx9lnU7KBGV/aNvz0tTpcsucsK+cZFK
# DEkWB/oUFVrtyun6ND5pYZNj0CgRup5grVACq/Agb+EOGLCD+zEtGNop4tfKvsYb
# 64257NJ9XrMHgpCib76WT34RPmCBByxLUkHxHq5zCyYNu0IFXAt1AVicw14M+czL
# YIVM7NOyVpFdcB1B9MiJik7peSii0XTRdl5/V/KscTaCBFz3MIIHcTCCBVmgAwIB
# AgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1
# WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O
# 1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZn
# hUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t
# 1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxq
# D89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmP
# frVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSW
# rAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv
# 231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zb
# r17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYcten
# IPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQc
# xWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17a
# j54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQAB
# MCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQU
# n6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEw
# QTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9E
# b2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQB
# gjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/
# MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJ
# oEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01p
# Y1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYB
# BQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9v
# Q2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3h
# LB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x
# 5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74p
# y27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1A
# oL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbC
# HcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB
# 9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNt
# yo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3
# rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcV
# v7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A24
# 5oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lw
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjpFNUE2LUUyN0MtNTkyRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA0Y+CyLezGgVHWFNmKI1LuE/hY6ug
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOaJN/4wIhgPMjAyMjA3MjUyMzQwNDZaGA8yMDIyMDcyNjIzNDA0Nlow
# dzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5ok3/gIBADAKAgEAAgIU3QIB/zAHAgEA
# AgIRszAKAgUA5oqJfgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMC
# oAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBABPfE8Vs
# a+CiawsU1rmvB5685sCHk+cpA7kqsr1nz3wxstYejYV6HbsjO5sNN5VdUuHISdby
# PTpzBJ+274AutqloXUVCaD2UtLFRGxco1dwmwCCzoE2dlTaCo3ZYqJQZdSBrIBDe
# 2DdXCQBuERIYmRn3LFzQT4aFEeiZkDojMnMQMYIEDTCCBAkCAQEwgZMwfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGVt/wN1uM3MSUAAQAAAZUwDQYJ
# YIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkq
# hkiG9w0BCQQxIgQgFTZeFwYw1vge49e2vCSDMLxvAVyewGa8S1M89KuQGSQwgfoG
# CyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBc5kvhjZALe2mhIz/Qd7keVOmA/cC1
# dzKZT4ybLEkCxzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# AhMzAAABlbf8DdbjNzElAAEAAAGVMCIEIDIk6TMvnpaolLoQ4StUJjjT/MRcdrUq
# 7WYL2gh5fmBqMA0GCSqGSIb3DQEBCwUABIICAFIyPx/5kCruFVCKryBdMOuUJiuk
# uB+Ko9uSH6U9LNCtBgltS9uDoa0IkH0LeHPawC24pXoOeYKr27EmYKsz/vgiIMRW
# ff50wGqEn0wF0HZDvTa818aDGHgeZa79cmHFwxZWxjjuwUTupii2AXWxZ3r3DQ+1
# rdmG3fjgOUz0RWv6H+xFCm7Gf/xdUlQfJz96kTOXaUXcql+SHGwk9jjWYHjSwfnA
# pMzeit6ZwBcPE6paFfeMZ/5zMLXL2TXTLB6CzFIdiUyDl1E8CfAiCFoNqzzEkCKI
# MytzVqyHj7jajuBoZZZVrsAqV50jp89AJ+f0EZudV4ldpfHLnKs+LaRsizfYv+sJ
# iYrmchN4WbrctVdWzxx3x80hWrqBtOZ254esAp4G+IIPJ4y4P7s1WdHDnndCiPBl
# nUZXeoEBZ+nKODyP2areDYc9P6ctqa6leZWLD7f0Ru5ACpbIGEXCHj1dlCHeP+Re
# 0SotbN5tLB1YKpJNsRcxJ06vyzNwsv9CRb0kpb2PBG9XEhIcZz987y8WZcTARWur
# yO+a/GAegmCW9mYj/6FGuhAkLy5UQmY8793CG3T+iLUvQLN0xADOB9vngVNAnepZ
# emMDgu6b+HWmI2kZVYujaANnqhc+AyLu1lEaMNCQz955mQV59Z1TYFzTh8bPcLFd
# Iz2osiEtb3Mctm1w
# SIG # End signature block

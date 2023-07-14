# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubRepositoryActionsPermissionTypeName = 'GitHub.RepositoryActionsPermission'
    GitHubRepositoryTypeName = 'GitHub.Repository'
    GitHubRepositoryTopicTypeName = 'GitHub.RepositoryTopic'
    GitHubRepositoryContributorTypeName = 'GitHub.RepositoryContributor'
    GitHubRepositoryCollaboratorTypeName = 'GitHub.RepositoryCollaborator'
    GitHubRepositoryContributorStatisticsTypeName = 'GitHub.RepositoryContributorStatistics'
    GitHubRepositoryLanguageTypeName = 'GitHub.RepositoryLanguage'
    GitHubRepositoryTagTypeName = 'GitHub.RepositoryTag'
    GitHubRepositoryTeamPermissionTypeName = 'GitHub.RepositoryTeamPermission'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter New-GitHubRepository
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub.

    .DESCRIPTION
        Creates a new repository on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER RepositoryName
        Name of the repository to be created.

    .PARAMETER OrganizationName
        Name of the organization that the repository should be created under.
        If not specified, will be created under the current user's account.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER GitIgnoreTemplate
        Desired language or platform .gitignore template to apply.
        For supported values, call Get-GitHubGitIgnore.
        Values are case-sensitive.

    .PARAMETER LicenseTemplate
        Choose an open source license template that best suits your needs.
        For supported values, call Get-GitHubLicense
        Values are case-sensitive.

    .PARAMETER TeamId
        The id of the team that will be granted access to this repository.
        This is only valid when creating a repository in an organization.

    .PARAMETER Private
        By default, this repository will be created Public.  Specify this to create
        a private repository.

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER AutoInit
        Specify this to create an initial commit with an empty README.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DeleteBranchOnMerge
        Specifies the automatic deleting of head branches when pull requests are merged.

    .PARAMETER IsTemplate
        Specifies whether the repository is made available as a template.

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
        GitHub.Repository

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -AutoInit

    .EXAMPLE
        'MyNewRepo' | New-GitHubRepository -AutoInit

    .EXAMPLE
        New-GitHubRepository -RepositoryName MyNewRepo -Organization MyOrg -DisallowRebaseMerge
#>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType({$script:GitHubRepositoryTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Name')]
        [string] $RepositoryName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $OrganizationName,

        [string] $Description,

        [string] $Homepage,

        [string] $GitIgnoreTemplate,

        [string] $LicenseTemplate,

        [int64] $TeamId,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $AutoInit,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [switch] $DeleteBranchOnMerge,

        [switch] $IsTemplate,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = 'user/repos'
    if ($PSBoundParameters.ContainsKey('OrganizationName') -and
        (-not [String]::IsNullOrEmpty($OrganizationName)))
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName
        $uriFragment = "orgs/$OrganizationName/repos"
    }

    if ($PSBoundParameters.ContainsKey('TeamId') -and (-not $PSBoundParameters.ContainsKey('OrganizationName')))
    {
        $message = 'TeamId may only be specified when creating a repository under an organization.'
        Write-Log -Message $message -Level Error
        throw $message
    }

    $hashBody = @{
        'name' = $RepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('GitIgnoreTemplate')) { $hashBody['gitignore_template'] = $GitIgnoreTemplate }
    if ($PSBoundParameters.ContainsKey('LicenseTemplate')) { $hashBody['license_template'] = $LicenseTemplate }
    if ($PSBoundParameters.ContainsKey('TeamId')) { $hashBody['team_id'] = $TeamId }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('AutoInit')) { $hashBody['auto_init'] = $AutoInit.ToBool() }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DeleteBranchOnMerge')) { $hashBody['delete_branch_on_merge'] = $DeleteBranchOnMerge.ToBool() }
    if ($PSBoundParameters.ContainsKey('IsTemplate')) { $hashBody['is_template'] = $IsTemplate.ToBool() }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Create GitHub Repository'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'AcceptHeader' = $script:baptisteAcceptHeader
        'Description' = "Creating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter New-GitHubRepositoryFromTemplate
{
<#
    .SYNOPSIS
        Creates a new repository on GitHub from a template repository.

    .DESCRIPTION
        Creates a new repository on GitHub from a template repository.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the template repository.
        If no value is specified, the DefaultOwnerName configuration property value will be used,
        and if there is no configuration value defined, the current authenticated user will be used.

    .PARAMETER RepositoryName
        Name of the template repository.

    .PARAMETER Uri
        Uri for the repository.
        The OwnerName and RepositoryName will be extracted from here instead of needing to provide
        them individually.

    .PARAMETER TargetOwnerName
        The organization or person who will own the new repository.
        To create a new repository in an organization, the authenticated user must be a member
        of the specified organization.

    .PARAMETER TargetRepositoryName
        Name of the repository to be created.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Private
        By default, this repository will created Public.  Specify this to create a private
        repository.

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
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .NOTES
        The authenticated user must own or be a member of an organization that owns the repository.

        To check if a repository is available to use as a template, call `Get-GitHubRepository` on the
        repository in question and check that the is_template property is $true.

    .EXAMPLE
        New-GitHubRepositoryFromTemplate -OwnerName MyOrg -RepositoryName MyTemplateRepo -TargetRepositoryName MyNewRepo -TargetOwnerName Me

        Creates a new GitHub repository from the specified template repository.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName MyOrg -RepositoryName MyTemplateRepo
        $repo | New-GitHubRepositoryFromTemplate -TargetRepositoryName MyNewRepo -TargetOwnerName Me

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubRepositoryTypeName})]
    param(
        [Parameter(ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Elements')]
        [ValidateNotNullOrEmpty()]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 2,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetOwnerName,

        [Parameter(
            Mandatory,
            Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string] $TargetRepositoryName,

        [string] $Description,

        [switch] $Private,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        RepositoryName = (Get-PiiSafeString -PlainText $RepositoryName)
        OwnerName = (Get-PiiSafeString -PlainText $OwnerName)
        TargetRepositoryName = (Get-PiiSafeString -PlainText $TargetRepositoryName)
        TargetOwnerName = (Get-PiiSafeString -PlainText $TargetOwnerName)
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/generate"

    $hashBody = @{
        owner = $TargetOwnerName
        name = $TargetRepositoryName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }

    if (-not $PSCmdlet.ShouldProcess(
        $TargetRepositoryName,
        "Create GitHub Repository From Template $RepositoryName"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating $TargetRepositoryName from Template"
        'AcceptHeader' = $script:baptisteAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Remove-GitHubRepository
{
<#
    .SYNOPSIS
        Removes/deletes a repository from GitHub.

    .DESCRIPTION
        Removes/deletes a repository from GitHub.

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
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .EXAMPLE
        Remove-GitHubRepository -OwnerName You -RepositoryName YourRepoToDelete

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete -Confirm:$false

        Remove repository with the given URI, without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubRepository -Uri https://github.com/You/YourRepoToDelete -Force

        Remove repository with the given URI, without prompting for confirmation.

    .EXAMPLE
        $repo = Get-GitHubRepository -Uri https://github.com/You/YourRepoToDelete
        $repo | Remove-GitHubRepository -Force

        You can also pipe in a repo that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubRepository')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

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

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Remove GitHub Repository'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName"
        'Method' = 'Delete'
        'Description' = "Deleting $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Get-GitHubRepository
{
<#
    .SYNOPSIS
        Retrieves information about a repository or list of repositories on GitHub.

    .DESCRIPTION
        Retrieves information about a repository or list of repositories on GitHub.

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

    .PARAMETER OrganizationName
        The name of the organization to retrieve the repositories for.

    .PARAMETER Visibility
        The type of visibility/accessibility for the repositories to return.

    .PARAMETER Affiliation
        Can be one or more of:

        owner - Repositories that are owned by the authenticated user

        collaborator - Repositories that the user has been added to as a collaborator

        organization_member - Repositories that the user has access to through being
        a member of an organization.  This includes every repository on every team that the user
        is on.

    .PARAMETER Type
        The type of repository to return.

    .PARAMETER Sort
        Property that the results should be sorted by

    .PARAMETER Direction
        Direction of the sort that is to be applied to the results.

    .PARAMETER GetAllPublicRepositories
        If this is specified with no other parameter, then instead of returning back all
        repositories for the current authenticated user, it will instead return back all
        public repositories on GitHub in the order in which they were created.

    .PARAMETER Since
        The ID of the last public repository that you have seen.  If specified with
        -GetAllPublicRepositories, will only return back public repositories created _after_ this
        one.

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
        GitHub.Repository

    .EXAMPLE
        Get-GitHubRepository

        Gets all repositories for the current authenticated user.

    .EXAMPLE
        Get-GitHubRepository -GetAllPublicRepositories

        Gets all public repositories on GitHub.

    .EXAMPLE
        Get-GitHubRepository -OwnerName octocat

        Gets all of the repositories for the user octocat

    .EXAMPLE
        Get-GitHubUser -UserName octocat | Get-GitHubRepository

        Gets all of the repositories for the user octocat

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/microsoft/PowerShellForGitHub

        Gets information about the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        $repo | Get-GitHubRepository

        You can pipe in a previous repository to get its refreshed information.

    .EXAMPLE
        Get-GitHubRepository -OrganizationName PowerShell

        Gets all of the repositories in the PowerShell organization.
#>
    [CmdletBinding(DefaultParameterSetName = 'AuthenticatedUser')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    param(
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsOrUser')]
        [Alias('UserName')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsOrUser')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [string] $OrganizationName,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [ValidateSet('All', 'Public', 'Private')]
        [string] $Visibility,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [ValidateSet('Owner', 'Collaborator', 'OrganizationMember')]
        [string[]] $Affiliation,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('All', 'Owner', 'Public', 'Private', 'Member', 'Forks', 'Sources')]
        [string] $Type,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('Created', 'Updated', 'Pushed', 'FullName')]
        [string] $Sort,

        [Parameter(ParameterSetName='AuthenticatedUser')]
        [Parameter(ParameterSetName='ElementsOrUser')]
        [Parameter(ParameterSetName='Organization')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [Parameter(ParameterSetName='PublicRepos')]
        [switch] $GetAllPublicRepositories,

        [Parameter(ParameterSetName='PublicRepos')]
        [int64] $Since,

        [string] $AccessToken
    )

    Write-InvocationLog

    # We are explicitly disabling validation here because a valid parameter set for this function
    # allows the OwnerName to be passed in, but not the RepositoryName.  That would allow the caller
    # to get all of the repositories owned by a specific username.  Therefore, we don't want to fail
    # if both have not been supplied...we'll do the extra validation within the function.
    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'UsageType' = $PSCmdlet.ParameterSetName
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    switch ($PSCmdlet.ParameterSetName)
    {
        'ElementsOrUser' {
            # This is a little tricky.  Ideally we'd have two separate ParameterSets (Elements, User),
            # however PowerShell would be unable to disambiguate between the two, so unfortunately
            # we need to do some additional work here.  And because fallthru doesn't appear to be
            # working right, we're combining both of those.

            if ([String]::IsNullOrWhiteSpace($OwnerName))
            {
                $message = 'OwnerName could not be determined.'
                Write-Log -Message $message -Level Error
                throw $message
            }
            elseif ([String]::IsNullOrWhiteSpace($RepositoryName))
            {
                $telemetryProperties['UsageType'] = 'User'
                $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName

                $uriFragment = "users/$OwnerName/repos"
                $description = "Getting repos for $OwnerName"
            }
            else
            {
                if ($PSBoundParameters.ContainsKey('Type') -or
                    $PSBoundParameters.ContainsKey('Sort') -or
                    $PSBoundParameters.ContainsKey('Direction'))
                {
                    $message = 'Unable to specify -Type, -Sort and/or -Direction when retrieving a specific repository.'
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $telemetryProperties['UsageType'] = 'Elements'
                $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
                $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

                $uriFragment = "repos/$OwnerName/$RepositoryName"
                $description = "Getting $OwnerName/$RepositoryName"
            }

            break
        }

        'Uri' {
            if ($PSBoundParameters.ContainsKey('Type') -or
                $PSBoundParameters.ContainsKey('Sort') -or
                $PSBoundParameters.ContainsKey('Direction'))
            {
                $message = 'Unable to specify -Type, -Sort and/or -Direction when retrieving a specific repository.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
            $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

            $uriFragment = "repos/$OwnerName/$RepositoryName"
            $description = "Getting $OwnerName/$RepositoryName"

            break
        }

        'Organization' {
            $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

            $uriFragment = "orgs/$OrganizationName/repos"
            $description = "Getting repos for $OrganizationName"

            break
        }

        'AuthenticatedUser' {
            if ($PSBoundParameters.ContainsKey('Type') -and
                ($PSBoundParameters.ContainsKey('Visibility') -or
                $PSBoundParameters.ContainsKey('Affiliation')))
            {
                $message = 'Unable to specify -Type when using -Visibility and/or -Affiliation.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $uriFragment = 'user/repos'
            $description = 'Getting repos for current authenticated user'

            break
        }

        'PublicRepos' {
            $uriFragment = 'repositories'
            $description = "Getting all public repositories"

            if ($PSBoundParameters.ContainsKey('Since'))
            {
                $description += " since $Since"
            }

            break
        }
    }

    $sortConverter = @{
        'Created' = 'created'
        'Updated' = 'updated'
        'Pushed' = 'pushed'
        'FullName' = 'full_name'
    }

    $directionConverter = @{
        'Ascending' = 'asc'
        'Descending' = 'desc'
    }

    $getParams = @()
    if ($PSBoundParameters.ContainsKey('Visibility')) { $getParams += "visibility=$($Visibility.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Sort')) { $getParams += "sort=$($sortConverter[$Sort])" }
    if ($PSBoundParameters.ContainsKey('Type')) { $getParams += "type=$($Type.ToLower())" }
    if ($PSBoundParameters.ContainsKey('Direction')) { $getParams += "direction=$($directionConverter[$Direction])" }
    if ($PSBoundParameters.ContainsKey('Affiliation') -and $Affiliation.Count -gt 0)
    {
        $affiliationMap = @{
            Owner = 'owner'
            Collaborator = 'collaborator'
            OrganizationMember = 'organization_member'
        }
        $affiliationParam = @()

        foreach ($member in $Affiliation)
        {
            $affiliationParam += $affiliationMap[$member]
        }
        $getParams += "affiliation=$($affiliationParam -join ',')"
    }
    if ($PSBoundParameters.ContainsKey('Since')) { $getParams += "since=$Since" }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' = $description
        'AcceptHeader' = "$script:nebulaAcceptHeader,$script:baptisteAcceptHeader,$script:mercyAcceptHeader"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubRepositoryAdditionalProperties)
}

filter Rename-GitHubRepository
{
<#
    .SYNOPSIS
        Rename a GitHub repository

    .DESCRIPTION
        Renames a GitHub repository with the new name provided.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OwnerName
        Owner of the repository.
        If not supplied here, the DefaultOwnerName configuration property value will be used.

    .PARAMETER RepositoryName
        Name of the repository.
        If not supplied here, the DefaultRepositoryName configuration property value will be used.

    .PARAMETER Uri
        Uri for the repository to rename. You can supply this directly, or more easily by
        using Get-GitHubRepository to get the repository as you please,
        and then piping the result to this cmdlet.

    .PARAMETER NewName
        The new name to set for the given GitHub repository

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the renamed Repository.  By default, this cmdlet does not generate any output.
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
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Get-GitHubRepository -Owner octocat -RepositoryName hello-world | Rename-GitHubRepository -NewName hello-again-world

        Get the given 'hello-world' repo from the user 'octocat' and then
        rename it to be https://github.com/octocat/hello-again-world.

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/octocat/hello-world | Rename-GitHubRepository -NewName hello-again-world -Confirm:$false

        Get the repository at https://github.com/octocat/hello-world and then
        rename it https://github.com/octocat/hello-again-world.
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world.

    .EXAMPLE
        New-GitHubRepositoryFork -Uri https://github.com/octocat/hello-world | Foreach-Object {$_ | Rename-GitHubRepository -NewName "$($_.name)_fork"}

        Fork the `hello-world` repository from the user 'octocat', and then
        rename the newly forked repository by appending '_fork'.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world -Confirm:$false

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world without prompting for confirmation.

    .EXAMPLE
        Rename-GitHubRepository -Uri https://github.com/octocat/hello-world -NewName hello-again-world -Force

        Rename the repository at https://github.com/octocat/hello-world to
        https://github.com/octocat/hello-again-world without prompting for confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Uri',
        ConfirmImpact="High")]
    [OutputType({$script:GitHubRepositoryTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias("RepositoryUrl")]
        [string] $Uri,

        [parameter(Mandatory)]
        [String] $NewName,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    # This method was created by mistake and is now retained to avoid a breaking change.
    # Set-GitHubRepository is able to handle this scenario just fine.
    return Set-GitHubRepository @PSBoundParameters
}

filter Set-GitHubRepository
{
<#
    .SYNOPSIS
        Updates the details of an existing repository on GitHub.

    .DESCRIPTION
        Updates the details of an existing repository on GitHub.

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

    .PARAMETER NewName
        Rename the repository to this new name.

    .PARAMETER Description
        A short description of the repository.

    .PARAMETER Homepage
        A URL with more information about the repository.

    .PARAMETER DefaultBranch
        Update the default branch for this repository.

    .PARAMETER Private
        Specify this to make the repository private.
        To change a repository to be public, specify -Private:$false

    .PARAMETER NoIssues
        By default, this repository will support Issues.  Specify this to disable Issues.

    .PARAMETER NoProjects
        By default, this repository will support Projects.  Specify this to disable Projects.
        If you're creating a repository in an organization that has disabled repository projects,
        this will be true by default.

    .PARAMETER NoWiki
        By default, this repository will have a Wiki.  Specify this to disable the Wiki.

    .PARAMETER DisallowSquashMerge
        By default, squash-merging pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowMergeCommit
        By default, merging pull requests with a merge commit will be allowed.
        Specify this to disallow.

    .PARAMETER DisallowRebaseMerge
        By default, rebase-merge pull requests will be allowed.
        Specify this to disallow.

    .PARAMETER DeleteBranchOnMerge
        Specifies the automatic deleting of head branches when pull requests are merged.

    .PARAMETER IsTemplate
        Specifies whether the repository is made available as a template.

    .PARAMETER Archived
        Specify this to archive this repository.
        NOTE: You cannot unarchive repositories through the API / this module.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution
        when renaming the repository.

    .PARAMETER PassThru
        Returns the updated GitHub Repository.  By default, this cmdlet does not generate any output.
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
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Set-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub -Description 'The best way to automate your GitHub interactions'

        Changes the description of the specified repository.

    .EXAMPLE
        Set-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub -Private:$false

        Changes the visibility of the specified repository to be public.

    .EXAMPLE
        Get-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub |
            Set-GitHubRepository -NewName 'PoShForGitHub' -Force

        Renames the repository without any user confirmation prompting.  This is identical to using
        Rename-GitHubRepository -Uri https://github.com/PowerShell/PowerShellForGitHub -NewName 'PoShForGitHub' -Confirm:$false
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Alias('Update-GitHubRepository')] # Non-standard usage of the Update verb, but done to avoid a breaking change post 0.14.0
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [ValidateNotNullOrEmpty()]
        [string] $NewName,

        [string] $Description,

        [string] $Homepage,

        [string] $DefaultBranch,

        [switch] $Private,

        [switch] $NoIssues,

        [switch] $NoProjects,

        [switch] $NoWiki,

        [switch] $DisallowSquashMerge,

        [switch] $DisallowMergeCommit,

        [switch] $DisallowRebaseMerge,

        [switch] $DeleteBranchOnMerge,

        [switch] $IsTemplate,

        [switch] $Archived,

        [switch] $Force,

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
    }

    $hashBody = @{}
    $shouldProcessMessage = 'Update GitHub Repository'

    if ($PSBoundParameters.ContainsKey('NewName'))
    {
        $hashBody['name'] = $NewName
        $ConfirmPreference = 'Low'
        $shouldProcessMessage = "Rename repository to '$NewName'"
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Homepage')) { $hashBody['homepage'] = $Homepage }
    if ($PSBoundParameters.ContainsKey('DefaultBranch')) { $hashBody['default_branch'] = $DefaultBranch }
    if ($PSBoundParameters.ContainsKey('Private')) { $hashBody['private'] = $Private.ToBool() }
    if ($PSBoundParameters.ContainsKey('NoIssues')) { $hashBody['has_issues'] = (-not $NoIssues.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoProjects')) { $hashBody['has_projects'] = (-not $NoProjects.ToBool()) }
    if ($PSBoundParameters.ContainsKey('NoWiki')) { $hashBody['has_wiki'] = (-not $NoWiki.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowSquashMerge')) { $hashBody['allow_squash_merge'] = (-not $DisallowSquashMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowMergeCommit')) { $hashBody['allow_merge_commit'] = (-not $DisallowMergeCommit.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DisallowRebaseMerge')) { $hashBody['allow_rebase_merge'] = (-not $DisallowRebaseMerge.ToBool()) }
    if ($PSBoundParameters.ContainsKey('DeleteBranchOnMerge')) { $hashBody['delete_branch_on_merge'] = $DeleteBranchOnMerge.ToBool() }
    if ($PSBoundParameters.ContainsKey('IsTemplate')) { $hashBody['is_template'] = $IsTemplate.ToBool() }
    if ($PSBoundParameters.ContainsKey('Archived')) { $hashBody['archived'] = $Archived.ToBool() }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, $shouldProcessMessage))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'AcceptHeader' = $script:baptisteAcceptHeader
        'Description' = "Updating $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Get-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Retrieves information about a repository on GitHub.

    .DESCRIPTION
        Retrieves information about a repository on GitHub.

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
        GitHub.RepositoryTopic

    .EXAMPLE
        Get-GitHubRepositoryTopic -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryTopicTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

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
        'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
        'Method' = 'Get'
        'Description' = "Getting topics for $RepositoryName"
        'AcceptHeader' = $script:mercyAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTopicTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

function Set-GitHubRepositoryTopic
{
<#
    .SYNOPSIS
        Replaces all topics for a repository on GitHub.

    .DESCRIPTION
        Replaces all topics for a repository on GitHub.

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

    .PARAMETER Topic
        Array of topics to add to the repository.

    .PARAMETER Clear
        Specify this to clear all topics from the repository.

    .PARAMETER PassThru
        Returns the updated Repository Topics.  By default, this cmdlet does not generate any output.
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
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryTopic

    .EXAMPLE
        Set-GitHubRepositoryTopic -OwnerName microsoft -RepositoryName PowerShellForGitHub -Clear

    .EXAMPLE
        Set-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub -Topic ('octocat', 'powershell', 'github')

    .EXAMPLE
        ('octocat', 'powershell', 'github') | Set-GitHubRepositoryTopic -Uri https://github.com/PowerShell/PowerShellForGitHub

    .NOTES
        This is implemented as a function rather than a filter because the ValueFromPipeline
        parameter (Topic) is itself an array which we want to ensure is processed only a single time.
        This API endpoint doesn't add topics to a repository, it replaces the existing topics with
        the new set provided, so we need to make sure that we have all the requested topics available
        to us at the time that the API endpoint is called.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsName')]
    [OutputType({$script:GitHubRepositoryTopicTypeName})]
    param(
        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='ElementsName')]
        [Parameter(ParameterSetName='ElementsClear')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriName')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriClear')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='ElementsName')]
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='UriName')]
        [Alias('Name')]
        [string[]] $Topic,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsClear')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriClear')]
        [switch] $Clear,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $topics = @()
    }

    process
    {
        foreach ($value in $Topic)
        {
            $topics += $value
        }
    }

    end
    {
        Write-InvocationLog

        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName

        $telemetryProperties = @{
            'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
            'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
            'Clear' = $PSBoundParameters.ContainsKey('Clear')
        }

        if ($Clear)
        {
            $description = "Clearing topics in $RepositoryName"
        }
        else
        {
            $description = "Replacing topics in $RepositoryName"
        }

        $hashBody = @{
            'names' = $topics
        }

        if (-not $PSCmdlet.ShouldProcess(
            $RepositoryName,
            "Set GitHub Repository Topic $($Topic -join ', ')"))
        {
            return
        }

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/topics"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Put'
            'Description' = $description
            'AcceptHeader' = $script:mercyAcceptHeader
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        $result = (Invoke-GHRestMethod @params |
            Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTopicTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
}

filter Get-GitHubRepositoryContributor
{
<#
    .SYNOPSIS
        Retrieve list of contributors for a given repository.

    .DESCRIPTION
        Retrieve list of contributors for a given repository.

        GitHub identifies contributors by author email address.
        This groups contribution counts by GitHub user, which includes all associated email addresses.
        To improve performance, only the first 500 author email addresses in the repository link to
        GitHub users. The rest will appear as anonymous contributors without associated GitHub user
        information.

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

    .PARAMETER IncludeAnonymousContributors
        If specified, anonymous contributors will be included in the results.

    .PARAMETER IncludeStatistics
        If specified, each result will include statistics for the number of additions, deletions
        and commit counts, by week (excluding merge commits and empty commits).

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
        GitHub.Contributor
        GitHub.RepositoryContributorStatistics

    .EXAMPLE
        Get-GitHubRepositoryContributor -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets a list of contributors for the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryContributor -Uri 'https://github.com/PowerShell/PowerShellForGitHub' -IncludeStatistics

        Gets a list of contributors for the PowerShellForGithub repository including statistics.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryContributorTypeName})]
    [OutputType({$script:GitHubRepositoryContributorStatisticsTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [switch] $IncludeAnonymousContributors,

        [switch] $IncludeStatistics,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'IncludeAnonymousContributors' = $IncludeAnonymousContributors.ToBool()
        'IncludeStatistics' = $IncludeStatistics.ToBool()
    }

    $getParams = @()
    if ($IncludeAnonymousContributors) { $getParams += 'anon=true' }

    $uriFragment = "repos/$OwnerName/$RepositoryName/contributors"
    if ($IncludeStatistics) { $uriFragment = "repos/$OwnerName/$RepositoryName/stats/contributors" }

    $params = @{
        'UriFragment' = $uriFragment + '?' + ($getParams -join '&')
        'Description' = "Getting contributors for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $results = Invoke-GHRestMethodMultipleResult @params

    if ($IncludeStatistics)
    {
        foreach ($item in $results)
        {
            $item.PSObject.TypeNames.Insert(0, $script:GitHubRepositoryContributorStatisticsTypeName)

            if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
            {
                $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.author
            }
        }
    }
    else
    {
        $results = $results | Add-GitHubRepositoryContributorAdditionalProperties
    }

    return $results
}

filter Get-GitHubRepositoryCollaborator
{
<#
    .SYNOPSIS
        Retrieve list of collaborators for a given repository.

    .DESCRIPTION
        Retrieve list of collaborators for a given repository.

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

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .PARAMETER Affiliation
        Filter collaborators returned by their affiliation. Can be one of:
           All:     All collaborators the authenticated user can see.
           Direct:  All collaborators with permissions to an organization-owned repository,
                     regardless of organization membership status.
           Outside: All outside collaborators of an organization-owned repository.

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
        GitHub.User

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets a list of collaborators for the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryCollaborator -Uri 'https://github.com/PowerShell/PowerShellForGitHub'

        Gets a list of collaborators for the PowerShellForGithub repository.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryCollaboratorTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [ValidateSet('All', 'Direct', 'Outside')]
        [string] $Affiliation = 'All',

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

    $getParams = @(
        "affiliation=$($Affiliation.ToLower())"
    )

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/collaborators?" + ($getParams -join '&')
        'Description' = "Getting collaborators for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryCollaboratorAdditionalProperties)
}

filter Get-GitHubRepositoryLanguage
{
<#
    .SYNOPSIS
        Retrieves a list of the programming languages used in a repository on GitHub.

    .DESCRIPTION
        Retrieves a list of the programming languages used in a repository on GitHub.

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
        GitHub.RepositoryLanguage - The value shown for each language is the number
        of bytes of code written in that language.

    .EXAMPLE
        Get-GitHubRepositoryLanguage -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryLanguage -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryLanguageTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

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
        'UriFragment' = "repos/$OwnerName/$RepositoryName/languages"
        'Description' = "Getting languages for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryLanguageTypeName)
}

filter Get-GitHubRepositoryTag
{
<#
    .SYNOPSIS
        Retrieves tags for a repository on GitHub.

    .DESCRIPTION
        Retrieves tags for a repository on GitHub.

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
        GitHub.RepositoryTag

    .EXAMPLE
        Get-GitHubRepositoryTag -OwnerName microsoft -RepositoryName PowerShellForGitHub

    .EXAMPLE
        Get-GitHubRepositoryTag -Uri https://github.com/PowerShell/PowerShellForGitHub
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubRepositoryTagTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

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
        'UriFragment' = "repos/$OwnerName/$RepositoryName/tags"
        'Description' = "Getting tags for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubRepositoryAdditionalProperties -TypeName $script:GitHubRepositoryTagTypeName -OwnerName $OwnerName -RepositoryName $RepositoryName)
}

filter Move-GitHubRepositoryOwnership
{
<#
    .SYNOPSIS
        Changes the ownership of a repository on GitHub.

    .DESCRIPTION
        Changes the ownership of a repository on GitHub.

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

    .PARAMETER NewOwnerName
        The username or organization name the repository will be transferred to.

    .PARAMETER TeamId
        ID of the team or teams to add to the repository.  Teams can only be added to
        organization-owned repositories.

    .PARAMETER PassThru
        Returns the updated GitHub Repository.  By default, this cmdlet does not generate any output.
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
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository

    .OUTPUTS
        GitHub.Repository

    .EXAMPLE
        Move-GitHubRepositoryOwnership -OwnerName microsoft -RepositoryName PowerShellForGitHub -NewOwnerName OctoCat
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubRepositoryTypeName})]
    [Alias('Transfer-GitHubRepositoryOwnership')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $NewOwnerName,

        [int64[]] $TeamId,

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
    }

    $hashBody = @{
        'new_owner' = $NewOwnerName
    }

    if ($TeamId.Count -gt 0) { $hashBody['team_ids'] = @($TeamId) }

    if (-not $PSCmdlet.ShouldProcess(
        $RepositoryName,
        "Move GitHub Repository Ownership from $OwnerName to $NewOwnerName"))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/transfer"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Transferring ownership of $RepositoryName to $NewOwnerName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubRepositoryAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Test-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Retrieves the status of vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Retrieves the status of vulnerability alerts for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        System.Boolean

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Test-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Retrieves the status of vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Test-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Retrieves the status of vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
        Description = "Getting Vulnerability Alerts status for $RepositoryName"
        AcceptHeader = $script:dorianAcceptHeader
        Method = 'Get'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        Invoke-GHRestMethod @params | Out-Null
        $result = $true
    }
    catch
    {
        # Temporary code to handle current differences in exception object between PS5 and PS7
        if ($PSVersionTable.PSedition -eq 'Core')
        {
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and
                ($_.ErrorDetails.Message | ConvertFrom-Json).message -eq 'Vulnerability alerts are disabled.')
            {
                $result = $false
            }
            else
            {
                throw $_
            }
        }
        else
        {
            if ($_.Exception.Message -like '*Vulnerability alerts are disabled.*')
            {
                $result = $false
            }
            else
            {
                throw $_
            }
        }
    }

    return $result
}

filter Enable-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Enables vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Enables vulnerability alerts for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Enable-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Enables vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Enable-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Enables vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Enable Vulnerability Alerts'))
    {
        return
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
        Description =  "Enabling Vulnerability Alerts for $RepositoryName"
        AcceptHeader = $script:dorianAcceptHeader
        Method = 'Put'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Disable-GitHubRepositoryVulnerabilityAlert
{
 <#
    .SYNOPSIS
        Disables vulnerability alerts for a repository on GitHub.

    .DESCRIPTION
        Disables vulnerability alerts for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Disable-GitHubRepositoryVulnerabilityAlert -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Disables vulnerability alerts for the PowerShellForGithub repository.

    .EXAMPLE
        Disable-GitHubRepositoryVulnerabilityAlert -Uri https://github.com/PowerShell/PowerShellForGitHub

        Disables vulnerability alerts for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Disable Vulnerability Alerts'))
    {
        return
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/vulnerability-alerts"
        Description =  "Disabling Vulnerability Alerts for $RepositoryName"
        AcceptHeader = $script:dorianAcceptHeader
        Method = 'Delete'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Enable-GitHubRepositorySecurityFix
{
 <#
    .SYNOPSIS
        Enables automated security fixes for a repository on GitHub.

    .DESCRIPTION
        Enables automated security fixes for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Enable-GitHubRepositorySecurityFix -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Enables automated security fixes for the PowerShellForGitHub repository.
    .EXAMPLE
        Enable-GitHubRepositorySecurityFix -Uri https://github.com/PowerShell/PowerShellForGitHub

        Enables automated security fixes for the PowerShellForGitHub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Enable Automated Security Fixes'))
    {
        return
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/automated-security-fixes"
        Description =  "Enabling Automated Security Fixes for $RepositoryName"
        AcceptHeader = $script:londonAcceptHeader
        Method = 'Put'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params
}

filter Disable-GitHubRepositorySecurityFix
{
 <#
    .SYNOPSIS
        Disables automated security fixes for a repository on GitHub.

    .DESCRIPTION
        Disables automated security fixes for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Disable-GitHubRepositorySecurityFix -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Disables automated security fixes for the PowerShellForGithub repository.
    .EXAMPLE
        Disable-GitHubRepositorySecurityFix -Uri https://github.com/PowerShell/PowerShellForGitHub

        Disables automated security fixes for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Disable Automated Security Fixes'))
    {
        return
    }

    $params = @{
        UriFragment = "repos/$OwnerName/$RepositoryName/automated-security-fixes"
        Description =  "Disabling Automated Security Fixes for $RepositoryName"
        AcceptHeader = $script:londonAcceptHeader
        Method = 'Delete'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Get-GitHubRepositoryActionsPermission
{
 <#
    .SYNOPSIS
        Gets GitHub Actions permission for a repository on GitHub.

    .DESCRIPTION
        Gets GitHub Actions permission for a repository on GitHub.

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
        GitHub.Repository

    .OUTPUTS
        GitHub.RepositoryActionsPermission

    .NOTES
        The authenticated user must have admin access to the repository.

    .EXAMPLE
        Get-GitHubRepositoryActionsPermission -OwnerName Microsoft -RepositoryName PowerShellForGitHub

        Gets GitHub Actions permissions for the PowerShellForGithub repository.

    .EXAMPLE
        Get-GitHubRepositoryActionsPermission -Uri https://github.com/PowerShell/PowerShellForGitHub

        Gets GitHub Actions permissions for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $params = @{
        UriFragment = "/repos/$OwnerName/$RepositoryName/actions/permissions"
        Description =  "Getting GitHub Actions permissions for $RepositoryName"
        Method = 'Get'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params |
        Add-GitHubRepositoryActionsPermissionAdditionalProperties -RepositoryName $RepositoryName -OwnerName $OwnerName)
}

filter Set-GitHubRepositoryActionsPermission
{
 <#
    .SYNOPSIS
        Sets GitHub Actions permissions for a repository on GitHub.

    .DESCRIPTION
        Sets GitHub Actions permissions for a repository on GitHub.

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

    .PARAMETER AllowedActions
        The permissions policy that controls the actions that are allowed to run.
        Can be one of: 'All', 'LocalOnly', 'Selected' or 'Disabled'.

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
        GitHub.Repository

    .OUTPUTS
        None

    .NOTES
        The authenticated user must have admin access to the repository.

        If the repository belongs to an organization or enterprise that has set restrictive
        permissions at the organization or enterprise levels, such as 'AllowedActions' to 'Selected'
        actions, then you cannot override them for the repository.

    .EXAMPLE
        Set-GitHubRepositoryActionsPermission -OwnerName Microsoft -RepositoryName PowerShellForGitHub -AllowedActions All

        Sets GitHub Actions permissions to 'All' for the PowerShellForGithub repository.

    .EXAMPLE
        Set-GitHubRepositoryActionsPermission -Uri https://github.com/PowerShell/PowerShellForGitHub -AllowedActions Disabled

        Sets GitHub Actions permissions to 'Disabled' for the PowerShellForGithub repository.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    param(
        [Parameter(
            ParameterSetName='Elements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(Mandatory)]
        [ValidateSet('All', 'LocalOnly', 'Selected', 'Disabled')]
        [string] $AllowedActions,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -BoundParameters $PSBoundParameters
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $allowedActionsConverter = @{
        All = 'all'
        LocalOnly = 'local_only'
        Selected = 'selected'
        Disabled = 'disabled'
    }

    $hashBodyAllowedActions = $allowedActionsConverter[$AllowedActions]

    if ($AllowedActions -eq 'Disabled')
    {
        $hashBody = @{
            'enabled' = $false
        }
    }
    else
    {
        $hashBody = @{
            'enabled' = $true
            'allowed_actions' = $hashBodyAllowedActions
        }
    }

    if (-not $PSCmdlet.ShouldProcess($RepositoryName, 'Set GitHub Repository Actions Permissions'))
    {
        return
    }

    $params = @{
        UriFragment = "/repos/$OwnerName/$RepositoryName/actions/permissions"
        Description =  "Setting GitHub Actions permissions for $RepositoryName"
        Method = 'Put'
        Body = (ConvertTo-Json -InputObject $hashBody)
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Get-GitHubRepositoryTeamPermission
{
<#
    .SYNOPSIS
        Retrieve team permissions for a repository on GitHub.

    .DESCRIPTION
        Retrieve team permissions for a repository on GitHub.

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

    .PARAMETER TeamName
        The name of the team.
        Note: This will be slower than querying by TeamSlug since it requires retrieving
        all teams first.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team.

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
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.Team

    .OUTPUTS
        GitHub.RepositoryTeamPermission

    .EXAMPLE
        Get-GitHubRepositoryTeamPermission -Uri https://github.com/microsoft/PowerShellForGitHub -TeamName Devs

        Gets permission for the Devs team on the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        Get-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins

        Gets permission for the Admin team on the microsoft/PowerShellForGitHub repository.
#>
    [CmdletBinding(DefaultParameterSetName = 'TeamNameElements')]
    [OutputType(
        { $script:GitHubRepositoryTeamTypeName })]
    param
    (
        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamNameUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameElements')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $team = Get-GitHubTeam -OrganizationName $OwnerName |
            Where-Object -Property name -eq $TeamName

        if ($null -eq $team)
        {
            $message = "Team '$TeamName' not found"
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $TeamSlug = $team.slug
        }
    }

    $telemetryProperties['TeamSlug'] = Get-PiiSafeString -PlainText $TeamSlug

    $uriFragment = "/orgs/$OwnerName/teams/$TeamSlug/repos/$OwnerName/$RepositoryName"
    $description = "Getting team $TeamSlug permissions for repository $RepositoryName"

    $params = @{
        UriFragment = $uriFragment
        Description =  $description
        AcceptHeader = $script:repositoryAcceptHeader
        Method = 'Get'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    $result = Invoke-GHRestMethod @params

    if ($PSBoundParameters.ContainsKey('TeamSlug'))
    {
        $team = Get-GitHubTeam -OrganizationName $OwnerName -TeamSlug $TeamSlug

        $TeamName = $team.name
    }

    return ($result |
        Add-GitHubRepositoryTeamPermissionAdditionalProperties -TeamName $TeamName -TeamSlug $TeamSlug)
}

filter Set-GitHubRepositoryTeamPermission
{
<#
    .SYNOPSIS
        Sets team permission for a repository on GitHub.

    .DESCRIPTION
        Sets team permission for a repository on GitHub.

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

    .PARAMETER TeamName
        The name of the specific team to retrieve.
        Note: This will be slower than querying by TeamSlug since it requires retrieving
        all teams first.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the specific team to retrieve.

    .PARAMETER Permission
        The permission to grant the team on this repository.
        Can be one of:
        * Pull - team members can pull, but not push to or administer this repository.
        * Push - team members can pull and push, but not administer this repository.
        * Admin - team members can pull, push and administer this repository.
        * Maintain - team members can manage the repository without access to sensitive or
          destructive actions. Recommended for project managers. Only applies to repositories owned
          by organizations.
        * Triage - team members can proactively manage issues and pull requests without write access.
          Recommended for contributors who triage a repository. Only applies to repositories owned
          by organizations.
        If no permission is specified, the team's permission attribute will be used to determine
        what permission to grant the team on this repository.

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
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.Team

    .EXAMPLE
        Set-GitHubRepositoryTeamPermission -Uri https://github.com/microsoft/PowerShellForGitHub -TeamName Devs -Permission Push

        Sets the Push permission for the Devs team on the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        Set-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins -Permission Admin

        Sets the Admin permission for the Admin team on the microsoft/PowerShellForGitHub repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'TeamNameElements')]
    param(
        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamNameUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameElements')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [Parameter()]
        [ValidateSet('Pull', 'Push', 'Admin', 'Maintain', 'Triage')]
        [string]$Permission,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $team = Get-GitHubTeam -OrganizationName $OwnerName |
            Where-Object -Property name -eq $TeamName

        if ($null -eq $team)
        {
            $message = "Team '$TeamName' not found"
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $TeamSlug = $team.slug
        }
    }

    $telemetryProperties['TeamSlug'] = Get-PiiSafeString -PlainText $TeamSlug

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('Permission'))
    {
        $hashBody = @{
            permission = $Permission.ToLower()
        }
    }

    if (-not $PSCmdlet.ShouldProcess(
        $RepositoryName, "Set GitHub $Permission Repository Permissions for Team $TeamSlug"))
    {
        return
    }

    $params = @{
        UriFragment = "/orgs/$OwnerName/teams/$TeamSlug/repos/$OwnerName/$RepositoryName"
        Description =  "Setting team $TeamSlug $Permission permissions for repository $RepositoryName"
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Put'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Remove-GitHubRepositoryTeamPermission
{
<#
    .SYNOPSIS
        Removes team permission for a repository on GitHub.

    .DESCRIPTION
        Removes team permission for a repository on GitHub.

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

    .PARAMETER TeamName
        The name of the specific team to remove.
        Note: This will be slower than querying by TeamSlug since it requires retrieving
        all teams first.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the specific team to remove.

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
        GitHub.Organization
        GitHub.PullRequest
        GitHub.Project
        GitHub.ProjectCard
        GitHub.ProjectColumn
        GitHub.Reaction
        GitHub.Release
        GitHub.ReleaseAsset
        GitHub.Repository
        GitHub.Team

    .EXAMPLE
        Remove-GitHubRepositoryTeamPermission -Uri https://github.com/microsoft/PowerShellForGitHub -TeamName Devs

        Removes the permission for the Devs team on the microsoft/PowerShellForGitHub repository.

    .EXAMPLE
        Remove-GitHubRepositoryTeamPermission -OwnerName microsoft -RepositoryName PowerShellForGitHub -TeamName Admins

        Removes the permission for the Admin team on the microsoft/PowerShellForGitHub repository.

#>
[CmdletBinding(
    SupportsShouldProcess,
    DefaultParameterSetName = 'TeamNameElements',
    ConfirmImpact='High')]
    [Alias('Delete-GitHubRepositoryTeamPermission')]
    param(
        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $OwnerName,

        [Parameter(ParameterSetName = 'TeamNameElements')]
        [Parameter(ParameterSetName = 'TeamSlugElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamNameUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameElements')]
        [Parameter(
            Mandatory,
            ParameterSetName = 'TeamNameUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'TeamSlugUri')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $team = Get-GitHubTeam -OrganizationName $OwnerName |
            Where-Object -Property name -eq $TeamName

        if ($null -eq $team)
        {
            $message = "Team '$TeamName' not found"
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $TeamSlug = $team.slug
        }
    }

    $telemetryProperties['TeamSlug'] = Get-PiiSafeString -PlainText $TeamSlug

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess(
        $RepositoryName, "Remove GitHub Repository Permissions for Team $TeamSlug"))
    {
        return
    }

    $params = @{
        UriFragment = "/orgs/$OwnerName/teams/$TeamSlug/repos/$OwnerName/$RepositoryName"
        Description =  "Removing team $TeamSlug permissions from repository $RepositoryName"
        Method = 'Delete'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Add-GitHubRepositoryAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Repository
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
        [string] $TypeName = $script:GitHubRepositoryTypeName,

        [string] $OwnerName,

        [string] $RepositoryName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = [String]::Empty
            if ([String]::IsNullOrEmpty($item.html_url))
            {
                if ($PSBoundParameters.ContainsKey('OwnerName') -and
                    $PSBoundParameters.ContainsKey('RepositoryName'))
                {
                    $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                }
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
            }

            if (-not [String]::IsNullOrEmpty($repositoryUrl))
            {
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            if ($item.id -gt 0)
            {
                Add-Member -InputObject $item -Name 'RepositoryId' -Value $item.id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.owner)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.owner
            }

            if ($null -ne $item.organization)
            {
                $null = Add-GitHubOrganizationAdditionalProperties -InputObject $item.organization
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubRepositoryContributorAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Contributor objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER Name
        The name of the Contributor.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER Id
        The ID of the Contributor.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryContributor
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryContributorTypeName,

        [string] $Name,

        [int64] $Id
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)
        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $UserName = $item.login
            if ([String]::IsNullOrEmpty($UserName) -and $PSBoundParameters.ContainsKey('Name'))
            {
                $UserName = $Name
            }

            if (-not [String]::IsNullOrEmpty($UserName))
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserName'
                    Value = $UserName
                    MemberType = 'NoteProperty'
                    Force = $true
                }
                Add-Member @addMemberParms
            }

            $UserId = $item.id
            if (($UserId -eq 0) -and $PSBoundParameters.ContainsKey('Id'))
            {
                $UserId = $Id
            }

            if ($UserId -ne 0)
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserId'
                    Value = $UserId
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubRepositoryCollaboratorAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Collaborator objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER Name
        The name of the Collaborator.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER Id
        The ID of the Collaborator.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryCollaborator
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryCollaboratorTypeName,

        [string] $Name,

        [int64] $Id
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $userName = $item.login
            if ([String]::IsNullOrEmpty($userName) -and $PSBoundParameters.ContainsKey('Name'))
            {
                $userName = $Name
            }

            if (-not [String]::IsNullOrEmpty($userName))
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserName'
                    Value = $userName
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }

            $userId = $item.id
            if (($userId -eq 0) -and $PSBoundParameters.ContainsKey('Id'))
            {
                $userId = $Id
            }

            if ($userId -ne 0)
            {
                $addMemberParms = @{
                    InputObject = $item
                    Name = 'UserId'
                    Value = $userId
                    MemberType = 'NoteProperty'
                    Force = $true
                }

                Add-Member @addMemberParms
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubRepositoryActionsPermissionAdditionalProperties
{
    <#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository Actions Permissions objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryActionsPermission
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '',
        Justification='Internal helper that is definitely adding more than one property.')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryActionsPermissionTypeName,

        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)

        Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
        Add-Member -InputObject $item -Name 'RepositoryName' -Value $RepositoryName -MemberType NoteProperty -Force

        $allowedActionsConverter = @{
            all = 'All'
            local_only = 'LocalOnly'
            selected = 'Selected'
        }

        if ([String]::IsNullOrEmpty($item.allowed_actions))
        {
            $allowedActions = 'Disabled'
        }
        else
        {
            $allowedActions = $allowedActionsConverter[$item.allowed_actions]
        }

        Add-Member -InputObject $item -Name 'AllowedActions' -Value $allowedActions -MemberType NoteProperty -Force

        Write-Output $item
    }
}

filter Add-GitHubRepositoryTeamPermissionAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Repository Team Permission objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER OwnerName
        Owner of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER RepositoryName
        Name of the repository.  This information might be obtainable from InputObject, so this
        is optional based on what InputObject contains.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        PSCustomObject

    .OUTPUTS
        GitHub.RepositoryTeamPermission
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "",
        Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [string] $OwnerName,

        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $TeamName,

        [Parameter(Mandatory)]
        [string] $TeamSlug,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubRepositoryTeamPermissionTypeName
        )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = [String]::Empty
            if ([String]::IsNullOrEmpty($item.html_url))
            {
                if ($PSBoundParameters.ContainsKey('OwnerName') -and
                    $PSBoundParameters.ContainsKey('RepositoryName'))
                {
                    $repositoryUrl = (Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName)
                }
            }
            else
            {
                $elements = Split-GitHubUri -Uri $item.html_url
                $repositoryUrl = Join-GitHubUri @elements
            }

            if (-not [String]::IsNullOrEmpty($repositoryUrl))
            {
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            }

            if ($item.id -gt 0)
            {
                Add-Member -InputObject $item -Name 'RepositoryId' -Value $item.id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.owner)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.owner
            }

            if ($null -ne $item.organization)
            {
                $null = Add-GitHubOrganizationAdditionalProperties -InputObject $item.organization
            }

            Add-Member -InputObject $item -Name 'RepositoryName' -Value $item.full_name -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'TeamName' -Value $TeamName -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'TeamSlug' -Value $TeamSlug -MemberType NoteProperty -Force
        }

        if ($result.permissions.admin)
        {
            $permission = 'admin'
        }
        elseif ($result.permissions.push)
        {
            $permission = 'push'
        }
        elseif ($result.permissions.maintain)
        {
            $permission = 'maintain'
        }
        elseif ($result.permissions.triage)
        {
            $permission = 'triage'
        }
        elseif ($result.permissions.pull)
        {
            $permission = 'pull'
        }

        Add-Member -InputObject $item -Name 'Permission' -Value $permission -MemberType NoteProperty -Force

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInpAYJKoZIhvcNAQcCoIInlTCCJ5ECAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAOmLqVnncP31VP
# bKO/7v8f+z+TvrShnJlPxOBGBUAeHaCCDXYwggX0MIID3KADAgECAhMzAAACURR2
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGYQwghmAAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAJRFHbMxYWDbgsAAAAAAlEwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHfuOggDjdwqenyeBxfA9qCa
# 1HeFdGJ0r0OHWTtLO5TuMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQBH0/8nLuHeenornBkjJYMlubg+gRAEgt03OMTYelJNdqQWhsb/scWE
# zhoZXigr7euQZvzGrKvC347O1zzoZ1JFe0Js+Xai0cpSlGPACi9qfjn3TTcQ3b4J
# Zv3Z1IMHspCvzj4Fh/2C0YOidSbYz3A0XrzXtd+K8+X0FF1U6JNqwA3JJPxyszBi
# +empCWBPJFmHBibXqt3gHur5nHYU2vQWkfFf/bFhUxK63yfA9Gtmt3wExLck69Aj
# v80Dc/13ShBgEjf54vkMw9kT9HDhUVWGFXvRg4zpiSMdpiQMJEOhMyt/lnMmp6h2
# 4tsL0pxr5G/xGKxBJvAFQs9o2D4DsKYdoYIXDDCCFwgGCisGAQQBgjcDAwExghb4
# MIIW9AYJKoZIhvcNAQcCoIIW5TCCFuECAQMxDzANBglghkgBZQMEAgEFADCCAVUG
# CyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEID7Q58lGLREAxUE6AFBhSNxIsjPoZ8f8GGZ7AKpE7+NyAgZi2wZD
# 65gYEzIwMjIwNzI1MTcyNjA5LjYxM1owBIACAfSggdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0
# RDJGLUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaCCEV8wggcQMIIE+KADAgECAhMzAAABsKHjgzLojTvAAAEAAAGwMA0GCSqG
# SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMDMw
# MjE4NTE0MloXDTIzMDUxMTE4NTE0Mlowgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjo0RDJGLUUzREQtQkVF
# RjElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAJzGbTsM19KCnQc5RC7VoglySXMKLut/
# yWWPQWD6VAlJgBexVKx2n1zgX3o/xA2ZgZ/NFGcgNDRCJ7mJiOeW7xeHnoNXPlg7
# EjYWulfk3oOAj6a7O15GvckpYsvLcx+o8Se8CrfIb40EJ8W0Qx4TIXf0yDwAJ4/q
# O94dJ/hGabeJYg4Gp0G0uQmhwFovAWTHlD1ci+sp36AxT9wIhHqw/70tzMvrnDF7
# jmQjaVUPnjOgPOyFWZiVr7e6rkSl4anT1tLv23SWhXqMs14wolv4ZeQcWP84rV2F
# rr1KbwkIa0vlHjlv4xG9a6nlTRfo0CYUQDfrZOMXCI5KcAN2BZ6fVb09qtCdsWdN
# NxB0y4lwMjnuNmx85FNfzPcMZjmwAF9aRUUMLHv626I67t1+dZoVPpKqfSNmGtVt
# 9DETWkmDipnGg4+BdTplvgGVq9F3KZPDFHabxbLpSWfXW90MZXOuFH8yCMzDJNUz
# eyAqytFFyLZir3j4T1Gx7lReCOUPw1puVzbWKspV7ModZjtN/IUWdVIdk3HPp4QN
# 1wwdVvdXOsYdhG8kgjGyAZID5or7C/75hyKQb5F0Z+Ee04uY9K+sDZ3l3z8TQZWA
# fYurbZCMWWnmJVsu5V4PR5PO+U6D7tAtMvMULNYibT9+sxVZK/WQer2JJ9q3Z7lj
# Fs4lgpmfc6AVAgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQUOt8BJDcBJm4dy6ASZHrX
# IEfWNj8wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgw
# VjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUF
# BwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQsFAAOCAgEA3XPih5sNtUfAyLnlXq6MZSpCh0TF+uG+nhIJ44//cMcQGEVi
# Z2N263NwvrQjCFOni/+oxf76jcmUhcKWLXk9hhd7vfFBhZZzcF5aNs07Uligs24p
# veasFuhmJ4y82OYm1G1ORYsFndZdvF//NrYGxaXqUNlRHQlskV/pmccqO3Oi6wLH
# cPB1/WRTLJtYbIiiwE/uTFEFEL45wWD/1mTCPEkFX3hliXEypxXzdZ1k6XqGTysG
# AtLXUB7IC6CH26YygKQuXG8QjcJBAUG/9F3yNZOdbFvn7FinZyNcIVLxld7h0bEL
# fQzhIjelj+5sBKhLcaFU0vbjbmf0WENgFmnyJNiMrL7/2FYOLsgiQDbJx6Dpy1Ef
# vuRGsdL5f+jVVds5oMaKrhxgV7oEobrA6Z56nnWYN47swwouucHf0ym1DQWHy2DH
# OFRRN7yv++zes0GSCOjRRYPK7rr1Qc+O3nsd604Ogm5nR9QqhOOc2OQTrvtSgXBS
# tu5vF6W8DPcsns53cQ4gdcR1Y9Ng5IYEwxCZzzYsq9oalxlH+ZH/A6J7ZMeSNKNk
# rXPx6ppFXUxHuC3k4mzVyZNGWP/ZgcUOi2qV03m6Imytvi1kfGe6YdCh32POgWeN
# H9lfKt+d1M+q4IhJLmX0E2ZZICYEb9Q0romeMX8GZ+cbhuNsFimJga/fjjswggdx
# MIIFWaADAgECAhMzAAAAFcXna54Cm0mZAAAAAAAVMA0GCSqGSIb3DQEBCwUAMIGI
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylN
# aWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0yMTA5
# MzAxODIyMjVaFw0zMDA5MzAxODMyMjVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA5OGmTOe0ciEL
# eaLL1yR5vQ7VgtP97pwHB9KpbE51yMo1V/YBf2xK4OK9uT4XYDP/XE/HZveVU3Fa
# 4n5KWv64NmeFRiMMtY0Tz3cywBAY6GB9alKDRLemjkZrBxTzxXb1hlDcwUTIcVxR
# MTegCjhuje3XD9gmU3w5YQJ6xKr9cmmvHaus9ja+NSZk2pg7uhp7M62AW36MEByd
# Uv626GIl3GoPz130/o5Tz9bshVZN7928jaTjkY+yOSxRnOlwaQ3KNi1wjjHINSi9
# 47SHJMPgyY9+tVSP3PoFVZhtaDuaRr3tpK56KTesy+uDRedGbsoy1cCGMFxPLOJi
# ss254o2I5JasAUq7vnGpF1tnYN74kpEeHT39IM9zfUGaRnXNxF803RKJ1v2lIH1+
# /NmeRd+2ci/bfV+AutuqfjbsNkz2K26oElHovwUDo9Fzpk03dJQcNIIP8BDyt0cY
# 7afomXw/TNuvXsLz1dhzPUNOwTM5TI4CvEJoLhDqhFFG4tG9ahhaYQFzymeiXtco
# dgLiMxhy16cg8ML6EgrXY28MyTZki1ugpoMhXV8wdJGUlNi5UPkLiWHzNgY1GIRH
# 29wb0f2y1BzFa/ZcUlFdEtsluq9QBXpsxREdcu+N+VLEhReTwDwV2xo3xwgVGD94
# q0W29R6HXtqPnhZyacaue7e3PmriLq0CAwEAAaOCAd0wggHZMBIGCSsGAQQBgjcV
# AQQFAgMBAAEwIwYJKwYBBAGCNxUCBBYEFCqnUv5kxJq+gpE8RjUpzxD/LwTuMB0G
# A1UdDgQWBBSfpxVdAF5iXYP05dJlpxtTNRnpcjBcBgNVHSAEVTBTMFEGDCsGAQQB
# gjdMg30BATBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20v
# cGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# GQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMA8GA1UdEwEB
# /wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxiaNE9lJBb186aGMQwVgYDVR0f
# BE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJv
# ZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3JsMFoGCCsGAQUFBwEBBE4w
# TDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0
# cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQwDQYJKoZIhvcNAQELBQADggIB
# AJ1VffwqreEsH2cBMSRb4Z5yS/ypb+pcFLY+TkdkeLEGk5c9MTO1OdfCcTY/2mRs
# fNB1OW27DzHkwo/7bNGhlBgi7ulmZzpTTd2YurYeeNg2LpypglYAA7AFvonoaeC6
# Ce5732pvvinLbtg/SHUB2RjebYIM9W0jVOR4U3UkV7ndn/OOPcbzaN9l9qRWqveV
# tihVJ9AkvUCgvxm2EhIRXT0n4ECWOKz3+SmJw7wXsFSFQrP8DJ6LGYnn8AtqgcKB
# GUIZUnWKNsIdw2FzLixre24/LAl4FOmRsqlb30mjdAy87JGA0j3mSj5mO0+7hvoy
# GtmW9I/2kQH2zsZ0/fZMcm8Qq3UwxTSwethQ/gpY3UA8x1RtnWN0SCyxTkctwRQE
# cb9k+SS+c23Kjgm9swFXSVRk2XPXfx5bRAGOWhmRaw2fpCjcZxkoJLo4S5pu+yFU
# a2pFEUep8beuyOiJXk+d0tBMdrVXVAmxaQFEfnyhYWxz/gq77EFmPWn9y8FBSX5+
# k77L+DvktxW/tM4+pTFRhLy/AsGConsXHRWJjXD+57XQKBqJC4822rpM+Zv/Cuk0
# +CQ1ZyvgDbjmjJnW4SLq8CdCPSWU5nR0W2rRnj7tfqAxM328y+l7vzhwRNGQ8cir
# Ooo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYIC0jCCAjsCAQEwgfyh
# gdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjo0RDJGLUUzREQtQkVFRjElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAAp4vkN3fD5FN
# BVYZklZeS/JFPBiggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQUFAAIFAOaI0HswIhgPMjAyMjA3MjUxMjE5MDdaGA8yMDIy
# MDcyNjEyMTkwN1owdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5ojQewIBADAKAgEA
# AgIMowIB/zAHAgEAAgIROTAKAgUA5ooh+wIBADA2BgorBgEEAYRZCgQCMSgwJjAM
# BgorBgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEB
# BQUAA4GBACLHVyusuccutwignfZfFW74aIm7oJj5UZ5ZHNPbTtf8r7zGecP+aeoS
# iy4sIDFuzmNxke5W5z96QGvK4bHFlBdMrkFXDmBxg9yGxsoyP20AwgMSI+t6yk6x
# OWO5USKkFvd6q5H8o+m06uqYzpgJG47MDsC5GaLCXtL0eDhxeNRvMYIEDTCCBAkC
# AQEwgZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGwoeODMuiN
# O8AAAQAAAbAwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG
# 9w0BCRABBDAvBgkqhkiG9w0BCQQxIgQgCBmp61cS5RBpaB8B/d8MYrE5v+SjMC0f
# Kc1Uk08+al8wgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDNBgtDd8uf9KTj
# Gf1G67IfKmcNFJmeWTd6ilAy5xWEoDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwAhMzAAABsKHjgzLojTvAAAEAAAGwMCIEIGbzXseZg46oD9jl
# ffGITu1yOPLtxG6hMyksIiX6lOqdMA0GCSqGSIb3DQEBCwUABIICAJyAKBLnQ7K5
# 3Up7TWSgD9cwNOi4QbbrqGca/pEnI3QDLJ2TSwNo0XzyGYbK3MBlNKOGM5BZSKZ+
# BgLJd5r2ciwC4NkkLmjL1/5mIURj4nxnFc+qSAW6/dJy/mIr8qmZundH59L98Jjx
# TLTo6NNMdwuedPGQM4TBn+m5L0FVJLtrVwUwGWoo/eqw4Xoj7jpLyIe0iuCi21Cm
# bUxEwsJbSZQTOZf5SIv38Vpe7Dw6p9SqhLRS4y64ghkA8vxSWfbz46Y0u3JGEeuT
# ya23dAd+qc+bHva/lMT+r8oSflOwUp2JW/FrIDpNrbWuXjPGJ3Fuu43yqrG9lr9P
# 5HrxgINNFprpmGbqFWX9zHQa4qVrWp9Xo6LUEbA3YxpDrlwjIMTzkxamFiMR0k2U
# 8+LAKFxpTgW1xOmXxXL6A4AHKIEnVr33EbEX/UO20LRh1ICrjMfo1/JcK38L701n
# Fdq1xYJBZeR6BHI3MqZQm+AmgNqw5UBQNZX+An12cQjpdlsMt9Fwm+WpG945X6aW
# ps4Iop9bgQlMb03/pcLw1hrcr6JIY0lu746E9G/HJAYL1co3jbQ8vCJubiQWV5sH
# 7PPHZkRbNH3ZPE1i88C31+xRqOu+mDCQyxQHY6fceVIKiX4JsBkVFnteH4w1JvPJ
# nnC9NydRdEQ+H9tXoW3AAanQxtoTxkXY
# SIG # End signature block

# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubTeamTypeName = 'GitHub.Team'
    GitHubTeamSummaryTypeName = 'GitHub.TeamSummary'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubTeam
{
<#
    .SYNOPSIS
        Retrieve a team or teams within an organization or repository on GitHub.

    .DESCRIPTION
        Retrieve a team or teams within an organization or repository on GitHub.

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
        The name of the organization.

    .PARAMETER TeamName
        The name of the specific team to retrieve.
        Note: This will be slower than querying by TeamSlug since it requires retrieving
        all teams first.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the specific team to retrieve.

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
        GitHub.Team
        GitHub.TeamSummary

    .EXAMPLE
        Get-GitHubTeam -OrganizationName PowerShell
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType(
        {$script:GitHubTeamTypeName},
        {$script:GitHubTeamSummaryTypeName})]
    param
    (
        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='TeamName')]
        [string] $OwnerName,

        [Parameter(ParameterSetName='Elements')]
        [Parameter(ParameterSetName='TeamName')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamName')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Organization')]
        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamName')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $teamType = [String]::Empty

    if ($PSBoundParameters.ContainsKey('TeamName') -and
        (-not $PSBoundParameters.ContainsKey('OrganizationName')))
    {
        $elements = Resolve-RepositoryElements
        $OwnerName = $elements.ownerName
        $RepositoryName = $elements.repositoryName
    }

    if ((-not [String]::IsNullOrEmpty($OwnerName)) -and
        (-not [String]::IsNullOrEmpty($RepositoryName)))
    {
        $telemetryProperties['OwnerName'] = Get-PiiSafeString -PlainText $OwnerName
        $telemetryProperties['RepositoryName'] = Get-PiiSafeString -PlainText $RepositoryName

        $uriFragment = "/repos/$OwnerName/$RepositoryName/teams"
        $description = "Getting teams for $RepositoryName"
        $teamType = $script:GitHubTeamSummaryTypeName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'TeamSlug')
    {
        $telemetryProperties['TeamSlug'] = Get-PiiSafeString -PlainText $TeamSlug

        $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"
        $description = "Getting team $TeamSlug"
        $teamType = $script:GitHubTeamTypeName
    }
    else
    {
        $telemetryProperties['OrganizationName'] = Get-PiiSafeString -PlainText $OrganizationName

        $uriFragment = "/orgs/$OrganizationName/teams"
        $description = "Getting teams in $OrganizationName"
        $teamType = $script:GitHubTeamSummaryTypeName
    }

    $params = @{
        'UriFragment' = $uriFragment
        'AcceptHeader' = $script:hellcatAcceptHeader
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubTeamAdditionalProperties -TypeName $teamType

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $team = $result | Where-Object -Property name -eq $TeamName

        if ($null -eq $team)
        {
            $message = "Team '$TeamName' not found"
            Write-Log -Message $message -Level Error
            throw $message
        }
        else
        {
            $uriFragment = "/orgs/$($team.OrganizationName)/teams/$($team.slug)"
            $description = "Getting team $($team.slug)"

            $params = @{
                UriFragment = $uriFragment
                Description =  $description
                Method = 'Get'
                AccessToken = $AccessToken
                TelemetryEventName = $MyInvocation.MyCommand.Name
                TelemetryProperties = $telemetryProperties
            }

            $result = Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties
        }
    }

    return $result
}

filter Get-GitHubTeamMember
{
<#
    .SYNOPSIS
        Retrieve list of team members within an organization.

    .DESCRIPTION
        Retrieve list of team members within an organization.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization.

    .PARAMETER TeamName
        The name of the team in the organization.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team in the organization.

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
        GitHub.Team

    .OUTPUTS
        GitHub.User

    .EXAMPLE
        $members = Get-GitHubTeamMember -Organization PowerShell -TeamName Everybody
#>
    [CmdletBinding(DefaultParameterSetName = 'Slug')]
    [OutputType({$script:GitHubUserTypeName})]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [String] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Name')]
        [ValidateNotNullOrEmpty()]
        [String] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Slug')]
        [string] $TeamSlug,

        [string] $AccessToken
    )

    Write-InvocationLog

    if ($PSCmdlet.ParameterSetName -eq 'Name')
    {
        $teams = Get-GitHubTeam -OrganizationName $OrganizationName -AccessToken $AccessToken
        $team = $teams | Where-Object {$_.name -eq $TeamName}
        if ($null -eq $team)
        {
            $message = "Unable to find the team [$TeamName] within the organization [$OrganizationName]."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $TeamSlug = $team.slug
    }

    $telemetryProperties = @{
        'OrganizationName' = (Get-PiiSafeString -PlainText $OrganizationName)
        'TeamName' = (Get-PiiSafeString -PlainText $TeamName)
        'TeamSlug' = (Get-PiiSafeString -PlainText $TeamSlug)
    }

    $params = @{
        'UriFragment' = "orgs/$OrganizationName/teams/$TeamSlug/members"
        'Description' = "Getting members of team $TeamSlug"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubUserAdditionalProperties)
}

function New-GitHubTeam
{
<#
    .SYNOPSIS
        Creates a team within an organization on GitHub.

    .DESCRIPTION
        Creates a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization to create the team in.

    .PARAMETER TeamName
        The name of the team.

    .PARAMETER Description
        The description for the team.

    .PARAMETER MaintainerName
        A list of GitHub user names for organization members who will become team maintainers.

    .PARAMETER RepositoryName
        The name of repositories to add the team to.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER ParentTeamId
        The ID of the team to set as the parent team.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Team
        GitHub.User
        System.String

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        New-GitHubTeam -OrganizationName PowerShell -TeamName 'Developers'

        Creates a new GitHub team called 'Developers' in the 'PowerShell' organization.

    .EXAMPLE
        $teamName = 'Team1'
        $teamName | New-GitHubTeam -OrganizationName PowerShell

        You can also pipe in a team name that was returned from a previous command.

    .EXAMPLE
        $users = Get-GitHubUsers -OrganizationName PowerShell
        $users | New-GitHubTeam -OrganizationName PowerShell -TeamName 'Team1'

        You can also pipe in a list of GitHub users that were returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        DefaultParameterSetName = 'ParentId'
    )]
    [OutputType({$script:GitHubTeamTypeName})]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [string] $Description,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('UserName')]
        [string[]] $MaintainerName,

        [string[]] $RepositoryName,

        [ValidateSet('Secret', 'Closed')]
        [string] $Privacy,

        [Parameter(ParameterSetName='ParentName')]
        [string] $ParentTeamName,

        [Parameter(
            ValueFromPipelineByPropertyName,
            ParameterSetName='ParentId')]
        [Alias('TeamId')]
        [int64] $ParentTeamId,

        [string] $AccessToken
    )

    begin
    {
        $maintainerNames = @()
    }

    process
    {
        foreach ($user in $MaintainerName)
        {
            $maintainerNames += $user
        }
    }

    end
    {
        Write-InvocationLog

        $telemetryProperties = @{
            OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
            TeamName = (Get-PiiSafeString -PlainText $TeamName)
        }

        $uriFragment = "/orgs/$OrganizationName/teams"

        $hashBody = @{
            name = $TeamName
        }

        if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
        if ($PSBoundParameters.ContainsKey('RepositoryName'))
        {
            $repositoryFullNames = @()
            foreach ($repository in $RepositoryName)
            {
                $repositoryFullNames += "$OrganizationName/$repository"
            }
            $hashBody['repo_names'] = $repositoryFullNames
        }
        if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
        if ($MaintainerName.Count -gt 0)
        {
            $hashBody['maintainers'] = $maintainerNames
        }
        if ($PSBoundParameters.ContainsKey('ParentTeamName'))
        {
            $getGitHubTeamParms = @{
                OrganizationName = $OrganizationName
                TeamName = $ParentTeamName
            }
            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $getGitHubTeamParms['AccessToken'] = $AccessToken
            }

            $team = Get-GitHubTeam @getGitHubTeamParms
            $ParentTeamId = $team.id
        }

        if ($ParentTeamId -gt 0)
        {
            $hashBody['parent_team_id'] = $ParentTeamId
        }

        if (-not $PSCmdlet.ShouldProcess($TeamName, 'Create GitHub Team'))
        {
            return
        }

        $params = @{
            UriFragment = $uriFragment
            Body = (ConvertTo-Json -InputObject $hashBody)
            Method = 'Post'
            Description =  "Creating $TeamName"
            AccessToken = $AccessToken
            TelemetryEventName = $MyInvocation.MyCommand.Name
            TelemetryProperties = $telemetryProperties
        }

        return (Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties)
    }
}

filter Set-GitHubTeam
{
<#
    .SYNOPSIS
        Updates a team within an organization on GitHub.

    .DESCRIPTION
        Updates a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the team's organization.

    .PARAMETER TeamName
        The name of the team.

        When TeamSlug is specified, specifying a name here that is different from the existing
        name will cause the team to be renamed. TeamSlug and TeamName are specified for you
        automatically when piping in a GitHub.Team object, so a rename would only occur if
        intentionally specify this parameter and provide a different name.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to update.

    .PARAMETER Description
        The description for the team.

    .PARAMETER Privacy
        The level of privacy this team should have.

    .PARAMETER ParentTeamName
        The name of a team to set as the parent team.

    .PARAMETER ParentTeamId
        The ID of the team to set as the parent team.

    .PARAMETER PassThru
        Returns the updated GitHub Team.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        Set-GitHubTeam -OrganizationName PowerShell -TeamName Developers -Description 'New Description'

        Updates the description for the 'Developers' GitHub team in the 'PowerShell' organization.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Set-GitHubTeam -Description 'New Description'

        You can also pipe in a GitHub team that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        DefaultParameterSetName = 'ParentName'
    )]
    [OutputType( { $script:GitHubTeamTypeName } )]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [string] $Description,

        [ValidateSet('Secret','Closed')]
        [string] $Privacy,

        [Parameter(ParameterSetName='ParentTeamName')]
        [string] $ParentTeamName,

        [Parameter(ParameterSetName='ParentTeamId')]
        [int64] $ParentTeamId,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $OrganizationName)
        TeamSlug = (Get-PiiSafeString -PlainText $TeamSlug)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    if ((-not $PSBoundParameters.ContainsKey('TeamSlug')) -or
        $PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubTeamParms['AccessToken'] = $AccessToken
        }

        $orgTeams = Get-GitHubTeam @getGitHubTeamParms

        if ($PSBoundParameters.ContainsKey('TeamName'))
        {
            $team = $orgTeams | Where-Object -Property name -eq $TeamName
            $TeamSlug = $team.slug
        }
    }

    $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"

    $hashBody = @{
        name = $TeamName
    }

    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Privacy')) { $hashBody['privacy'] = $Privacy.ToLower() }
    if ($PSBoundParameters.ContainsKey('ParentTeamName'))
    {
        $parentTeam = $orgTeams | Where-Object -Property name -eq $ParentTeamName
        $hashBody['parent_team_id'] = $parentTeam.id
    }
    elseif ($PSBoundParameters.ContainsKey('ParentTeamId'))
    {
        if ($ParentTeamId -gt 0)
        {
            $hashBody['parent_team_id'] = $ParentTeamId
        }
        else
        {
            $hashBody['parent_team_id'] = $null
        }
    }

    if (-not $PSCmdlet.ShouldProcess($TeamSlug, 'Set GitHub Team'))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Patch'
        Description =  "Updating $TeamName"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubTeamAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Rename-GitHubTeam
{
<#
    .SYNOPSIS
        Renames a team within an organization on GitHub.

    .DESCRIPTION
        Renames a team within an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the team's organization.

    .PARAMETER TeamName
        The existing name of the team.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to update.

    .PARAMETER NewTeamName
        The new name for the team.

    .PARAMETER PassThru
        Returns the updated GitHub Team.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        GitHub.Team

    .EXAMPLE
        Rename-GitHubTeam -OrganizationName PowerShell -TeamName Developers -NewTeamName DeveloperTeam

        Renames the 'Developers' GitHub team in the 'PowerShell' organization to be 'DeveloperTeam'.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Rename-GitHubTeam -NewTeamName 'DeveloperTeam'

        You can also pipe in a GitHub team that was returned from a previous command.

    .NOTES
        This is a helper/wrapper for Set-GitHubTeam which can also rename a GitHub Team.
#>
    [CmdletBinding(
        PositionalBinding = $false,
        DefaultParameterSetName = 'TeamSlug')]
    [OutputType( { $script:GitHubTeamTypeName } )]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $NewTeamName,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSBoundParameters.ContainsKey('TeamSlug'))
    {
        $team = Get-GitHubTeam -OrganizationName $OrganizationName -TeamName $TeamName -AccessToken:$AccessToken
        $TeamSlug = $team.slug
    }

    $params = @{
        OrganizationName = $OrganizationName
        TeamSlug = $TeamSlug
        TeamName = $NewTeamName
        PassThru = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        AccessToken = $AccessToken
    }

    return Set-GitHubTeam @params
}

filter Remove-GitHubTeam
{
<#
    .SYNOPSIS
        Removes a team from an organization on GitHub.

    .DESCRIPTION
        Removes a team from an organization on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER OrganizationName
        The name of the organization the team is in.

    .PARAMETER TeamName
        The name of the team to remove.

    .PARAMETER TeamSlug
        The slug (a unique key based on the team name) of the team to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Organization
        GitHub.Team

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubTeam -OrganizationName PowerShell -TeamName Developers

        Removes the 'Developers' GitHub team from the 'PowerShell' organization.

    .EXAMPLE
        Remove-GitHubTeam -OrganizationName PowerShell -TeamName Developers -Force

        Removes the 'Developers' GitHub team from the 'PowerShell' organization without prompting.

    .EXAMPLE
        $team = Get-GitHubTeam -OrganizationName PowerShell -TeamName Developers
        $team | Remove-GitHubTeam -Force

        You can also pipe in a GitHub team that was returned from a previous command.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'TeamSlug')]
    [Alias('Delete-GitHubTeam')]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $OrganizationName,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName,
            Position = 2,
            ParameterSetName='TeamName')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='TeamSlug')]
        [ValidateNotNullOrEmpty()]
        [string] $TeamSlug,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{
        OrganizationName = (Get-PiiSafeString -PlainText $RepositoryName)
        TeamSlug = (Get-PiiSafeString -PlainText $TeamSlug)
        TeamName = (Get-PiiSafeString -PlainText $TeamName)
    }

    if ($PSBoundParameters.ContainsKey('TeamName'))
    {
        $getGitHubTeamParms = @{
            OrganizationName = $OrganizationName
            TeamName = $TeamName
        }
        if ($PSBoundParameters.ContainsKey('AccessToken'))
        {
            $getGitHubTeamParms['AccessToken'] = $AccessToken
        }

        $team = Get-GitHubTeam @getGitHubTeamParms
        $TeamSlug = $team.slug
    }

    $uriFragment = "/orgs/$OrganizationName/teams/$TeamSlug"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($TeamName, 'Remove Github Team'))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Method = 'Delete'
        Description =  "Deleting $TeamSlug"
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    Invoke-GHRestMethod @params | Out-Null
}

filter Add-GitHubTeamAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Team objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Team
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
        [string] $TypeName = $script:GitHubTeamTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'TeamName' -Value $item.name -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'TeamId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'TeamSlug' -Value $item.slug -MemberType NoteProperty -Force

            $organizationName = [String]::Empty
            if ($item.organization)
            {
                $organizationName = $item.organization.login
            }
            else
            {
                $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

                if ($item.html_url -match "^https?://$hostName/orgs/([^/]+)/.*$")
                {
                    $organizationName = $Matches[1]
                }
            }

            Add-Member -InputObject $item -Name 'OrganizationName' -Value $organizationName -MemberType NoteProperty -Force

            # Apply these properties to any embedded parent teams as well.
            if ($null -ne $item.parent)
            {
                $null = Add-GitHubTeamAdditionalProperties -InputObject $item.parent
            }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInrwYJKoZIhvcNAQcCoIInoDCCJ5wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDusFBOFNJl7wBU
# nCPAOK2gCwbxAIl35s1QZjzz1O8oMKCCDYEwggX/MIID56ADAgECAhMzAAACUosz
# qviV8znbAAAAAAJSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDQ5M+Ps/X7BNuv5B/0I6uoDwj0NJOo1KrVQqO7ggRXccklyTrWL4xMShjIou2I
# sbYnF67wXzVAq5Om4oe+LfzSDOzjcb6ms00gBo0OQaqwQ1BijyJ7NvDf80I1fW9O
# L76Kt0Wpc2zrGhzcHdb7upPrvxvSNNUvxK3sgw7YTt31410vpEp8yfBEl/hd8ZzA
# v47DCgJ5j1zm295s1RVZHNp6MoiQFVOECm4AwK2l28i+YER1JO4IplTH44uvzX9o
# RnJHaMvWzZEpozPy4jNO2DDqbcNs4zh7AWMhE1PWFVA+CHI/En5nASvCvLmuR/t8
# q4bc8XR8QIZJQSp+2U6m2ldNAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUNZJaEUGL2Guwt7ZOAu4efEYXedEw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDY3NTk3MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAFkk3
# uSxkTEBh1NtAl7BivIEsAWdgX1qZ+EdZMYbQKasY6IhSLXRMxF1B3OKdR9K/kccp
# kvNcGl8D7YyYS4mhCUMBR+VLrg3f8PUj38A9V5aiY2/Jok7WZFOAmjPRNNGnyeg7
# l0lTiThFqE+2aOs6+heegqAdelGgNJKRHLWRuhGKuLIw5lkgx9Ky+QvZrn/Ddi8u
# TIgWKp+MGG8xY6PBvvjgt9jQShlnPrZ3UY8Bvwy6rynhXBaV0V0TTL0gEx7eh/K1
# o8Miaru6s/7FyqOLeUS4vTHh9TgBL5DtxCYurXbSBVtL1Fj44+Od/6cmC9mmvrti
# yG709Y3Rd3YdJj2f3GJq7Y7KdWq0QYhatKhBeg4fxjhg0yut2g6aM1mxjNPrE48z
# 6HWCNGu9gMK5ZudldRw4a45Z06Aoktof0CqOyTErvq0YjoE4Xpa0+87T/PVUXNqf
# 7Y+qSU7+9LtLQuMYR4w3cSPjuNusvLf9gBnch5RqM7kaDtYWDgLyB42EfsxeMqwK
# WwA+TVi0HrWRqfSx2olbE56hJcEkMjOSKz3sRuupFCX3UroyYf52L+2iVTrda8XW
# esPG62Mnn3T8AuLfzeJFuAbfOSERx7IFZO92UPoXE1uEjL5skl1yTZB3MubgOA4F
# 8KoRNhviFAEST+nG8c8uIsbZeb08SeYQMqjVEmkwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZhDCCGYACAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg+rL14iTq
# /yL8EHdQz2ekeGCM09XjLzfNs8ti3kwUYTwwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBAGVqwBqDHb8jiKBWEjtAsvYP7OukJy+SHAVoL22E
# efRpmE6aKrV4Oy7/iJYgC1Ay4QqhYyrrefj2JAEFMyBj+ap0ygzRIb/DCD4oLgnl
# k4Tr2+j2XkyXvgptjhN/v6KWRwKQ5st0Jfhjz/JxFUauNby9SBf25TRKvMNXpxXn
# BZD0NMzncWC7DTI8aTxPvAiJ6nzMqurzIEkl7cYHi6wy3KTn7EEunFX6vv/NzqDp
# bleROamZty/RLgkhubyVr1FMwx0LSp69ZFzCFzBPJw7048ulNR3RpDWVRRTPn71w
# FVB8VZoJhzwqH1hMPvzP+CVfNQHKAcT8/k4Gpy5We8Fp9c+hghcMMIIXCAYKKwYB
# BAGCNwMDATGCFvgwghb0BgkqhkiG9w0BBwKgghblMIIW4QIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgOI2ZldtWvXzCztx5m//O5bo1NPF1TZb6bKKt
# gEElnMYCBmLatrPgkxgTMjAyMjA3MjUxNzMwMTEuMDQ3WjAEgAIB9KCB1KSB0TCB
# zjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMg
# TWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjQ2MkYtRTMxOS0zRjIwMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRXzCCBxAwggT4oAMCAQICEzMAAAGkB8/jj6O6b9YA
# AQAAAaQwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjIwMzAyMTg1MTE4WhcNMjMwNTExMTg1MTE4WjCBzjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9w
# ZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjQ2
# MkYtRTMxOS0zRjIwMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAwEeOAPoU/LzU9SFw
# 4hUaHhs5Jqrrfhj5ONbaE0X0GWdbEskIS4yJXpgXnHphMztPVkszo2cfTCE/KmLP
# dtVlGbCAbJNREp9XI8nz1HdZpn8cy9wAlmcIyAv6Y6nET3iDBAkP+qjxSq46sIoJ
# j99yNyHFXzIyR8io/r0edZ9bStq2T4jYZkXYhIXJG28S7Em9pwgUMWRBePcf5fL0
# gfM2qqL6DniJCM4A3qzezryaLquq/r4P0M9U+DV6/rCisjcWVjOs8sIi6exu1i3d
# fDdocox8D5IfwJXiKon94RlQ/W4UlPnQwA81CUjBYRFrpxxxJUHmY3ZiAd/zMNSp
# BTiTb8NbD7XiIuTCuA2V91nfxXfGbEL2Zlz1ifAVzfbGLRzM/M3XkLzCJkQioJ13
# FvCKZz7Qu08pqd1FeTaEx/CDRellonEN8tOC9iNVTk9dOAHXSaFYAD9iiyBsHwrO
# 8DFc+esSdiDdctaSAFn6U6se+qKzOUUIZAL2so9UU8IKx7LfnpWF9xeW/AAlq4CT
# tXSctVODCL/kgvId98S5lgOevHpr6yeoNMcv9mpGwHkcerRcGj+LsFW4xedJJeUU
# Kjc6fwg6Xwk4pDgKsiWuL2pYlgzGxIgKxyi2A4Ohg47iWZeW0o4HSXQgCERfBJIo
# gPlABr3BOkhqB5raHOMjpJRjVb8CAwEAAaOCATYwggEyMB0GA1UdDgQWBBTi0BOf
# rPgIEvbFlB3SOM3pKeMkwjAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5j
# cmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
# Q0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4ICAQAJVhxQ0QyXJO48MEaGJnVTnjyywXonaD1A
# SVYRvZxnh0vT7kbzvbX+CJG1M++DFCEMXmskKMcaPycVKo4Tx+djP2+BvZhyVge+
# SgpZQk4PGOFZL5LTpktH+cNLzkd4MAPQUZ24ADzRDu8bOScpbaPGg0dNvvgpAQxa
# JQrUzY8M354hI9c+E+50ZUYtsgQCTUaiPlWPNtC4sqGbZOThrbauReR4T3yDI2iM
# eUGEdtvud7HfMYFMEaRW3C3a53uo3atym4mGwn+8v/Rdgu3I6Tt5JBl1/J7RNPX+
# qPXyJJcewhcOEc65MqoGKJq2ijhSfCTu4bIzSW/fxm2v5ilqNI/6nQ8QxEf1F1+s
# pGbhsdXkKY5MjMCZzj1hm3jSGGVXCUKUUDgz7OfdzIuYQbB82oPr3eEPlbe9ymeF
# /fGFltVZNWkkfUI8ZOZHjLlT2THDKwrxWV8IVHBhRrnrjQqyAi/W0mEX0td6ZYg8
# Se7D0mfMdneJLDl1tNJen0eZ04kjOw77+2NDBlYFIWqdrJoa/djzDUpiJAlLxwom
# HCeEaAE9vJqf4TkP1PJj10qVncWKSy3AziEpgYRSWDe2ppYSKVbBr1Jo1603GNJ+
# BqHvzarNuNNCHAOBzol/TsXZqTRgyc0kUewFvU0/Dvt2Gaj2SLy+ss4H753oabZn
# +MOkM5Ky3zCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
# hvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# MjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAy
# MDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRp
# bWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoIC
# AQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg4r25Phdg
# M/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aORmsHFPPF
# dvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41JmTamDu6
# GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5LFGc6XBp
# Dco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL64NF50Zu
# yjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9QZpGdc3E
# XzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj0XOmTTd0
# lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqEUUbi0b1q
# GFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0kZSU2LlQ
# +QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435UsSFF5PA
# PBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB3TCCAdkw
# EgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTEmr6CkTxG
# NSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwGA1UdIARV
# MFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNVHSUEDDAK
# BggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNVHQ8EBAMC
# AYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo0T2UkFvX
# zpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29mdC5jb20v
# cGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcmwwWgYI
# KwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDANBgkqhkiG
# 9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4sQaTlz0x
# M7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th542DYunKmC
# VgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRXud2f8449
# xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBewVIVCs/wM
# nosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0DLzskYDS
# PeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+CljdQDzHVG2d
# Y3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFrDZ+kKNxn
# GSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFhbHP+Crvs
# QWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7ntdAoGokL
# jzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+oDEzfbzL
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggLS
# MIICOwIBATCB/KGB1KSB0TCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjQ2MkYtRTMxOS0zRjIwMSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
# FQA0HCjik2t8QvoNWj63D3q8Ym8un6CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5okpqTAiGA8yMDIyMDcyNTE4
# MzkzN1oYDzIwMjIwNzI2MTgzOTM3WjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDm
# iSmpAgEAMAoCAQACAhXcAgH/MAcCAQACAhEaMAoCBQDminspAgEAMDYGCisGAQQB
# hFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAw
# DQYJKoZIhvcNAQEFBQADgYEARI+f5k/15JH6zH/bl9HsSmnN1aQHpkkiykT3XiOT
# DN3Rb8jUxKd8spH9wVLkEGBpRhP7OOIhlAdhQn23cRo1tYaCbVBtlU3GsMLmM5Uy
# PjnNWlhff3Aepdc9WxI1aYfiXs09mVyKVsVzofjJvrsva/0iIzD9r9sfPDSYtmJc
# ATQxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAIT
# MwAAAaQHz+OPo7pv1gABAAABpDANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDFxP8zFOfYJvZsPeQJ
# iI/LLyOjY/2MXj56Xroe+/WPwjCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0E
# IAX84KMhJnCkwEnwwndbAwIXeo5rlgcUboni4eNq6nn4MIGYMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGkB8/jj6O6b9YAAQAAAaQwIgQg
# yL1QAE/dTZ4ROIyGeoVtnWbNepCqufutIHFTXDC5IM0wDQYJKoZIhvcNAQELBQAE
# ggIAeFz/ZKcpcZZYYXfTdKKSd67Tr5MNNd6DkZT7SNKO2AKT9lcsTYecLQ1Ko+X7
# t/Ay3SoZISoBbkz9LmpVD9DD6uYSEUVNUkefFBHdzez+fJIdRkZlumrgszrd0nuC
# c6QLXW6NMOqy0gBjocpgPBmRWuisKKCxsFBxagtSCvXRQwvMZHe6euS4Syke9SWO
# 2WNiHihlyyJMpUT6fKs2EE1L3Tf1PR2zOCLafVttFb28U29f01ptGD0TRL/nZEW/
# KMJwYNYknuqJ+tJ+aQ7910yeOYTVn/ecyRVFg1czRe+xqdPWsIbbCCiK+FiGKu/x
# LORLVmN+cfMNr9Ioj7V1tMwXYYldEnf/V7oMT00aH/TzgVvzoiHKrROf7NAM98qo
# mpZuC+4KYj8YmbZclCW7vu0tlWAGeGTzglRpRnwBSztfaNF09uR9+AUDcgVE5LXY
# jxOixd97b2R5rRDMXcH8K/rcjIXgLoHAdAw+mVl2sxpX9qK4giIRGBITUk/+Zkzs
# QmHztO+qeCIl7gSYfLEN/7NDUf/+Svijuv4KqfdXtKvbGpqm9P9RMCqMzPusKc/E
# zuRqkX8tQ07yKHTyKmMK+ePh/ozL9mQxLRJ0BCzPikj75iCQxFkmNiza3RT9jU+o
# H+peLKsWib20Oev6f4PfSrv0x2QdoOEnFxVCdXGgHNn9brg=
# SIG # End signature block

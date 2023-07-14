# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubLabelTypeName = 'GitHub.Label'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubLabel
{
<#
    .SYNOPSIS
        Retrieve label(s) of a given GitHub repository.

    .DESCRIPTION
        Retrieve label(s) of a given GitHub repository.

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

    .PARAMETER Label
        Name of the specific label to be retrieved.  If not supplied, all labels will be retrieved.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Issue
        If provided, will return all of the labels for this particular issue.

    .PARAMETER MilestoneNumber
        If provided, will return all of the labels assigned to issues for this particular milestone.

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
        GitHub.Label

    .EXAMPLE
        Get-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Gets the information for every label from the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Get-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel

        Gets the information for the label named "TestLabel" from the microsoft\PowerShellForGitHub
        project.

    .NOTES
        There were a lot of complications with the ParameterSets with this function due to pipeline
        input.  For the time being, the ParameterSets have been simplified and the validation of
        parameter combinations is happening within the function itself.
#>
    [CmdletBinding(DefaultParameterSetName = 'NameUri')]
    [OutputType({$script:GitHubLabelTypeName})]
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
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('LabelName')]
        [string] $Label,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(ValueFromPipelineByPropertyName)]
        [int64] $MilestoneNumber,

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

    # There were a lot of complications trying to get pipelining working right when using all of
    # the necessary ParameterSets, so we'll do internal parameter validation instead until someone
    # can figure out the right way to do the parameter sets here _with_ pipeline support.
    if ($PSBoundParameters.ContainsKey('Label') -or
        $PSBoundParameters.ContainsKey('Issue') -or
        $PSBoundParameters.ContainsKey('MilestoneNumber'))
    {
        if (-not ($PSBoundParameters.ContainsKey('Label') -xor
            $PSBoundParameters.ContainsKey('Issue') -xor
            $PSBoundParameters.ContainsKey('MilestoneNumber')))
        {
            $message = 'Label, Issue and Milestone are mutually exclusive.  Only one can be specified in a single command.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
        $description = "Getting labels for Issue $Issue in $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('MilestoneNumber'))
    {
        $uriFragment = "/repos/$OwnerName/$RepositoryName/milestones/$MilestoneNumber/labels"
        $description = "Getting labels for issues in Milestone $MilestoneNumber in $RepositoryName"
    }
    else
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/labels/$Label"

        if ($PSBoundParameters.ContainsKey('Name'))
        {
            $description = "Getting label $Label for $RepositoryName"
        }
        else
        {
            $description = "Getting labels for $RepositoryName"
        }
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubLabelAdditionalProperties)
}

filter New-GitHubLabel
{
<#
    .SYNOPSIS
        Create a new label on a given GitHub repository.

    .DESCRIPTION
        Create a new label on a given GitHub repository.

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

    .PARAMETER Label
        Name of the label to be created.
        Emoji and codes are supported.
        For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Color
        Color (in HEX) for the new label.

    .PARAMETER Description
        A short description of the label.

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
        GitHub.Label

    .EXAMPLE
        New-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Color BBBBBB

        Creates a new, grey-colored label called "TestLabel" in the PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
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

        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [Alias('LabelName')]
        [string] $Label,

        [Parameter(Mandatory)]
        [ValidateScript({if ($_ -match '^#?[ABCDEF0-9]{6}$') { $true } else { throw "Color must be provided in hex." }})]
        [Alias('LabelColor')]
        [string] $Color = "EEEEEE",

        [string] $Description,

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

    # Be robust to users who choose to provide a color in hex by specifying the leading # sign
    # (by just stripping it out).
    if ($Color.StartsWith('#'))
    {
        $Color = $Color.Substring(1)
    }

    $hashBody = @{
        'name' = $Label
        'color' = $Color
        'description' = $Description
    }

    if (-not $PSCmdlet.ShouldProcess($Label, 'Create GitHub Label'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/labels"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating label $Label in $RepositoryName"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubLabelAdditionalProperties)
}

filter Remove-GitHubLabel
{
<#
    .SYNOPSIS
        Deletes a label from a given GitHub repository.

    .DESCRIPTION
        Deletes a label from a given GitHub repository.

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

    .PARAMETER Label
        Name of the label to be deleted.
        Emoji and codes are supported.  For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

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
        Remove-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel

        Removes the label called "TestLabel" from the PowerShellForGitHub project.

    .EXAMPLE
        $label = $repo | Get-GitHubLabel -Label 'Test Label' -Color '#AAAAAA'
        $label | Remove-GitHubLabel

        Removes the label we just created using the pipeline, but will prompt for confirmation
        because neither -Confirm:$false nor -Force was specified.

    .EXAMPLE
        Remove-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Confirm:$false

        Removes the label called "TestLabel" from the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Force

        Removes the label called "TestLabel" from the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubLabel')]
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

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('LabelName')]
        [string] $Label,

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

    if (-not $PSCmdlet.ShouldProcess($Label, 'Remove GitHub label'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/labels/$Label"
        'Method' = 'Delete'
        'Description' = "Deleting label $Label from $RepositoryName"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Set-GitHubLabel
{
<#
    .SYNOPSIS
        Updates an existing label on a given GitHub repository.

    .DESCRIPTION
        Updates an existing label on a given GitHub repository.

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

    .PARAMETER Label
        Current name of the label to be updated.
        Emoji and codes are supported.
        For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER NewName
        New name for the label being updated.
        Emoji and codes are supported.
        For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

    .PARAMETER Color
        Color (in HEX) for the new label.

    .PARAMETER Description
        A short description of the label.

    .PARAMETER PassThru
        Returns the updated Label.  By default, this cmdlet does not generate any output.
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
        GitHub.Label

    .EXAMPLE
        Set-GitHubLabel  -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -NewName NewTestLabel -Color BBBB00

        Updates the existing label called TestLabel in the PowerShellForGitHub project to be called
        'NewTestLabel' and be colored yellow.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Alias('Update-GitHubLabel')] # Non-standard usage of the Update verb, but done to avoid a breaking change post 0.14.0
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

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('LabelName')]
        [string] $Label,

        [Alias('NewLabelName')]
        [string] $NewName,

        [Alias('LabelColor')]
        [ValidateScript({if ($_ -match '^#?[ABCDEF0-9]{6}$') { $true } else { throw "Color must be provided in hex." }})]
        [string] $Color = "EEEEEE",

        [string] $Description,

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

    # Be robust to users who choose to provide a color in hex by specifying the leading # sign
    # (by just stripping it out).
    if ($Color.StartsWith('#'))
    {
        $Color = $Color.Substring(1)
    }

    $hashBody = @{}
    if ($PSBoundParameters.ContainsKey('NewName')) { $hashBody['name'] = $NewName }
    if ($PSBoundParameters.ContainsKey('Description')) { $hashBody['description'] = $Description }
    if ($PSBoundParameters.ContainsKey('Color')) { $hashBody['color'] = $Color }

    if (-not $PSCmdlet.ShouldProcess($Label, 'Update GitHub Label'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/labels/$Label"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Updating label $Label"
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubLabelAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Initialize-GitHubLabel
{
<#
    .SYNOPSIS
        Replaces the entire set of Labels on the given GitHub repository to match the provided list
        of Labels.

    .DESCRIPTION
        Replaces the entire set of Labels on the given GitHub repository to match the provided list
        of Labels.

        Will update the color/description for any Labels already in the repository that match the
        name of a Label in the provided list.  All other existing Labels will be removed, and then
        new Labels will be created to match the others in the Label list.

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

    .PARAMETER Label
        The array of Labels (name, color, description) that the repository should be aligning to.
        A default list of labels will be used if no Labels are provided.

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
        Initialize-GitHubLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label @(@{'name' = 'TestLabel'; 'color' = 'EEEEEE'}, @{'name' = 'critical'; 'color' = 'FF000000'; 'description' = 'Needs immediate attention'})

        Removes any labels not in this Label array, ensure the current assigned color and descriptions
        match what's in the array for the labels that do already exist, and then creates new labels
        for any remaining ones in the Label list.

    .NOTES
        This method does not rename any existing labels, as it doesn't have any context regarding
        which Label the new name is for.  Therefore, it is possible that by running this function
        on a repository with Issues that have already been assigned Labels, you may experience data
        loss as a minor correction to you (maybe fixing a typo) will result in the old Label being
        removed (and thus unassigned from existing Issues) and then the new one created.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
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

        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]] $Label,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (($null -eq $Label) -or ($Label.Count -eq 0))
    {
        $Label = $script:defaultGitHubLabels
    }

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $commonParams = @{
        'OwnerName' = $OwnerName
        'RepositoryName' = $RepositoryName
        'AccessToken' = $AccessToken
    }

    $labelNames = $Label.name
    $existingLabels = Get-GitHubLabel @commonParams
    $existingLabelNames = $existingLabels.name

    if (-not $PSCmdlet.ShouldProcess(($Label -join ', '), 'Set GitHub Label'))
    {
        return
    }

    foreach ($labelToConfigure in $Label)
    {
        if ($labelToConfigure.name -notin $existingLabelNames)
        {
            # Create label if it doesn't exist
            $newGitHubLabelParms = @{
                Label = $labelToConfigure.name
                Color = $labelToConfigure.color
                Confirm = $false
                WhatIf = $false
            }

            $null = New-GitHubLabel @newGitHubLabelParms @commonParams
        }
        else
        {
            # Update label's color if it already exists
            $setGitHubLabelParms = @{
                Label = $labelToConfigure.name
                NewName = $labelToConfigure.name
                Color = $labelToConfigure.color
                Confirm = $false
                WhatIf = $false
            }

            $null = Set-GitHubLabel @setGitHubLabelParms @commonParams
        }
    }

    foreach ($labelName in $existingLabelNames)
    {
        if ($labelName -notin $labelNames)
        {
            # Remove label if it exists but is not in desired label list
            $removeGitHubLabelParms = @{
                Label = $labelName
                Confirm = $false
                WhatIf = $false
            }

            $null = Remove-GitHubLabel @removeGitHubLabelParms @commonParams
        }
    }
}

function Add-GitHubIssueLabel
{
<#
    .SYNOPSIS
        Adds a label to an issue in the given GitHub repository.

    .DESCRIPTION
        Adds a label to an issue in the given GitHub repository.

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

    .PARAMETER Issue
        Issue number to add the label to.

    .PARAMETER Label
        Array of label names to add to the issue

    .PARAMETER PassThru
        Returns the added Label.  By default, this cmdlet does not generate any output.
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
        GitHub.Label

    .EXAMPLE
        Add-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Label $labels

        Adds labels to an issue in the PowerShellForGitHub project.

    .NOTES
        This is implemented as a function rather than a filter because the ValueFromPipeline
        parameter (Name) is itself an array which we want to ensure is processed only a single time.
        This API endpoint doesn't add labels to a repository, it replaces the existing labels with
        the new set provided, so we need to make sure that we have all the requested labels available
        to us at the time that the API endpoint is called.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
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
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [Alias('LabelName')]
        [ValidateNotNullOrEmpty()]
        [string[]] $Label,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $labelNames = @()
    }

    process
    {
        foreach ($name in $Label)
        {
            $labelNames += $name
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
            'LabelCount' = $Label.Count
        }

        $hashBody = @{
            'labels' = $labelNames
        }

        if (-not $PSCmdlet.ShouldProcess(($Label -join ', '), 'Add GitHub Issue Label'))
        {
            return
        }

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Post'
            'Description' = "Adding labels to issue $Issue in $RepositoryName"
            'AcceptHeader' = $script:symmetraAcceptHeader
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        $result = (Invoke-GHRestMethod @params | Add-GitHubLabelAdditionalProperties)
        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
}

function Set-GitHubIssueLabel
{
<#
    .SYNOPSIS
        Replaces labels on an issue in the given GitHub repository.

    .DESCRIPTION
        Replaces labels on an issue in the given GitHub repository.

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

    .PARAMETER Issue
        Issue number to replace the labels.

    .PARAMETER Label
        Array of label names that will be set on the issue.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the updated Label.  By default, this cmdlet does not generate any output.
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
        GitHub.Label

    .EXAMPLE
        Set-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Label $labels

        Replaces labels on an issue in the PowerShellForGitHub project.

    .EXAMPLE
        ('help wanted', 'good first issue') | Set-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1

        Replaces labels on an issue in the PowerShellForGitHub project
        with 'help wanted' and 'good first issue'.

    .EXAMPLE
        Set-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Confirm:$false

        Removes all labels from issue 1 in the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Confirm:$false was specified.

        This is the same result as having called
        Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Confirm:$false

    .EXAMPLE
        Set-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Force

        Removes all labels from issue 1 in the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Force was specified.

        This is the same result as having called
        Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Force

    .NOTES
        This is implemented as a function rather than a filter because the ValueFromPipeline
        parameter (Name) is itself an array which we want to ensure is processed only a single time.
        This API endpoint doesn't add labels to a repository, it replaces the existing labels with
        the new set provided, so we need to make sure that we have all the requested labels available
        to us at the time that the API endpoint is called.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Elements')]
    [OutputType({$script:GitHubLabelTypeName})]
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

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('LabelName')]
        [string[]] $Label,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $labelNames = @()
    }

    process
    {
        foreach ($name in $Label)
        {
            $labelNames += $name
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
            'LabelCount' = $Label.Count
        }

        $hashBody = @{
            'labels' = $labelNames
        }

        $shouldProcessMessage = "Set GitHub Issue Label(s) $($Label -join ', ')"

        if ([System.String]::IsNullOrEmpty($Label))
        {
            $ConfirmPreference = 'Low'
            $shouldProcessMessage = 'Remove all GitHub Issue Labels'
        }

        if ($Force -and (-not $Confirm))
        {
            $ConfirmPreference = 'None'
        }

        if (-not $PSCmdlet.ShouldProcess("Issue #$Issue", $shouldProcessMessage))
        {
            return
        }

        $params = @{
            'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/labels"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Put'
            'Description' = "Replacing labels to issue $Issue in $RepositoryName"
            'AcceptHeader' = $script:symmetraAcceptHeader
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        $result = (Invoke-GHRestMethod @params | Add-GitHubLabelAdditionalProperties)
        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
}

filter Remove-GitHubIssueLabel
{
<#
    .SYNOPSIS
        Deletes a label from an issue in the given GitHub repository.

    .DESCRIPTION
        Deletes a label from an issue in the given GitHub repository.

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

    .PARAMETER Issue
        Issue number to remove the label from.

    .PARAMETER Label
        Name of the label to be deleted. If not provided, will delete all labels on the issue.
        Emoji and codes are supported.
        For more information, see here: https://www.webpagefx.com/tools/emoji-cheat-sheet/

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
        Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Issue 1

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Issue 1 -Confirm:$false

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubIssueLabel -OwnerName microsoft -RepositoryName PowerShellForGitHub -Label TestLabel -Issue 1 -Force

        Removes the label called "TestLabel" from issue 1 in the PowerShellForGitHub project.
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubLabel')]
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
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('LabelName')]
        [string] $Label,

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

    $description = [String]::Empty
    if ($PSBoundParameters.ContainsKey('Label'))
    {
        $description = "Deleting label $Label from issue $Issue in $RepositoryName"
    }
    else
    {
        $description = "Deleting all labels from issue $Issue in $RepositoryName"
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Label, 'Remove GitHub Issue label'))
    {
        return
    }

    $params = @{
        'UriFragment' = "/repos/$OwnerName/$RepositoryName/issues/$Issue/labels/$Label"
        'Method' = 'Delete'
        'Description' = $description
        'AcceptHeader' = $script:symmetraAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubLabelAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Label objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER RepositoryUrl
        Optionally supplied if the Label object doesn't have this value already
        (as is the case for GitHub.LabelSummary).

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Label
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

        [string] $RepositoryUrl,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubLabelTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if (-not [System.String]::IsNullOrEmpty($item.url))
            {
                $elements = Split-GitHubUri -Uri $item.url
                $RepositoryUrl = Join-GitHubUri @elements
            }

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $RepositoryUrl -MemberType NoteProperty -Force

            if ($null -ne $item.id)
            {
                Add-Member -InputObject $item -Name 'LabelId' -Value $item.id -MemberType NoteProperty -Force
            }

            Add-Member -InputObject $item -Name 'LabelName' -Value $item.name -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}

# A set of labels that a project might want to initially populate their repository with
# Used by Set-GitHubLabel when no Label list is provided by the user.
# This list exists to support v0.1.0 users.
$script:defaultGitHubLabels = @(
    @{
        'name' = 'pri:lowest'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:low'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:medium'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:high'
        'color' = '4285F4'
    },
    @{
        'name' = 'pri:highest'
        'color' = '4285F4'
    },
    @{
        'name' = 'bug'
        'color' = 'fc2929'
    },
    @{
        'name' = 'duplicate'
        'color' = 'cccccc'
    },
    @{
        'name' = 'enhancement'
        'color' = '121459'
    },
    @{
        'name' = 'up for grabs'
        'color' = '159818'
    },
    @{
        'name' = 'question'
        'color' = 'cc317c'
    },
    @{
        'name' = 'discussion'
        'color' = 'fe9a3d'
    },
    @{
        'name' = 'wontfix'
        'color' = 'dcb39c'
    },
    @{
        'name' = 'in progress'
        'color' = 'f0d218'
    },
    @{
        'name' = 'ready'
        'color' = '145912'
    }
)

# SIG # Begin signature block
# MIInlQYJKoZIhvcNAQcCoIInhjCCJ4ICAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD56skNSK1EsVnM
# 9s96XMTzQnitOU1GzYN4HsMUBR5K4qCCDXYwggX0MIID3KADAgECAhMzAAACURR2
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGXUwghlxAgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAJRFHbMxYWDbgsAAAAAAlEwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGz2QqHXD5hbf8HkIMzFjVNa
# W9KLENdkAZuyvh6vggTSMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQCUrN+bydRz0MO8D5q/lh3bKDSZ51ZS9Eqs53V2/DYF2uUaohNnfMWd
# UMc/nuIBW36Lqw/I3rKoHpAzVrOamE8Xrq0S/bnQSnoAzxM7+0UP42v/b8GJ38H2
# 7H9i5w93H00I0JszhQH6HDrdWN8+OSjpMfuk336SxDqZLxz14XQErMR+3NhTigq8
# TsFkdxmQOrwf+1SWiUP+uwW2NmR5sqg9/4YjMo1fpLAuU4EeaIgQ4WgHTB9bKF+W
# NZcOaWzAUeec7DXZk0VpCnnXMj2OtTuHPrAeBU0k06UJiBTdk/Yl12A090jivNaq
# 2f/cy3IziYm5DQXgQCtCnulxge4FbGM0oYIW/TCCFvkGCisGAQQBgjcDAwExghbp
# MIIW5QYJKoZIhvcNAQcCoIIW1jCCFtICAQMxDzANBglghkgBZQMEAgEFADCCAVEG
# CyqGSIb3DQEJEAEEoIIBQASCATwwggE4AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEINaqIviOr7hx0KXpKIoA0Fj8yZ4btr94nyvuEktWvJc1AgZi1+tv
# jncYEzIwMjIwNzI1MTcyNTM1LjM3NVowBIACAfSggdCkgc0wgcoxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1pY3Jvc29mdCBB
# bWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjQ5QkMt
# RTM3QS0yMzNDMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNl
# oIIRVDCCBwwwggT0oAMCAQICEzMAAAGXA89ZnGuJeD8AAQAAAZcwDQYJKoZIhvcN
# AQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNV
# BAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQG
# A1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcNMjExMjAyMTkw
# NTE0WhcNMjMwMjI4MTkwNTE0WjCByjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9u
# czEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046NDlCQy1FMzdBLTIzM0MxJTAjBgNV
# BAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQDtAErqSkFN8/Ce/csrHVWcv1iSjNTArPKEMqKPUTpY
# JX8TBZl88LNrpw4bEpPimO+Etcli5RBoZEieo+SzYUnb0+nKEWaEYgubgp+HTFZi
# D85Lld7mk2Xg91KMDE2yMeOIH2DHpTsn5p0Lf0CDlfPE5HOwpP5/vsUxNeDWMW6z
# sSuKU69aL7Ocyk36VMyCKjHNML67VmZMJBO7bX1vYVShOvQqZUkxCpCR3szmxHT0
# 9s6nhwLeNCz7nMnU7PEiNGVxSYu+V0ETppFpK7THcGYAMa3SYZjQxGyDOc7J20kE
# ud6tz5ArSRzG47qscDfPYqv1+akex81w395E+1kc4uukfn0CeKtADum7PqRrbRMD
# 7wyFnX2FvyaytGj0uaKuMXFJsZ+wfdk0RsuPeWHtVz4MRCEwfYr1c+JTkmS3n/pv
# Hr/b853do28LoPHezk3dSxbniQojW3BTYJLmrUei/n4BHK5mTT8NuxG6zoP3t8HV
# mhCW//i2sFwxVHPsyQ6sdrxs/hapsPR5sti2ITG/Hge4SeH7Sne942OHeA/T7sOS
# JXAhhx9VyUiEUUax+dKIV7Gu67rjq5SVr5VNS4bduOpLsWEjeGHpMei//3xd8dxZ
# 42G/EDkr5+L7UFxIuBAq+r8diP/D8yR/du7vc4RGKw1ppxpo4JH9MnYfd+zUDuUg
# cQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFG3PAc8o6zBullUL0bG+3X69FQBgMB8G
# A1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCG
# Tmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUy
# MFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4w
# XAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2Vy
# dHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwG
# A1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQAD
# ggIBAARI2GHSJO0zHnshct+Hgu4dsPU0b0yUsDXBhAdAGdH1T+uDeq3c3Hp7v5C4
# QowSEqp0t/eDlFHhH+hkvm8QlVZR8hIf+hJZ3OqtKGpyZPg7HNzYIGzRS2fKilUO
# bhbYK6ajeq7KRg+kGgZ16Ku8N13XncDCwmQgyCb/yzEkpsgF5Pza2etSeA2Y2jy7
# uXW4TSGwwCrVuK9Drd9Aiev5Wpgm9hPRb/Q9bukDeqHihw2OJfpnx32SPHwvu4E8
# j8ezGJ8KP/yYVG+lUFg7Ko/tjl2LlkCeNMNIcxk1QU8e36eEVdRweNc9FEcIyqom
# DgPrdfpvRXRHztD3eKnAYhcEzM4xA0i0k5F6Qe0eUuLduDouemOzRoKjn9GUcKM2
# RIOD7FXuph5rfsv84pM2OqYfek0BrcG8/+sNCIYRi+ABtUcQhDPtYxZJixZ5Q8Vk
# jfqYKOBRjpXnfwKRC0PAzwEOIBzL6q47x6nKSI/QffbKrAOHznYF5abV60X4+TD+
# 3xc7dD52IW7saCKqN16aPhV+lGyba1M30ecB7CutvRfBjxATa2nSFF03ZvRSJLEy
# YHiE3IopdVoMs4UJ2Iuex+kPSuM4fyNsQJk5tpZYuf14S8Ov5A1A+9Livjsv0Brw
# uvUevjtXAnkTaAISe9jAhEPOkmExGLQqKNg3jfJPpdIZHg32MIIHcTCCBVmgAwIB
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
# Y1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAsswggI0AgEBMIH4oYHQpIHNMIHK
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUwIwYDVQQLExxN
# aWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1UaGFsZXMgVFNT
# IEVTTjo0OUJDLUUzN0EtMjMzQzElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3Rh
# bXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAYUDSsI2YSTTNTXYNg0YxTcHWY9Gg
# gYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYw
# JAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0B
# AQUFAAIFAOaJAVcwIhgPMjAyMjA3MjUxOTQ3MzVaGA8yMDIyMDcyNjE5NDczNVow
# dDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA5okBVwIBADAHAgEAAgIMVjAHAgEAAgIR
# 3TAKAgUA5opS1wIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgorBgEEAYRZCgMCoAow
# CAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUAA4GBAAOBsBBQCplq
# JmOHYr5pJBtSg07ZUbHK+TuFxQJIOotqhI7V722h0BWq+D2YcOhKUik27A7oOzZW
# Tq/bJH8wAwaIGpafTgXeFKau9ke2aTbq9vdBYqjvTZC2EFaeTtnk2qrn/X2SVHZY
# 8H8f+6DKoVkRM9AzQAiYsigep4Wgfk3EMYIEDTCCBAkCAQEwgZMwfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGXA89ZnGuJeD8AAQAAAZcwDQYJYIZI
# AWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAvBgkqhkiG
# 9w0BCQQxIgQgl3UyyBX9rmMGE8aJYibsqeAqpqcfAlsv43MdL2SdUuowgfoGCyqG
# SIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBbe9obEJV6OP4EDMVJ8zF8dD5vHGSoLDwu
# Qxj9BnimvzCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMz
# AAABlwPPWZxriXg/AAEAAAGXMCIEIARnXHWqeGv005Qx/Niu60lCCsQ0PKfiXcpS
# hp9OpKGpMA0GCSqGSIb3DQEBCwUABIICAMZtgAO6CvHOZgErR3wlWGVvmrk/3P5i
# 62dZuwsIxePiCIWAfUgjtSSP1fQerSByFYgHF21h7UUui9Oq1k+XHSALwGEpPAqE
# cy/03jcK6aw4crnijX8kYknlZO7i/sJ2T6SxTVc3dXBZqSPa7tsM0UUDmvaiNZCX
# ZnX70Slcge7rMjony3pIrSRMerl1/Y4nuTpgt8fnkRJzJPHGeWMVVp3TQ617cxWJ
# Vg3XtxSkwerdAPOnoeRJ4yKi+lJheXwhChIwqggdskKtzP9Y5Xdoiu7rsmpIn4S8
# +FRvdJ7Or6yz4cUciIj/35oIcnoNZwfsIEcMZ6qD+p0GXfjp7oi0i2oJcPAE5/UI
# sTIK6ezWHlL5pXhro/gBZ5pHOrs0fY80m7CbxkeXaMg6+lg7GyOY6/DqnOVHyARJ
# HhD/2PjHK2lkmqKwkEgEyxd+1qmiK4mj7pXGohdEqsThwHERwithakoUziwetSPB
# uyO7S+5IbEKwNJXtOf/Z41ONfV+ZFcZNW6ep29dQ/iNjCiSRhiuhTNrj9igSKPc6
# GhghRHXYzgUIt2RvxufwyBz5bvURSX46ab2W3ZR1SzLo/Py4ucYGDPo5j2uIf92p
# UKzCcmbJShBZijTNYH19rPzU8al+zqQD3+BJqNdtYSiVfIO8usAnpim6HElnJLku
# Lq/89/WE3wea
# SIG # End signature block

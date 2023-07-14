# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubCommentTypeName = 'GitHub.Comment'
    GitHubIssueCommentTypeName = 'GitHub.IssueComment'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubIssueComment
{
<#
    .SYNOPSIS
        Get the Issue comments for a given GitHub repository.

    .DESCRIPTION
        Get the Issue comments for a given GitHub repository.

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

    .PARAMETER Comment
        The ID of a specific comment to get. If not supplied, will return back all comments for this repository.

    .PARAMETER Issue
        Issue number to get comments for. If not supplied, will return back all comments for this repository.

    .PARAMETER Sort
        How to sort the results.

    .PARAMETER Direction
        How to list the results. Ignored without the sort parameter.

    .PARAMETER Since
        Only comments updated at or after this time are returned.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.

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
        GitHub.IssueComment

    .EXAMPLE
        Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Get all of the Issue comments for the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubIssueComment -Since ([DateTime]::Now).AddDays(-1)

        Get all of the Issue comments for the microsoft\PowerShellForGitHub project since yesterday.

    .EXAMPLE
        $issue = $repo | Get-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1

        Get the comments Issue #1 in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $issue = $repo | Get-GitHubIssue -Issue 1
        $issue | Get-GitHubIssueComment

        Get the comments Issue #1 in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $issue = $repo | Get-GitHubIssue -Issue 1
        $comments = $issue | Get-GitHubIssueComment
        $comment[0] | Get-GitHubIssueComment

        Get the most recent comment on Issue #1 in the microsoft\PowerShellForGitHub project by
        passing it in via the pipeline.  This shows some of the different types of objects you
        can pipe into this function.
#>
    [CmdletBinding(DefaultParameterSetName = 'RepositoryElements')]
    [Alias('Get-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='CommentElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='CommentElements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='RepositoryUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='CommentUri')]
        [Alias('CommentId')]
        [int64] $Comment,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [Parameter(ParameterSetName='IssueElements')]
        [Parameter(ParameterSetName='IssueUri')]
        [DateTime] $Since,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [ValidateSet('Created', 'Updated')]
        [string] $Sort,

        [Parameter(ParameterSetName='RepositoryElements')]
        [Parameter(ParameterSetName='RepositoryUri')]
        [ValidateSet('Ascending', 'Descending')]
        [string] $Direction,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName
    $uriFragment = [String]::Empty
    $description = [String]::Empty

    $sinceFormattedTime = [String]::Empty
    if ($null -ne $Since)
    {
        $sinceFormattedTime = $Since.ToUniversalTime().ToString('o')
    }

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedComment' = $PSBoundParameters.ContainsKey('Comment')
    }

    if ($PSBoundParameters.ContainsKey('Comment'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
        $description = "Getting comment $Comment for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments`?"

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $uriFragment += "since=$sinceFormattedTime"
        }

        $description = "Getting comments for issue $Issue in $RepositoryName"
    }
    else
    {
        $getParams = @()

        if ($PSBoundParameters.ContainsKey('Sort'))
        {
            $getParams += "sort=$($Sort.ToLower())"
        }

        if ($PSBoundParameters.ContainsKey('Direction'))
        {
            $directionConverter = @{
                'Ascending' = 'asc'
                'Descending' = 'desc'
            }

            $getParams += "direction=$($directionConverter[$Direction])"
        }

        if ($PSBoundParameters.ContainsKey('Since'))
        {
            $getParams += "since=$sinceFormattedTime"
        }

        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/comments`?" +  ($getParams -join '&')
        $description = "Getting comments for $RepositoryName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubIssueCommentAdditionalProperties)
}

filter New-GitHubIssueComment
{
<#
    .SYNOPSIS
        Creates a new GitHub comment for an issue for the given repository.

    .DESCRIPTION
        Creates a new GitHub comment for an issue for the given repository.

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
        The number for the issue that the comment will be filed under.

    .PARAMETER Body
        The contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        Raw - Return the raw markdown body. Response will include body. This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body. Response will include body_text.
        Html - Return HTML rendered from the body's markdown. Response will include body_html.
        Full - Return raw, text and HTML representations. Response will include body, body_text, and body_html.

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
        GitHub.User

    .OUTPUTS
        GitHub.IssueComment

    .EXAMPLE
        New-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Issue 1 -Body "Testing this API"

        Creates a new GitHub comment for an issue for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Alias('New-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
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

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'Issue' =  (Get-PiiSafeString -PlainText $Issue)
    }

    $hashBody = @{
        'body' = $Body
    }

    if (-not $PSCmdlet.ShouldProcess($Issue, 'Create GitHub Issue Comment'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/$Issue/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = "Creating comment under issue $Issue for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubIssueCommentAdditionalProperties)
}

filter Set-GitHubIssueComment
{
<#
    .SYNOPSIS
        Modifies an existing comment in an issue for the given repository.

    .DESCRIPTION
        Modifies an existing comment in an issue for the given repository.

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

    .PARAMETER Comment
        The ID of the comment to edit.

    .PARAMETER Body
        The new contents of the comment.

    .PARAMETER MediaType
        The format in which the API will return the body of the comment.

        Raw  - Return the raw markdown body.
               Response will include body.
               This is the default if you do not pass any specific media type.
        Text - Return a text only representation of the markdown body.
               Response will include body_text.
        Html - Return HTML rendered from the body's markdown.
               Response will include body_html.
        Full - Return raw, text and HTML representations.
               Response will include body, body_text, and body_html.

    .PARAMETER PassThru
        Returns the updated Comment.  By default, this cmdlet does not generate any output.
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
        GitHub.User

    .OUTPUTS
        GitHub.IssueComment

    .EXAMPLE
        Set-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Body "Testing this API"

        Updates an existing comment in an issue for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements')]
    [Alias('Set-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
    [OutputType({$script:GitHubIssueCommentTypeName})]
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
        [Alias('CommentId')]
        [int64] $Comment,

        [Parameter(Mandatory)]
        [string] $Body,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType ='Raw',

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
        'Comment' =  (Get-PiiSafeString -PlainText $Comment)
    }

    $hashBody = @{
        'body' = $Body
    }

    if (-not $PSCmdlet.ShouldProcess($Comment, 'Update GitHub Issue Comment'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Update comment $Comment for $RepositoryName"
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson -AcceptHeader $squirrelGirlAcceptHeader)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubIssueCommentAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubIssueComment
{
<#
    .SYNOPSIS
        Deletes a GitHub comment from an Issue in the given repository.

    .DESCRIPTION
        Deletes a GitHub comment from an Issue in the given repository.

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

    .PARAMETER Comment
        The ID of the comment to delete.

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
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1

        Deletes a GitHub comment from an Issue in the microsoft\PowerShellForGitHub project.

    .EXAMPLE
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Confirm:$false

        Deletes a Github comment from an Issue in the microsoft\PowerShellForGitHub project
        without prompting confirmation.

    .EXAMPLE
        Remove-GitHubIssueComment -OwnerName microsoft -RepositoryName PowerShellForGitHub -Comment 1 -Force

        Deletes a GitHub comment from an Issue in the microsoft\PowerShellForGitHub project
        without prompting confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Elements',
        ConfirmImpact="High")]
    [Alias('Delete-GitHubComment')]
    [Alias('Delete-GitHubIssueComment')]
    [Alias('Remove-GitHubComment')] # Aliased to avoid a breaking change after v0.14.0
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
        [Alias('CommentId')]
        [int64] $Comment,

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
        'Comment' =  (Get-PiiSafeString -PlainText $Comment)
    }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Comment, 'Remove GitHub Issue Comment'))
    {
        return
    }

    $params = @{
        'UriFragment' = "repos/$OwnerName/$RepositoryName/issues/comments/$Comment"
        'Method' = 'Delete'
        'Description' = "Removing comment $Comment for $RepositoryName"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubIssueCommentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Issue Comment objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.IssueComment
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
        [string] $TypeName = $script:GitHubIssueCommentTypeName
    )

    foreach ($item in $InputObject)
    {
        # Provide a generic comment type too
        $item.PSObject.TypeNames.Insert(0, $script:GitHubCommentTypeName)

        # But we want the specific type on top
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.html_url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            Add-Member -InputObject $item -Name 'CommentId' -Value $item.id -MemberType NoteProperty -Force

            if ($null -ne $item.user)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
            }
        }

        Write-Output $item
    }
}
# SIG # Begin signature block
# MIInrAYJKoZIhvcNAQcCoIInnTCCJ5kCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDfFkghi5O9DDNi
# 9wtqi0SsawcCL94QuSN/g8df1QYomaCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZgTCCGX0CAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgUfMbDMDj
# 5OPIYC0o9rAGPxO2ZDMeANgirYr5V5lCQ/kwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBAIV972yJLOeBInJ97gMfwUG/CgWGt5Yr+xKax7K+
# MrEAda0NZgEkwwu2F2o0Bzv/YmenLfhspAQvg4Wx7KJA2u3Gc/kz2GLsnkHMGMsO
# yZv+KhXkJBf8SFiWiW6YJFJBNwRib2CZ1Y7KjGu2CKLl0LDWRt0YviDAQP50p1tQ
# ZQkXhx9rgHxOl5N6+hFLv67epGWtOQpHpIvy3bVrOoXloEd0Lhm2p8KComVIiRMb
# bvcwLg8qkWLJfdUG9zt0xJwefWouNFeqPgdISpHkpw6ojv/yUm6iYQ/ojSRCfdhd
# sjCy/3TmCqeLoQDhi7inQnclaKv2x1p/TwT1qh6Gnqw8TsihghcJMIIXBQYKKwYB
# BAGCNwMDATGCFvUwghbxBgkqhkiG9w0BBwKgghbiMIIW3gIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgkuS26p+nyfnHfNuk2jc/MrBYcUFFj/Sn1n8d
# tfajIYECBmLa1UVtOxgTMjAyMjA3MjUxNzI1MjcuODM5WjAEgAIB9KCB1KSB0TCB
# zjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMg
# TWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOkY3QTYtRTI1MS0xNTBBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRXDCCBxAwggT4oAMCAQICEzMAAAGlAN4IxEAHcU4A
# AQAAAaUwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjIwMzAyMTg1MTE5WhcNMjMwNTExMTg1MTE5WjCBzjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9w
# ZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkY3
# QTYtRTI1MS0xNTBBMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAurGG6CBqSLzC6g4w
# x3uuwRCeYCG1XyJTVjSK2werfRN0JckOa9mNpnzK84dgVWFPIPVvkkYm3BmNbPV+
# CUKqzHmoHE/VbHUJmexDW2JGxFZBzXZWQROaRjzHjoyAewbICaE8+myBGeSUZqLs
# epAUHfXH9COTHutsCWvo9uUHi06ZpHWcrGXhUiCy0PB+d4pqgQTDiI3/FN3O1mPD
# IaJjmE2npt562RyLOAkU7f/JEdiHSC2T5tESGuYiBtquuuBvPsyycDu2Uq8Zw72I
# dzr7azKasBXLcLNDggw08VxNPHzBNn6Sm/qUWzV4bzGV+y7Y0NYqyGsyUofYmljN
# YBbV8I4PmKtewTgs6+LFlC9ud5ATr6IZ8hDBpuP59F2i4BTYCIT6Jo2wgNql0ppv
# xYvHPpU9FsQv4zowWRyyiK4oceiyEKnsmGZn2IzTKsTHZd5s6Fr9dDfjYqxEazaH
# TaClfrAHLJPx4PcwlUjFJGbgwsiKW9Zyl303euihrBstTqB2TuCgpZLr37DaO2i5
# cIRi3og99mryV2LQv8LBhu2/uZseYhn05zQkQlzpv2BxUN+g+J6YwpzPXkEt6nLH
# uelDYyIMoixw6oqFe5kj49l6s04eGL++zLb8WP2UHqQmsxhJ9XQXZ+u8FIFcwHvG
# O/ymCpflBdR7ydPFvhR8nRwMC8ECAwEAAaOCATYwggEyMB0GA1UdDgQWBBRfpo8D
# AJeurq1w7vvcWRdLaKka3zAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5j
# cmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
# Q0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4ICAQCWmwsX5TAwooRHanRYmejgboYYad+DeqMN
# 1odzm69di0boqYeuoB/9ioeSY2i1KvpkQSeUYIlhHtbe4n7lum+PTfAWoZ5+9Cwo
# hHb6rpOvOjO8/g2yh1ZNPlJWn8LpMQMa4sL2Y5AoDi3IvjQdNbu3FvRwB1+CfIcW
# gj8Gxmj8Vpd7NDyE7jFSOEOnI014npZi9fk0L4e/2eZPLOOrISD8vZxcA6bERa98
# 8BDWV/G+u1TAbvmMZ5Rp7CSHC3NqcKc/eXpiPAkUoHqfv9Ne2t+KTXFjWSB6/UnB
# DlpR0/HBJ0OYYThdM3azqk86Lwg7X305/oAS+HjV4PFHP7XVVRym4afu0lR5JNRI
# ey/NDwQI6PnDvsy/nn8XyFa7Tt6CcbxKtaPn5MXE08KnH8AU2/PP6h1NFNl3gta6
# iZwwdSYsWJQY4B160XpKh8cbkRwWfQNMPVqkFnMI/zGwZBxmDBWqjui/bf+4gmUw
# IsDJNhlX0hMI/T1yJQlsoFUJA2sYSdD9csU72bKzLINGu8eFTm4Y91fPgm3b9k3s
# lBhG5U1K4Kk3CgrQmvWzpyIO8cR4vKJzPGgh70YfdLJ9sfHq/+mEj6ITcNajVMIr
# vkQvqm3qTmLfr+Sfa5JVd1MfjhlWSHf+KFXe8TCzvy4aW+yIxysoGCmjcd1yMMeI
# ehaxR/gYjDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# 6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6FwZvKhggLP
# MIICOAIBATCB/KGB1KSB0TCBzjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJp
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkY3QTYtRTI1MS0xNTBBMSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
# FQCzyXDbRbObEMqI3UuGHuZlZe60qKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5olINTAiGA8yMDIyMDcyNTIw
# NDk1N1oYDzIwMjIwNzI2MjA0OTU3WjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDm
# iUg1AgEAMAcCAQACAgTbMAcCAQACAhGBMAoCBQDmipm1AgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQEFBQADgYEAZcNqjPvApnQ/C0S5NSPX9wKfLaysyHn5udX8iQsEF01s
# 9m/uyP7ITuMPwPEPlbxZ+w4Z7jGlYhSgDn8JaLhoToR64ecWUFj9limoUIA4T3tK
# t98TGRMJI+XYYtZoe6GLJ/ET6n0MkpIT30q6S4sak2kakK2jqzTgi+5u44QkeiMx
# ggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
# AaUA3gjEQAdxTgABAAABpTANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDEBGtr1fZXR/tTT6mFI+dn
# uPYYPEOKrwNp+pgUT+yTZTCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EILgK
# OHF+ZgSxoK3YBTzcqGH7okeXKTcHvS98wcyUEtxcMIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGlAN4IxEAHcU4AAQAAAaUwIgQgVCfr
# 6T9HHUiLgutA1rT86GtLMa43AU47NnRGle5XY/4wDQYJKoZIhvcNAQELBQAEggIA
# YZp5lr/YJ1S8USladR+nUTMoDdmnd7V3qDzXYxnNhoILfhyorO31c8IAVoUtvcK9
# m3+cVrtjrRZmTLX0KcPiG2ttY2IEad/+dlDFnbTQ9CbXbx2WQVkknbx40STjJYvr
# VAlSuI1eKt3IlByNzJJMifeOoJJoSbrFukGF5eC1iarKwZ4xfn5N9P09uanOdM/U
# DaFAK+wz9wi0kFAcf4kZ7y/l7rzoXsm7spKjrnp3LZGbO04nOqQ8uZFdlwDolovF
# m8Dj2wuCftV4p2bsDT+S+GNg06s1JnSeU+k2WLuPcLm1cYKiIroa5bKj1x1tOdMX
# CSeV/o+EUdHUoHQgNRZrjk+CQtPX64qn+bMTok6gVuGgNWCsJchon/j6XkNpnB2M
# Xfx9zq+FBIVv/Ig0RM54/iwYKAXuL6x2h8o2Mefl8Z0zwhDMAgY6kftnnOlpjWpz
# grSSysmTH5y/nJEAoi/CLqLBIXoni4DpEM8A5HIqbESTLwkHBy6voTh/EcLuo4Lh
# Nc5kmndjef63FdGYW0Zi6NmMjO7ISl187A+/PkutpkJYJXa9pFRSGM5rK+cmY5X5
# xnxY3bFzJ+NAwCcucHihjw9P78/95QPl68lbARdO/i6eUDVUxeuIZ2CCT/niE7Z+
# PR0jlxS4egB0tok/gEsH2zg7qFOu9vl2VAcpPBxTWtw=
# SIG # End signature block

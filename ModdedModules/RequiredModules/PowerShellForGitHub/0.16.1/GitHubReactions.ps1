# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubReactionTypeName = 'GitHub.Reaction'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubReaction
{
<#
    .SYNOPSIS
        Retrieve reactions of a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Retrieve reactions of a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionType
        The type of reaction you want to retrieve. This is also called the 'content' in
        the GitHub API. Valid options are based off:
        https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api. Otherwise, will attempt to use the configured value or will run
        unauthenticated.

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
        GitHub.Repository

    .OUTPUTS
        GitHub.Reaction

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157

        Gets the reactions for issue 157 from the Microsoft\PowerShellForGitHub
        project.

    .EXAMPLE
        Get-GitHubReaction -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 -ReactionType eyes

        Gets the 'eyes' reactions for issue 157 from the Microsoft\PowerShellForGitHub
        project.

    .EXAMPLE
        Get-GitHubIssue -OwnerName Microsoft -RepositoryName PowerShellForGitHub -Issue 157 | Get-GitHubReaction

        Gets a GitHub issue and pipe it into Get-GitHubReaction to get all
        the reactions for that issue.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Get-GitHubReaction

        Gets a GitHub pull request and pipes it into Get-GitHubReaction
        to get all the reactions for that pull request.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(DefaultParameterSetName='ElementsIssue')]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
        [string] $ReactionType,

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

    $splatForAddedProperties = @{
        OwnerName = $OwnerName
        Repository = $RepositoryName
    }

    if ($Issue)
    {
        $splatForAddedProperties.Issue = $Issue
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }
    else
    {
        # Pull Request
        $splatForAddedProperties.PullRequest = $PullRequest
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }

    if ($PSBoundParameters.ContainsKey('ReactionType'))
    {
        $uriFragment += "?content=" + [Uri]::EscapeDataString($ReactionType.ToLower())
    }

    $description = "Getting reactions for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params
    return ($result | Add-GitHubReactionAdditionalProperties @splatForAddedProperties)
}

filter Set-GitHubReaction
{
<#
    .SYNOPSIS
        Sets a reaction of a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Sets a reaction of a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionType
        The type of reaction you want to set. This is aslo called the 'content' in the GitHub API.
        Valid options are based off: https://developer.github.com/v3/reactions/#reaction-types

    .PARAMETER PassThru
        Returns the updated Reaction.  By default, this cmdlet does not generate any output.
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
        GitHub.Repository

    .OUTPUTS
        GitHub.Reaction

    .EXAMPLE
        Set-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket

        Sets the 'rocket' reaction for issue 12626 of the PowerShell\PowerShell project.

    .EXAMPLE
        Get-GitHubPullRequest -Uri https://github.com/microsoft/PowerShellForGitHub -PullRequest 193 | Set-GitHubReaction -ReactionType Heart

        Gets a GitHub pull request and pipes it into Set-GitHubReaction to set the
        'heart' reaction for that pull request.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsIssue')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [ValidateSet('+1', '-1', 'Laugh', 'Confused', 'Heart', 'Hooray', 'Rocket', 'Eyes')]
        [Parameter(Mandatory)]
        [string] $ReactionType,

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

    $splatForAddedProperties = @{
        OwnerName = $OwnerName
        Repository = $RepositoryName
    }

    if ($Issue)
    {
        $splatForAddedProperties.Issue = $Issue
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }
    else
    {
        # Pull request
        $splatForAddedProperties.PullRequest = $PullRequest
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions"
    }

    $description = "Setting reaction $ReactionType for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    if (-not $PSCmdlet.ShouldProcess(
        $ReactionId,
        "Setting reaction for $targetObjectTypeName $targetObjectNumber in $RepositoryName"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Post'
        'Body' = ConvertTo-Json -InputObject @{ content = $ReactionType.ToLower() }
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params |
        Add-GitHubReactionAdditionalProperties @splatForAddedProperties)

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubReaction
{
<#
    .SYNOPSIS
        Removes a reaction on a given GitHub Issue or Pull Request.

    .DESCRIPTION
        Removes a reaction on a given GitHub Issue or Pull Request.

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
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .PARAMETER ReactionId
        The Id of the reaction. You can get this from using Get-GitHubReaction.

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
        GitHub.Repository

    .OUTPUTS
        None

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 `
            -ReactionId 1234

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project
        interactively.

    .EXAMPLE
        Remove-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionId 1234 -Confirm:$false

        Remove a reaction by Id on Issue 12626 from the PowerShell\PowerShell project
        non-interactively.

    .EXAMPLE
        Get-GitHubReaction -OwnerName PowerShell -RepositoryName PowerShell -Issue 12626 -ReactionType rocket | Remove-GitHubReaction -Confirm:$false

        Gets a reaction using Get-GitHubReaction and pipes it into Remove-GitHubReaction.

    .NOTES
        Currently, issue comments, pull request comments and commit comments are not supported.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='ElementsIssue',
        ConfirmImpact='High')]
    [Alias('Delete-GitHubReaction')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="The Uri parameter is only referenced by Resolve-RepositoryElements which get access to it from the stack via Get-Variable -Scope 1.")]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='ElementsPullRequest')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriIssue')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsIssue')]
        [Parameter(
            Mandatory,
            ParameterSetName='UriIssue',
            ValueFromPipelineByPropertyName)]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='ElementsPullRequest')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='UriPullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ValueFromPipeline)]
        [int64] $ReactionId,

        [Parameter()]
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

    if ($Issue)
    {
        $targetObjectNumber = $Issue
        $targetObjectTypeName = 'Issue'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions/$ReactionId"
    }
    else
    {
        # Pull request
        $targetObjectNumber = $PullRequest
        $targetObjectTypeName = 'Pull Request'
        $uriFragment = "/repos/$OwnerName/$RepositoryName/issues/$targetObjectNumber/reactions/$ReactionId"
    }

    $description = "Removing reaction $ReactionId for $targetObjectTypeName $targetObjectNumber in $RepositoryName"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess(
        $ReactionId,
        "Removing reaction for $targetObjectTypeName $targetObjectNumber in $RepositoryName"))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'Method' = 'Delete'
        'AcceptHeader' = $script:squirrelGirlAcceptHeader
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Add-GitHubReactionAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Reaction objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER OwnerName
        Owner of the repository.

    .PARAMETER RepositoryName
        Name of the repository.

    .PARAMETER Issue
        The issue number.

    .PARAMETER PullRequest
        The pull request number.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Reaction
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
        [string] $TypeName = $script:GitHubReactionTypeName,

        [Parameter(Mandatory)]
        [string] $OwnerName,

        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ParameterSetName='Issue')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [Parameter(
            Mandatory,
            ParameterSetName='PullRequest')]
        [Alias('PullRequestNumber')]
        [int64] $PullRequest
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $repositoryUrl = Join-GitHubUri -OwnerName $OwnerName -RepositoryName $RepositoryName
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'ReactionId' -Value $item.id -MemberType NoteProperty -Force

            if ($PullRequest)
            {
                Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $PullRequest -MemberType NoteProperty -Force
            }
            else
            {
                # Issue
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $Issue -MemberType NoteProperty -Force
            }

            @('assignee', 'assignees', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInoQYJKoZIhvcNAQcCoIInkjCCJ44CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD6y2cNtvIr+9hQ
# uUHr0oX94MUjKZ7x4oWTG0rjIygF36CCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZdjCCGXICAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgEGXEonto
# URfiHdUNKUqqPf0LAVE1GJlw+QeywS9UPjIwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBACxUNO2msBv4tC2JBEmLsWlw7G2U45A7wQ7ioafm
# opzCzDlFf9aCyt/4XeG6jEoKDhpO/KeW7R1IN4c5Y08zBru4QBz+Ju4fn0EgyctC
# dDgY5v39/gvRQNKlRfEC8XksqVQP7egvup947N+2dYBAd19tJL4OLdwjq7gs+Sww
# WI1SeFrtrGCJaJyixL3j+x0zxFvFcSlOKFk4TFajj3EDypfoYcOo0x6g6sg4pE9I
# FJOv+gYLHtRJD12E8JB5JE7RBozYpaVRCzy4ePjNCeZHkEpPIGARyOtRiDs2lrfy
# 1Ab21THUWHECxDIGj9LhSsxFpextrkY2YkXXyo2vrL6Hm+ehghb+MIIW+gYKKwYB
# BAGCNwMDATGCFuowghbmBgkqhkiG9w0BBwKgghbXMIIW0wIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBTwYLKoZIhvcNAQkQAQSgggE+BIIBOjCCATYCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgnuk4G7xpaa6MjwieS1T4/fLUiBzOswY+MCH/
# 4y8R8w8CBmLVeqktzxgRMjAyMjA3MjUxNzI1NTYuN1owBIACAfSggdCkgc0wgcox
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJTAjBgNVBAsTHE1p
# Y3Jvc29mdCBBbWVyaWNhIE9wZXJhdGlvbnMxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOjEyQkMtRTNBRS03NEVCMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNloIIRVzCCBwwwggT0oAMCAQICEzMAAAGhAYVVmblUXYoAAQAAAaEw
# DQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwHhcN
# MjExMjAyMTkwNTI0WhcNMjMwMjI4MTkwNTI0WjCByjELMAkGA1UEBhMCVVMxEzAR
# BgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2Eg
# T3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MTJCQy1FM0FFLTc0
# RUIxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2UwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDayTxe5WukkrYxxVuHLYW9BEWCD9kk
# jnnHsOKwGddIPbZlLY+l5ovLDNf+BEMQKAZQI3DX91l1yCDuP9X7tOPC48ZRGXA/
# bf9ql0FK5438gIl7cV528XeEOFwc/A+UbIUfW296Omg8Z62xaQv3jrG4U/priArF
# /er1UA1HNuIGUyqjlygiSPwK2NnFApi1JD+Uef5c47kh7pW1Kj7RnchpFeY9MekP
# QRia7cEaUYU4sqCiJVdDJpefLvPT9EdthlQx75ldx+AwZf2a9T7uQRSBh8tpxPdI
# DDkKiWMwjKTrAY09A3I/jidqPuc8PvX+sqxqyZEN2h4GA0Edjmk64nkIukAK18K5
# nALDLO9SMTxpAwQIHRDtZeTClvAPCEoy1vtPD7f+eqHqStuu+XCkfRjXEpX9+h9f
# rsB0/BgD5CBf3ELLAa8TefMfHZWEJRTPNrbXMKizSrUSkVv/3HP/ZsJpwaz5My2R
# byc3Ah9bT76eBJkyfT5FN9v/KQ0HnxhRMs6HHhTmNx+LztYci+vHf0D3QH1eCjZW
# ZRjp1mOyxpPU2mDMG6gelvJse1JzRADo7YIok/J3Ccbm8MbBbm85iogFltFHecHF
# EFwrsDGBFnNYHMhcbarQNA+gY2e2l9fAkX3MjI7Uklkoz74/P6KIqe5jcd9FPCbb
# SbYH9OLsteeYOQIDAQABo4IBNjCCATIwHQYDVR0OBBYEFBa/IDLbY475VQyKiZSw
# 47l0/cypMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMF8GA1UdHwRY
# MFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01p
# Y3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAyMDEwKDEpLmNybDBsBggrBgEF
# BQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAo
# MSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZI
# hvcNAQELBQADggIBACDDIxElfXlG5YKcKrLPSS+f3JWZprwKEiASvivaHTBRlXtA
# s+TkadcsEei+9w5vmF5tCUzTH4c0nCI7bZxnsL+S6XsiOs3Z1V4WX+IwoXUJ4zLv
# s0+mT4vjGDtYfKQ/bsmJKar2c99m/fHv1Wm2CTcyaePvi86Jh3UyLjdRILWbtzs4
# oImFMwwKbzHdPopxrBhgi+C1YZshosWLlgzyuxjUl+qNg1m52MJmf11loI7D9HJo
# aQzd+rf928Y8rvULmg2h/G50o+D0UJ1Fa/cJJaHfB3sfKw9X6GrtXYGjmM3+g+Ah
# aVsfupKXNtOFu5tnLKvAH5OIjEDYV1YKmlXuBuhbYassygPFMmNgG2Ank3drEcDc
# ZhCXXqpRszNo1F6Gu5JCpQZXbOJM9Ue5PlJKtmImAYIGsw+pnHy/r5ggSYOp4g5Z
# 1oU9GhVCM3V0T9adee6OUXBk1rE4dZc/UsPlj0qoiljL+lN1A5gkmmz7k5tIObVG
# B7dJdz8J0FwXRE5qYu1AdvauVbZwGQkL1x8aK/svjEQW0NUyJ29znDHiXl5vLoRT
# jjFpshUBi2+IY+mNqbLmj24j5eT+bjDlE3HmNtLPpLcMDYqZ1H+6U6YmaiNmac2j
# RXDAaeEE/uoDMt2dArfJP7M+MDv3zzNNTINeuNEtDVgm9zwfgIUCXnDZuVtiMIIH
# cTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAAFTANBgkqhkiG9w0BAQsFADCB
# iDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMp
# TWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IDIwMTAwHhcNMjEw
# OTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAOThpkzntHIh
# C3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9sSuDivbk+F2Az/1xPx2b3lVNx
# WuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3po5GawcU88V29YZQ3MFEyHFc
# UTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2vjUmZNqYO7oaezOtgFt+jBAc
# nVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GPsjksUZzpcGkNyjYtcI4xyDUo
# veO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3rMvrg0XnRm7KMtXAhjBcTyzi
# YrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDPc31BmkZ1zcRfNN0Sidb9pSB9
# fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8FA6PRc6ZNN3SUHDSCD/AQ8rdH
# GO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q6oRRRuLRvWoYWmEBc8pnol7X
# KHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1fMHSRlJTYuVD5C4lh8zYGNRiE
# R9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLvjflSxIUXk8A8FdsaN8cIFRg/
# eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGjggHdMIIB2TASBgkrBgEEAYI3
# FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+ZMSavoKRPEY1Kc8Q/y8E7jAd
# BgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXAYDVR0gBFUwUzBRBgwrBgEE
# AYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMB
# Af8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1Ud
# HwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3By
# b2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEFBQcBAQRO
# MEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2Vy
# dHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MA0GCSqGSIb3DQEBCwUAA4IC
# AQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5HZHixBpOXPTEztTnXwnE2P9pk
# bHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2HnjYNi6cqYJWAAOwBb6J6Gng
# ugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1JFe53Z/zjj3G82jfZfakVqr3
# lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8F7BUhUKz/AyeixmJ5/ALaoHC
# gRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99Jo3QMvOyRgNI95ko+ZjtPu4b6
# MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4KWN1APMdUbZ1jdEgssU5HLcEU
# BHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZkWsNn6Qo3GcZKCS6OEuabvsh
# VGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58oWFsc/4Ku+xBZj1p/cvBQUl+
# fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w/ue10CgaiQuPNtq6TPmb/wrp
# NPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+7X6gMTN9vMvpe784cETRkPHI
# qzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1izoXBm8qGCAs4wggI3AgEBMIH4
# oYHQpIHNMIHKMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4G
# A1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSUw
# IwYDVQQLExxNaWNyb3NvZnQgQW1lcmljYSBPcGVyYXRpb25zMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjoxMkJDLUUzQUUtNzRFQjElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUAG3F2jO4LEMVLwgKG
# XdYMN4FBgOCggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDAN
# BgkqhkiG9w0BAQUFAAIFAOaJM0IwIhgPMjAyMjA3MjUyMzIwMzRaGA8yMDIyMDcy
# NjIzMjAzNFowdzA9BgorBgEEAYRZCgQBMS8wLTAKAgUA5okzQgIBADAKAgEAAgIc
# PwIB/zAHAgEAAgISLzAKAgUA5oqEwgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAAf4NbGng9kKgyCx83heId1PVTgOEB4CP90t81WXBeuUdmdENsbFBwlKj3c+
# cMBx7/qxZ0Qqh09nVH81zVYChI9SRXQq8988skuka1VXt8cqJNfEd8JqZbNdxZWl
# o1oB3QxOPuuzC7kTS9eY2G5T5aUdn/0jZ8v20KZwFn7fGG71MYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGhAYVVmblUXYoA
# AQAAAaEwDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQgyFvX0go7GuK3RSqSyIxcCvQMIYWmAL2aeGFP
# U1NJDCgwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCDrCFTxOoGCaCCCjoRy
# Be1JSQrMJeCCTyErziiJ347QhDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABoQGFVZm5VF2KAAEAAAGhMCIEILV6vPaPgHQ6jlKz1l77
# JnxZ4U4YfpTZvg1YJx8Aa4/YMA0GCSqGSIb3DQEBCwUABIICADgPT1RbRORQU/pQ
# hReB/4TE6XzOg9KL/OTfJVU72Ke7UdvOuhGl3KFaTVdfVqeFir0VI0kcwt0rgqo5
# zeEalb7WB87kcsr4xlxKFTNPcmSlY6qNI8VuR4/wM7VYtnZfMIVFCu/gW0X3dTl0
# sQca/UJCtaevtlEgahwnpWRkH79GZB6n0js4HvfraxqAkk3Xg3GKj71m+ugolDtn
# rgvMOToXfixq+LXMucptx+eK1CfBpzTIHPf3r2JRnZi1/OVFiBvM9n15vPYfVpxa
# mIHlTAuwJQPJm6az7iEF6bMJNgVCYTzyOUN7BK74UCFM+3eRbZ9Dnpn8VQTIVaID
# 7VSb8eHOK9/J9P49MX1s/IS8i6OoJJ71nFCmfykcWWl73hmPWHIk3Yf9Q7EQXQ0n
# ieNZ8i0FG4cM+iJ1d04vdt07Hb1fQgVnF5nZyWFz0nmQHRvF+Rj5ojcWnBOnTArJ
# FDzXJYdoVSw6mCY8bcm+iFYtmUltfzQaA+3S0/NCuLRzpHqeDWdn/FzbGdDslZrr
# TwPiL7XcoueEkBk/s4axtAq/qDZ4LOvHhWoCE9oEPp2JkpXuk85XRRpplEatcf46
# rxGGBFKy53ecDA16Ko3O2/+K1jeCqCzMCzAs+gB47xOvfQVvWgOAviznKETY3Wgi
# 4RJoBVPni5ks/oaCWYDCkho1WdQV
# SIG # End signature block

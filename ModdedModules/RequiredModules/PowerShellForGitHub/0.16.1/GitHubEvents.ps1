# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubEventTypeName = 'GitHub.Event'
    GitHubLabelSummaryTypeName = 'GitHub.LabelSummary'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubEvent
{
<#
    .SYNOPSIS
        Lists events for an issue, repository, or a single event.

    .DESCRIPTION
        Lists events for an issue, repository, or a single event.

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

    .PARAMETER EventId
        The ID of a specific event to get.
        If not supplied, will return back all events for this repository.

    .PARAMETER Issue
        Issue number to get events for.
        If not supplied, will return back all events for this repository.

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
        GitHub.Event

    .EXAMPLE
        Get-GitHubEvent -OwnerName microsoft -RepositoryName PowerShellForGitHub

        Get the events for the microsoft\PowerShellForGitHub project.
#>
    [CmdletBinding(DefaultParameterSetName = 'RepositoryElements')]
    [OutputType({$script:GitHubEventTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='EventElements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName='RepositoryElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='IssueElements')]
        [Parameter(
            Mandatory,
            ParameterSetName='EventElements')]
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
            ParameterSetName='EventUri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='EventUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='EventElements')]
        [int64] $EventId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueUri')]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='IssueElements')]
        [Alias('IssueNumber')]
        [int64] $Issue,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
        'ProvidedIssue' = $PSBoundParameters.ContainsKey('Issue')
        'ProvidedEvent' = $PSBoundParameters.ContainsKey('EventId')
    }

    $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events"
    $description = "Getting events for $RepositoryName"

    if ($PSBoundParameters.ContainsKey('EventId'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/events/$EventId"
        $description = "Getting event $EventId for $RepositoryName"
    }
    elseif ($PSBoundParameters.ContainsKey('Issue'))
    {
        $uriFragment = "repos/$OwnerName/$RepositoryName/issues/$Issue/events"
        $description = "Getting events for issue $Issue in $RepositoryName"
    }

    $acceptHeaders = @(
        $script:starfoxAcceptHeader,
        $script:sailorVAcceptHeader,
        $script:symmetraAcceptHeader,
        $script:machineManAcceptHeader)

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = $acceptHeaders -join ','
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubEventAdditionalProperties)
}

filter Add-GitHubEventAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Event objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Event
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
        [string] $TypeName = $script:GitHubEventTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $elements = Split-GitHubUri -Uri $item.url
            $repositoryUrl = Join-GitHubUri @elements
            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'EventId' -Value $item.id -MemberType NoteProperty -Force

            @('actor', 'assignee', 'assigner', 'assignees', 'committer', 'requested_reviewer', 'review_requester', 'user') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.issue)
            {
                $null = Add-GitHubIssueAdditionalProperties -InputObject $item.issue
                Add-Member -InputObject $item -Name 'IssueId' -Value $item.issue.id -MemberType NoteProperty -Force
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $item.issue.number -MemberType NoteProperty -Force
            }

            if ($null -ne $item.label)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.label -TypeName $script:GitHubLabelSummaryTypeName -RepositoryUrl $repositoryUrl
            }

            if ($null -ne $item.labels)
            {
                $null = Add-GitHubLabelAdditionalProperties -InputObject $item.labels -TypeName $script:GitHubLabelSummaryTypeName -RepositoryUrl $repositoryUrl
            }

            if ($null -ne $item.milestone)
            {
                $null = Add-GitHubMilestoneAdditionalProperties -InputObject $item.milestone
            }

            if ($null -ne $item.project_id)
            {
                Add-Member -InputObject $item -Name 'ProjectId' -Value $item.project_id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.project_card)
            {
                $null = Add-GitHubProjectCardAdditionalProperties -InputObject $item.project_card
                Add-Member -InputObject $item -Name 'CardId' -Value $item.project_card.id -MemberType NoteProperty -Force
            }

            if ($null -ne $item.column_name)
            {
                Add-Member -InputObject $item -Name 'ColumnName' -Value $item.column_name -MemberType NoteProperty -Force
            }

            if ($null -ne $item.source)
            {
                $null = Add-GitHubIssueAdditionalProperties -InputObject $item.source
                if ($item.source.PSObject.TypeNames[0] -eq 'GitHub.PullRequest')
                {
                    Add-Member -InputObject $item -Name 'PullRequestId' -Value $item.source.id -MemberType NoteProperty -Force
                    Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $item.source.number -MemberType NoteProperty -Force
                }
                else
                {
                    Add-Member -InputObject $item -Name 'IssueId' -Value $item.source.id -MemberType NoteProperty -Force
                    Add-Member -InputObject $item -Name 'IssueNumber' -Value $item.source.number -MemberType NoteProperty -Force
                }
            }

            if ($item.issue_url -match '^.*/issues/(\d+)$')
            {
                $issueNumber = $Matches[1]
                Add-Member -InputObject $item -Name 'IssueNumber' -Value $issueNumber -MemberType NoteProperty -Force
            }

            if ($item.pull_request_url -match '^.*/pull/(\d+)$')
            {
                $pullRequestNumber = $Matches[1]
                Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $pullRequestNumber -MemberType NoteProperty -Force
            }

            if ($null -ne $item.dismissed_review)
            {
                # TODO: Add dismissed_review (object) and dismissed_review[review_id] once Reviews are supported

                # $null = Add-GitHubPullRequestReviewAdditionalProperties -InputObject $item.dismissed_review
                # Add-Member -InputObject $item -Name 'ReviewId' -Value $item.dismissed_review.review_id -MemberType NoteProperty -Force
            }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInrwYJKoZIhvcNAQcCoIInoDCCJ5wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBHwysUYERcjdVl
# EcYc5V/4ZaUJznPjtwSMVna0ZJ3YGqCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgQhzuxySi
# 6bje7PeUUZLyYEDeBW8ttXK+q3lt5Gj/6CwwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBALl4g+5IH15Dj9O13pY9I89TqUB7xs3/D+xWl5Vg
# xxSEgbn6fQT4n9TZhqSL80LpsJ8g9M5TVHFtG4Nvst8IEz4ktM68ilpMwgPCXWTV
# qC362Hdj6c60USIPWZUD+5KHkfFOTdr6rHfnEF4A/lIIgn9RRWRvtHURzhdnbvo6
# KKpYoHsBe+YZEtJrLPKlooKk35+uo35GSnY0F4pozD8tpK2w8hTw0Fvnii97I6Qv
# /ces2RJmB9atvYefC4TF1sbzmiH3u82tIojECY7k5/KLqs5b+61y+MXqr7vrszvK
# GJUHfgT1b+rouQ6E4ylzdazNKljZk1bRHNPbASNsr3hO/MahghcMMIIXCAYKKwYB
# BAGCNwMDATGCFvgwghb0BgkqhkiG9w0BBwKgghblMIIW4QIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgxVNu3tbb11BXH5zBiJXO6YeansGwyvpnJgZX
# wP5kRDACBmLa6J7wERgTMjAyMjA3MjUxNzI1MjEuNjEyWjAEgAIB9KCB1KSB0TCB
# zjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMg
# TWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjc4ODAtRTM5MC04MDE0MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRXzCCBxAwggT4oAMCAQICEzMAAAGoVfBhqcwwGFwA
# AQAAAagwDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjIwMzAyMTg1MTIzWhcNMjMwNTExMTg1MTIzWjCBzjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9w
# ZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjc4
# ODAtRTM5MC04MDE0MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAo9ptysAuJdfymPJe
# lww3z0pO9yaUCIPDilT4d6NmGJtR6j8dTL4/1XFaEJfuiB54o8nrvv4t5V090bmF
# O8YOBK6jfD4BybNxdnZAIZSBRF4tQpuauvTpsHTGG+1nCh6WHG0+SMkWxtMa1K35
# XsThUKM91ipBn+I3QCtdeaBsR9XILBL6Ha6igGEzlRxs+iC2vlWmB3NtQzj+ta6m
# YVWM8HVqyff7C/toEIryP1BQmuhjjLWmZlJ/RK4YxZjtybZy+tt2bteV2WOpF0db
# 4JAAHgSqI6qC6Z9H5pKmjlPvkobT6ewGSOUZKxTUGLXmnis/zylmdKinvcZ6b0ZY
# 7YZEvA/XlgScqxzPGEZj5nw0RrRDAwyJWWSx09Tsnmor2DEBCM4nOohInOEjBBa0
# QuqAmgfCSpPF6beCtjsHsM7NBOdCkpagvQdZH0qoi9oLuL1eU+/657z2P17t+YHi
# eHWG6XMQnNfpExT1MckyVs7o6s/c00QolbyOKkKfLwfV+69K4V+4Hu374or2DZzY
# 0q7kTNKzWco2q2Xgo7dTPJcta9NEM7gPk9VA51rS2qNL8BahSvEoLlk+WQsT5g+x
# Lkb4T9UKAJqCE/IFmwc0rvAeVJ//bq6EucqnpdEAiuiIRiX/nJbSZKGO+cBE+vQY
# iVKbQqupLAKNHlyRZPWwpoRvzDcCAwEAAaOCATYwggEyMB0GA1UdDgQWBBQ2x9vj
# 4vhS62U2H8zGMaSPSQsi1TAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5j
# cmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
# Q0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4ICAQBxO4JLZGqqZ/aY+vo5TJ2GZTH6bq+kQ+zN
# aKglduexFufLracX1hdMq5I1YfVAV/Jz/Y3dhMSniETxi2FgqAMz8dSFRERfdZPA
# ax5i64N5LFZElYKisAcXWTBDMgqCtRzcb65XACYb8QjUQtETEDh+3HQSGt/n1omb
# s6eCfSVNJKIpR64YD4zLqgKL9XwRPHP55uW9AA1qW0mAZ+mm5ZdhPiOKxAoRO+gm
# MG/nH4EDSgQW7uAZp4wORmOc7m91/od4qd4guz1m/AhaSBhCLZl6jNvGCUbljATG
# iLF6TGtFMNnAyiQhjFeZxyxxDTFeaH4je+juFX1kwpNr09rPmd7hxzw53DVP7rbi
# YHRZpb0cATWGiMHoJt+6d21X+PDGZ0qHXmmUlec3XIzs4v3bgeoCImKwdqek4Qnh
# Sb1veEVRcTa4Qkv1pi4iCSxVgirU/b2tHhfuXPe4QkfoI6SgTr5Rxq43olgWCE30
# jwlEFYCEdfgZAeWeCx1+1YsuINkzKeWBEJnORgjbg31zH4PfrtjByWo1joJm4CDP
# DLXa5FgVBqxgdgrWGnPJO24j8DYHxwb4czpfWN/Z324BHAfr6EuQ+23f/k0GUtek
# 6XmJnJGUGLuINeRY1reO4Z8sAnchIPI2HvK74fjJBjJGz8xWsKRZQmz0SK8sqw0n
# YH8iM2tK1jCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjc4ODAtRTM5MC04MDE0MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
# FQBsuvzEn0EHisvhiDnxfUtnmJB3LKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5oiy0zAiGA8yMDIyMDcyNTEw
# MTIzNVoYDzIwMjIwNzI2MTAxMjM1WjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDm
# iLLTAgEAMAoCAQACAgRIAgH/MAcCAQACAhHTMAoCBQDmigRTAgEAMDYGCisGAQQB
# hFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAw
# DQYJKoZIhvcNAQEFBQADgYEAu22LvnO40gJV9rWKJtE8+ro/w6VBf/UjY7hO3D1M
# paENcQXs+AgayJL7QzDi1NZBE2agA/QQbdAzrhjC4iwWF0wwf8/q3tpNEte8Hi2d
# 8F67/0WIZVlnIXLsw0L7PDEQ++SmK5umhpgxsnON0eeqbPcLj0Do7IRfvTpo55yp
# XQQxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAIT
# MwAAAahV8GGpzDAYXAABAAABqDANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCDgb/a6cP+5KGp6Xypf
# YaWMYAaTDhStSujubXk+nrOmrzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0E
# IHT+yx0AywfCc3CF8UFc+UWdG9aEepJf1gtTEEOXXGWmMIGYMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGoVfBhqcwwGFwAAQAAAagwIgQg
# lt1RpbA/nLJV7EWhxSfO/r6DFq6bNemeub0tDOIm8CYwDQYJKoZIhvcNAQELBQAE
# ggIAR8Hq17jrscBhLQ21ak1a/LDSXjq/QR1S+8xgAF5wGHjOTHeTW83lES79Nx4N
# 0ZyJ/2FoGpiR79diyoMYPb/yXxUJBz2JlCmi0QfrAlNZzo1a4Xeum/z2eWiUJRFL
# MYMXV6/+wTkmSiZuYrdfDVCbjDH00jV4TkVIo8MGBd8mBQcjy8dA6tyVR5k30iXo
# 3m/prnGhYuYbxlHM477HCr2Y6t2QN/tG6e4Zjl/dz/3xLPG+m0h5Dfb4p25stzKg
# K1v/JbVqCPbbqa+1zKdHHGFkB1LGdArnGmNbiN2voaHeduh1qTQfaVYTp0g63zYN
# 6V+UgPySV+Iibm+tE+5gmrG/fUDfBhZTSboU0RUjI+WUk1vxTatxbxJAj1MmsO0I
# J8FHDhr4YUJe0k9IJVSmH3dPzo4DZIQoEnzxImR11KeVwWPC6eSWq/TBEi8uMule
# gqHC1dT/5kPfRfSiEdmLf0dXw3UK84Qs9ZR7Aadz54pB/HaBYtaYP1tLjnOFPoQ/
# mO878AYRZcGZTMlWcDdrBh87GW2/q0i2GAF5dezYetBidKPuXCeoP210M6wmi5Qw
# xbHaydkCeCZDcSt+Xkgbp+QdCVBtcuURHqBQ0izcY5eIkCn8qmf71R0634L2WSoK
# SjxrzRFL8JQ4CjyPaGh/WqyEZaajCLSpIgvhUV6FUevVNHk=
# SIG # End signature block

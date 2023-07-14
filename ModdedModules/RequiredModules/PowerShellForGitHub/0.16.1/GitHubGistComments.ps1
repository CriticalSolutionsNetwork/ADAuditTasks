# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubGistCommentTypeName = 'GitHub.GistComment'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubGistComment
{
<#
    .SYNOPSIS
        Retrieves comments for a specific gist from GitHub.

    .DESCRIPTION
        Retrieves comments for a specific gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to retrieve the comments for.

    .PARAMETER Comment
        The ID of the specific comment on the gist that you wish to retrieve.

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
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        Get-GitHubGistComment -Gist 6cad326836d38bd3a7ae

        Gets all comments on octocat's "hello_world.rb" gist.

    .EXAMPLE
        Get-GitHubGistComment -Gist 6cad326836d38bd3a7ae -Comment 1507813

        Gets comment 1507813 from octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [string] $Gist,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
        [int64] $Comment,

        [ValidateSet('Raw', 'Text', 'Html', 'Full')]
        [string] $MediaType = 'Full',

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ($PSBoundParameters.ContainsKey('Comment'))
    {
        $telemetryProperties['SpecifiedComment'] = $true

        $uriFragment = "gists/$Gist/comments/$Comment"
        $description = "Getting comment $Comment for gist $Gist"
    }
    else
    {
        $uriFragment = "gists/$Gist/comments"
        $description = "Getting comments for gist $Gist"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' =  $description
        'AccessToken' = $AccessToken
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType -AsJson)
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubGistCommentAdditionalProperties)
}

filter Remove-GitHubGistComment
{
<#
    .SYNOPSIS
        Removes/deletes a comment from a gist on GitHub.

    .DESCRIPTION
        Removes/deletes a comment from a gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to remove the comment from.

    .PARAMETER Comment
        The ID of the comment to remove from the gist.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Comment 12324567

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Comment 12324567 -Confirm:$false

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Comment 12324567 -Force

        Removes the specified comment from octocat's "hello_world.rb" gist
        (assuming you have permission).
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact="High")]
    [Alias('Delete-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
        [int64] $Comment,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Comment, "Delete comment from gist $Gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/comments/$Comment"
        'Method' = 'Delete'
        'Description' =  "Removing comment $Comment from gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter New-GitHubGistComment
{
<#
    .SYNOPSIS
        Creates a new comment on the specified gist from GitHub.

    .DESCRIPTION
        Creates a new comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to add the comment to.

    .PARAMETER Body
        The body of the comment that you wish to leave on the gist.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        New-GitHubGistComment -Gist 6cad326836d38bd3a7ae -Body 'Hello World'

        Adds a new comment of "Hello World" to octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [string] $AccessToken
    )

    Write-InvocationLog

    $hashBody = @{
        'body' = $Body
    }

    if (-not $PSCmdlet.ShouldProcess($Gist, "Create new comment for gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/comments"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' =  "Creating new comment on gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return (Invoke-GHRestMethod @params | Add-GitHubGistCommentAdditionalProperties)
}

filter Set-GitHubGistComment
{
    <#
    .SYNOPSIS
        Edits a comment on the specified gist from GitHub.

    .DESCRIPTION
        Edits a comment on the specified gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the gist that the comment is on.

    .PARAMETER Comment
        The ID of the comment that you wish to edit.

    .PARAMETER Body
        The new text of the comment that you wish to leave on the gist.

    .PARAMETER PassThru
        Returns the updated Comment.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.Gist
        GitHub.GistComment
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .OUTPUTS
        GitHub.GistComment

    .EXAMPLE
        Set-GitHubGistComment -Gist 6cad326836d38bd3a7ae -Comment 1232456 -Body 'Hello World'

        Updates the body of the comment with ID 1232456 octocat's "hello_world.rb" gist to be
        "Hello World".
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [Alias('GistCommentId')]
        [ValidateNotNullOrEmpty()]
        [int64] $Comment,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $Body,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $hashBody = @{
        'body' = $Body
    }

    if (-not $PSCmdlet.ShouldProcess($Comment, "Update gist comment on gist $Gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/comments/$Comment"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' = "Creating new comment on gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubGistCommentAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Add-GitHubGistCommentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist Comment objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .PARAMETER GistId
        The ID of the gist that the comment is for.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistComment
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGisCommentTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistCommentTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')
            if ($item.url -match "^https?://(?:www\.|api\.|)$hostName/gists/([^/]+)/comments/(.+)$")
            {
                $gistId = $Matches[1]
                $commentId = $Matches[2]

                if ($commentId -ne $item.id)
                {
                    $message = "The gist comment url no longer follows the expected pattern.  Please contact the PowerShellForGitHubTeam: $item.url"
                    Write-Log -Message $message -Level Warning
                }
            }

            Add-Member -InputObject $item -Name 'GistCommentId' -Value $item.id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'GistId' -Value $gistId -MemberType NoteProperty -Force

            if ($null -ne $item.user)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
            }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInrwYJKoZIhvcNAQcCoIInoDCCJ5wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCpZ8N03tJRHri/
# 6gp4tCeA+qUD2iXxTuxeGDBrHtehWKCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgBImZoXVX
# GVB14XQfEKM09rPIopwpWPH5bnHxfdhKXbwwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBACZPF2UmmJlCtGbOfvG2SoFk95XE7SHIixXLXUUB
# W7lEp1C1gYEpfZPVVQMsqv8QAiI6fvWVzjx3j1kUtW/yIC58g4F5xv/N/WahsG5k
# pm31tEW3YRW5J1DNmFBgioHiNDWzNKiURsEp+k8bgI7It3IDshj4HvMGhkyicvwf
# vIr8FwkxCRCRSjF0x8McTsNQ4EtX7vdEzZy6j6ZPgLTGs2MQIiyktTKd17+oSHPM
# rgP4LZs7+SjqLQCY2cvy9aJJnYIEpe25pBfBhO6RGb8OZPFA8wG/iNrYl7yPLuiO
# YGrSq+So8FWC/M4NaMq1E2vo1hMPUZwjvGf015BAakuFwW6hghcMMIIXCAYKKwYB
# BAGCNwMDATGCFvgwghb0BgkqhkiG9w0BBwKgghblMIIW4QIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgvfkFeCX/k/4r5mCSwolYGqU9JbSzDevJlgai
# aXVjFD4CBmLbIk3HKxgTMjAyMjA3MjUxNzI1MjMuNDAzWjAEgAIB9KCB1KSB0TCB
# zjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMg
# TWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjMyQkQtRTNENS0zQjFEMSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRXzCCBxAwggT4oAMCAQICEzMAAAGt/N9NWONdMukA
# AQAAAa0wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjIwMzAyMTg1MTM2WhcNMjMwNTExMTg1MTM2WjCBzjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9w
# ZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjMy
# QkQtRTNENS0zQjFEMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA6J5TKqVNKtUuG9jt
# M7y+AL5Pk3/L8xd5Heg3ATSssjUSD+AzmD02E/4qqolz/u48vhOygAtv5FV/quhg
# 2WXJCtiaq5SPCyrbrYwPkv2X2tTWmXPa0w96E/xp11WU0iNggGHQ0LgLIwTq3FWm
# lCvt4V39tbRf22dnLVoNb7OhokHYVjyFqiSrlxE40Rbi6hWxNNewgKRtg4Bh98gg
# ZqQwVdW8HfQ1yy6IOfq4OTzdddOzS2dKvwXHM+gPxKA88hxZpY8SMJAuvkjQHF91
# SWLA08cg8SCWqiysKVGNcbutxlZtZ44OABOLSLoNSy/VafQs5biy8rj9a5z+/12W
# a4itqa/3CFuALKRS5hnLwzFPOxCpTZHFybyHz0JcDmN/WTuTdmJotQnTTcyO1O01
# fOWBv6TUDl4vXsbcLgSPDkChWIz5QEZC/G5PGkV5oahAWp44Ya0QrSqTTB1Rf2n/
# gC71eyV7kPl+/KkF2xxcGyVQFxPr4JirSRD2yaxPKFXgMr3Bv1mfs5sQ59PQBDKm
# kjqPDMGMeEAYXKspiMhuCUxoSLGNG/td02JzZW5grJLvUDSGzp1tsPH9XuENt2/a
# yu1nZVM7TLYT7hCoxEq0AG/gCCCNgrPlNga5DhVts9jx8E71eq9rcafHVkM5DecZ
# UUofBqsYNw10Hep6y+0lsgYmAmMCAwEAAaOCATYwggEyMB0GA1UdDgQWBBR9UHQd
# BLyqIVpuaoSo5X0ussbBWTAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5j
# cmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
# Q0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4ICAQCL0B1FuzH+A5J0Fed3BF6NC661Cpx7eTdu
# CzWyU+NlLHoUNenUhnOM7JPUmj/d5RYMEUl2L4d67U2jIN0af28vqvGXLUvrwrgy
# d8sGb7JvKM37FrV41rj7hw6g67ETYq3yO2ZlsiHHaO9jsX2pj+VqdHk9JtQrIKWE
# 1CHGyc1Sn8lJD6jucC5An7CwLA8KtdgTsL5O8oONrp7pZTQrhGIFcUZTXPoy3cr3
# CUwP9AZTj78gZkOYT79n+TQl8mNnLEICVyaF7euB2EPMCwbElirg9uUZlMF2vzCR
# DCk/aOCDIwxrAwzkOCDC9doNuuoJDyCSw2EJnNOp9LZ1uAsXSbsd/CVQytyfOL9t
# 1NJFbMheDlCwfW3ldpogf5NnW5kG3BcnwQ5evpL7YDqrxFBVjXQqcEfpikYT06Fc
# 9+4i7zzaa4UR2HgRds90BFRHUgxIjGDzySFIEL9gHBCEKmNOSyrkndn6PIdZngyd
# dflHjaYBHnziJFhztqBi+6i0MSpwPRT2UiOBbfU+p+plDW25hlOIZwoT1Bxga9kU
# qdV2SorxXQz176QXkKoM6swxhFXb4j8WHJCwkfEr8bncPQ7lu90iHaAOcQdEAWKF
# 1mPb1ntbSloY+i0ZfSgHmv3Co2Mzetu+4R7oUnfbcw9jXH383WDXbpP9KiSoAMkF
# MqrIFg3jMzCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOjMyQkQtRTNENS0zQjFEMSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
# FQBAktGtRVHhlsEOBY+O42pVy1TOkKCBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5ojsgzAiGA8yMDIyMDcyNTE0
# MTg0M1oYDzIwMjIwNzI2MTQxODQzWjB3MD0GCisGAQQBhFkKBAExLzAtMAoCBQDm
# iOyDAgEAMAoCAQACAh15AgH/MAcCAQACAhE2MAoCBQDmij4DAgEAMDYGCisGAQQB
# hFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAw
# DQYJKoZIhvcNAQEFBQADgYEAerBDt0O+YpFjEgejnKPpEYvTiNZf8s8s/E0/OwTS
# VJ745bX/bc/muMe9JM6JPFDNUENsWqes6PbV5h9r7uf8fehjT4N6NMZVv2hIbaHQ
# 6uzP24XAp1wyV5Vak0eZ77DToZRXVs1DcjWijhhtHbKgM/Zvp89verm2Btj4eE81
# 1B0xggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGlu
# Z3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBv
# cmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAIT
# MwAAAa38301Y410y6QABAAABrTANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcN
# AQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCCZii2gT3BRoqCgxIk+
# czXluP4tG1FUV0qJM+ZhduhsIDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0E
# IJ/qfD0JHl7X4621yfXD33YqafxgxNj8NY8gd4xsy1CCMIGYMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGt/N9NWONdMukAAQAAAa0wIgQg
# v1RM/UvAB/Pl+o6W5T2kHsh5knQbpfD6c70tw/4jPKwwDQYJKoZIhvcNAQELBQAE
# ggIAokZqMFOO+e+MUvIzjH+Kaq4LzFQ3TFPuxV38XQCHZhfJUmkxCkXQO8hvTsdC
# LhnrytATOK8AAvNXwm+EZL1NCD1UGHPz8ThpTuqCm6rditFa4N3CIjvfqIypHdlL
# qbMWCqrVnfO+yNsk4DeKrewNpAVYh4kW5npAs8wsK2lNDcuMFYmFjHLNIUfBnLox
# 0Vzhms6w9oUVmNotlq4lmxpMPlmqCbvbtdE2qMQPgmur46Fk3/94/X09K0oZyv3M
# yW7uPCWlrhgvaIcxwPQbfDbrgjoAn1+cB3kLu0qNZH+d3CBPle6Qrb5yDql4GJnT
# m92WTK7BWzFWZ7IqxTJX0me24v9bYl3ifwNX0baCF8lL6UZqUFKnaCx48w9q44xl
# J9FFWGNFV48cHEiktZdPEEGf7bWjC/ZNQV90FvJ90DU0zVOywIKkO81I8mX2naar
# EiCDxii18AsHo/DFwxtiQk6a6lTergwJBKk446vU5IkD7vjddErZ8BNmJ1PtFXQl
# 4UlaKlavrhAAyDqnvPQSZOs7IQwitww7q9biXaIaxJ8P6xbjhJG+lwH+/CrUfwjw
# Eds/e1os4MyTUUEE8KEyBZk/tf53F2fiB6PorWeOVLXhL+Eo3LzkwOuuFD3plzaa
# cIoULdKLGvKerG4/YXHK5Ccm6Du1cip0QQCGygu/xQdRgjQ=
# SIG # End signature block

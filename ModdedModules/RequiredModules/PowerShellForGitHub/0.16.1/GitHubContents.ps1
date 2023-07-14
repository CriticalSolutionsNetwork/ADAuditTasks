@{
    GitHubContentTypeName = 'GitHub.Content'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubContent
{
    <#
    .SYNOPSIS
        Retrieve the contents of a file or directory in a repository on GitHub.

    .DESCRIPTION
        Retrieve content from files on GitHub.
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

    .PARAMETER Path
        The file path for which to retrieve contents

    .PARAMETER BranchName
        The branch, or defaults to the default branch of not specified.

    .PARAMETER MediaType
        The format in which the API will return the body of the issue.

        Object - Return a json object representation a file or folder.
                 This is the default if you do not pass any specific media type.
        Raw    - Return the raw contents of a file.
        Html   - For markup files such as Markdown or AsciiDoc,
                 you can retrieve the rendered HTML using the Html media type.

    .PARAMETER ResultAsString
        If this switch is specified and the MediaType is either Raw or Html then the
        resulting bytes will be decoded the result will be  returned as a string instead of bytes.
        If the MediaType is Object, then an additional property on the object named
        'contentAsString' will be included and its value will be the decoded base64 result
        as a string.

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
        [String]
        GitHub.Content

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -MediaType Html

        Get the Html output for the README.md file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path LICENSE

        Get the Binary file output for the LICENSE file

    .EXAMPLE
        Get-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path Tests

        List the files within the "Tests" path of the repository

    .EXAMPLE
        $repo = Get-GitHubRepository -OwnerName microsoft -RepositoryName PowerShellForGitHub
        $repo | Get-GitHubContent -Path Tests

        List the files within the "Tests" path of the repository

    .NOTES
        Unable to specify Path as ValueFromPipeline because a Repository object may be incorrectly
        coerced into a string used for Path, thus confusing things.
#>
    [CmdletBinding(DefaultParameterSetName = 'Elements')]
    [OutputType([String])]
    [OutputType({$script:GitHubContentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [string] $Path,

        [ValidateNotNullOrEmpty()]
        [string] $BranchName,

        [ValidateSet('Raw', 'Html', 'Object')]
        [string] $MediaType = 'Object',

        [switch] $ResultAsString,

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

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents"

    if ($PSBoundParameters.ContainsKey('Path'))
    {
        $Path = $Path.TrimStart("\", "/")
        $uriFragment += "/$Path"
        $description = "Getting content for $Path in $RepositoryName"
    }
    else
    {
        $description = "Getting all content for in $RepositoryName"
    }

    if ($PSBoundParameters.ContainsKey('BranchName'))
    {
        $uriFragment += "?ref=$BranchName"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AcceptHeader' = (Get-MediaAcceptHeader -MediaType $MediaType)
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = Invoke-GHRestMethodMultipleResult @params

    if ($ResultAsString)
    {
        if ($MediaType -eq 'Raw' -or $MediaType -eq 'Html')
        {
            # Decode bytes to string
            $result = [System.Text.Encoding]::UTF8.GetString($result)
        }
        elseif ($MediaType -eq 'Object')
        {
            # Convert from base64
            $decoded = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($result.content))
            Add-Member -InputObject $result -NotePropertyName "contentAsString" -NotePropertyValue $decoded
        }
    }

    if ($MediaType -eq 'Object')
    {
        $null = $result | Add-GitHubContentAdditionalProperties
    }

    return $result
}

filter Set-GitHubContent
{
    <#
    .SYNOPSIS
        Sets the contents of a file or directory in a repository on GitHub.

    .DESCRIPTION
        Sets the contents of a file or directory in a repository on GitHub.

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

    .PARAMETER Path
        The file path for which to set contents.

    .PARAMETER CommitMessage
        The Git commit message.

    .PARAMETER Content
        The new file content.

    .PARAMETER Sha
        The SHA value of the current file if present. If this parameter is not provided, and the
        file currently exists in the specified branch of the repo, it will be read to obtain this
        value.

    .PARAMETER BranchName
        The branch, or defaults to the default branch if not specified.

    .PARAMETER CommitterName
        The name of the committer of the commit. Defaults to the name of the authenticated user if
        not specified. If specified, CommiterEmail must also be specified.

    .PARAMETER CommitterEmail
        The email of the committer of the commit. Defaults to the email of the authenticated user
        if not specified. If specified, CommitterName must also be specified.

    .PARAMETER AuthorName
        The name of the author of the commit. Defaults to the name of the authenticated user if
        not specified. If specified, AuthorEmail must also be specified.

    .PARAMETER AuthorEmail
        The email of the author of the commit. Defaults to the email of the authenticated user if
        not specified. If specified, AuthorName must also be specified.

    .PARAMETER PassThru
        Returns the updated GitHub Content.  By default, this cmdlet does not generate any output.
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
        GitHub.Repository

    .OUTPUTS
        GitHub.Content

    .EXAMPLE
        Set-GitHubContent -OwnerName microsoft -RepositoryName PowerShellForGitHub -Path README.md -CommitMessage 'Adding README.md' -Content '# README' -BranchName master

        Sets the contents of the README.md file on the master branch of the PowerShellForGithub repository.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubContentTypeName})]
    param(
        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $OwnerName,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Elements')]
        [string] $RepositoryName,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1,
            ParameterSetName='Uri')]
        [Alias('RepositoryUrl')]
        [string] $Uri,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 2)]
        [string] $Path,

        [Parameter(
            Mandatory,
            Position = 3)]
        [string] $CommitMessage,

        [Parameter(
            Mandatory,
            Position = 4)]
        [string] $Content,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $Sha,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string] $BranchName,

        [string] $CommitterName,

        [string] $CommitterEmail,

        [string] $AuthorName,

        [string] $AuthorEmail,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $elements = Resolve-RepositoryElements -DisableValidation
    $OwnerName = $elements.ownerName
    $RepositoryName = $elements.repositoryName

    $telemetryProperties = @{
        'OwnerName' = (Get-PiiSafeString -PlainText $OwnerName)
        'RepositoryName' = (Get-PiiSafeString -PlainText $RepositoryName)
    }

    $uriFragment = "/repos/$OwnerName/$RepositoryName/contents/$Path"

    $encodedContent = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Content))

    $hashBody = @{
        message = $CommitMessage
        content = $encodedContent
    }

    if ($PSBoundParameters.ContainsKey('BranchName'))
    {
        $hashBody['branch'] = $BranchName
    }

    if ($PSBoundParameters.ContainsKey('CommitterName') -or
        $PSBoundParameters.ContainsKey('CommitterEmail'))
    {
        if (![System.String]::IsNullOrEmpty($CommitterName) -and
            ![System.String]::IsNullOrEmpty($CommitterEmail))
        {
            $hashBody['committer'] = @{
                name = $CommitterName
                email = $CommitterEmail
            }
        }
        else
        {
            $message = 'Both CommiterName and CommitterEmail need to be specified.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('AuthorName') -or
        $PSBoundParameters.ContainsKey('AuthorEmail'))
    {
        if (![System.String]::IsNullOrEmpty($AuthorName) -and
            ![System.String]::IsNullOrEmpty($AuthorEmail))
        {
            $hashBody['author'] = @{
                name = $AuthorName
                email = $AuthorEmail
            }
        }
        else
        {
            $message = 'Both AuthorName and AuthorEmail need to be specified.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }

    if ($PSBoundParameters.ContainsKey('Sha'))
    {
        $hashBody['sha'] = $Sha
    }

    if (-not $PSCmdlet.ShouldProcess(
        "$BranchName branch of $RepositoryName",
        "Set GitHub Contents on $Path"))
    {
        return
    }

    $params = @{
        UriFragment = $uriFragment
        Description = "Writing content for $Path in the $BranchName branch of $RepositoryName"
        Body = (ConvertTo-Json -InputObject $hashBody)
        Method = 'Put'
        AccessToken = $AccessToken
        TelemetryEventName = $MyInvocation.MyCommand.Name
        TelemetryProperties = $telemetryProperties
    }

    try
    {
        $result = (Invoke-GHRestMethod @params | Add-GitHubContentAdditionalProperties)
        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
    catch
    {
        $overwriteShaRequired = $false

        # Temporary code to handle current differences in exception object between PS5 and PS7
        if ($PSVersionTable.PSedition -eq 'Core')
        {
            $errorMessage = ($_.ErrorDetails.Message | ConvertFrom-Json).message -replace '\n',' ' -replace '\"','"'
            if (($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException]) -and
                ($errorMessage -eq 'Invalid request.  "sha" wasn''t supplied.'))
            {
                $overwriteShaRequired = $true
            }
            else
            {
                throw $_
            }
        }
        else
        {
            $errorMessage = $_.Exception.Message  -replace '\n',' ' -replace '\"','"'
            if ($errorMessage -like '*Invalid request.  "sha" wasn''t supplied.*')
            {
                $overwriteShaRequired = $true
            }
            else
            {
                throw $_
            }
        }

        if ($overwriteShaRequired)
        {
            # Get SHA from current file
            $getGitHubContentParms = @{
                Path = $Path
                OwnerName = $OwnerName
                RepositoryName = $RepositoryName
            }

            if ($PSBoundParameters.ContainsKey('BranchName'))
            {
                $getGitHubContentParms['BranchName'] = $BranchName
            }

            if ($PSBoundParameters.ContainsKey('AccessToken'))
            {
                $getGitHubContentParms['AccessToken'] = $AccessToken
            }

            $object = Get-GitHubContent @getGitHubContentParms

            $hashBody['sha'] = $object.sha
            $params['body'] = ConvertTo-Json -InputObject $hashBody

            $message = 'Replacing the content of an existing file requires the current SHA ' +
                'of that file.  Retrieving the SHA now.'
            Write-Log -Level Verbose -Message $message

            $result = (Invoke-GHRestMethod @params | Add-GitHubContentAdditionalProperties)
            if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            {
                return $result
            }
        }
    }
}

filter Add-GitHubContentAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Content objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Content
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
        [string] $TypeName = $script:GitHubContentTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            if ($item.html_url)
            {
                $uri = $item.html_url
            }
            else
            {
                $uri = $item.content.html_url
            }

            $elements = Split-GitHubUri -Uri $uri
            $repositoryUrl = Join-GitHubUri @elements

            Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')

            if ($uri -match "^https?://(?:www\.|api\.|)$hostName/(?:[^/]+)/(?:[^/]+)/(?:blob|tree)/([^/]+)/([^#]*)?$")
            {
                $branchName = $Matches[1]
                $path = $Matches[2]
            }
            else
            {
                $branchName = [String]::Empty
                $path = [String]::Empty
            }

            Add-Member -InputObject $item -Name 'BranchName' -Value $branchName -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'Path' -Value $path -MemberType NoteProperty -Force
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInrwYJKoZIhvcNAQcCoIInoDCCJ5wCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAXRHaHh2/l1XhK
# nHSe+pzzJRVa9zoZxBNclcvETCoKY6CCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgwve/Li2F
# ldIxeV0baCOqzFGdY4Eprv+XwxzYa9kOBzIwRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBAJPD1hgc6FG0sRJ/GFZTpNueyoCS4kpp2mLvrGxd
# EmgYiPFauLsndE9XUq25mQWconUkHM3mT6nt2XWGOZpGDvp/kyleDRD2WSogAtGe
# jzmuMuZxq41SBt532UQ4yd6BN7WVASxbVgWdZxaKR4srLkvy3yyKoMYLf9ZmKCo0
# 3nK2JHUouO4n1lwl48Cl1bQM0LT8r04HQjGjRiz0cx5cCibr6Ey53aadBMxZR2/P
# nYpQDi+qT9uyJX1JWC8WRpJUg3mFnXy6Ww9IkuRcObCoTAxrEYauMtR9NDQTt6Fs
# 8SQ1RxAIvn09FSh80YtQ95L+TEQT3rRMYHyP4Mw7gk7zz9mhghcMMIIXCAYKKwYB
# BAGCNwMDATGCFvgwghb0BgkqhkiG9w0BBwKgghblMIIW4QIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQg5Qlikcm1qyCo6soWlQseY6vIISLpaOK2zXxh
# qrqA+aUCBmLbIk3GuRgTMjAyMjA3MjUxNzI1MTUuNjYxWjAEgAIB9KCB1KSB0TCB
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
# AQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCC0/4Jlhrd8iUq9LmGW
# lKS02jblkZJ1azPgjJJOn+HJIDCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0E
# IJ/qfD0JHl7X4621yfXD33YqafxgxNj8NY8gd4xsy1CCMIGYMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGt/N9NWONdMukAAQAAAa0wIgQg
# v1RM/UvAB/Pl+o6W5T2kHsh5knQbpfD6c70tw/4jPKwwDQYJKoZIhvcNAQELBQAE
# ggIAYWE4bNtsNb0EQThg6Cmbe2M83cs9Ep/30t86pnlHCGoiGjvEcMGv5VtzPtvI
# 8TqKgozUFvzQCFbtU2okm4aYKpGIp06aPqYqlYd7dSvPLfoBNmoEhd2MBkqluTvX
# 2T4CKj7RFq2bqOI67EXbliM6Evf6jFWjpqKUwaGrbWbHIBqmTlTBeNt83StJwluv
# VgLZK55tdwJFzsHHKvLcEmCXY5/fO9NWdCOItIitjlzha+LZbXGHrTynOCsrBNy3
# k0gpQisy79j4FiylRwz+MXp7/6Cy2nZKGP7zvYY36riU36Ats0ucLAsDVPevyVAN
# DKyxgW1S4/JUw87Q8/5+VG5ZFBPlXRb37vAo5MxeVQ0JE1i6MKCOISrbYq9DdFt3
# nOFhkB1ko1zV7ARUolLnPpyJlGn9WL7BMqkfjv+UEmmmWe74VbjdW6duOaoB34s1
# eNAQaoPLYv/grYAiq9sb3exmz4ECAwuNWoU2cBds5CA+Es5XoR0JvlMk+1gZ9ej1
# iL5S9UKL+Inbh8OfQEsLw+JbtJj0bgEWxaBKwWvEXw1vBByBkj+1PhjPm1zYujaB
# W8cTImpYVFqf872UxTHm2uRNzLcw/vG9cslsyWo6Yzgw2Hy/bqbBLLe86qJxD16N
# OD7pjUH3hvPYjzYC2DzFkzR6pDOkHnzYiXvlvx86kmisL5w=
# SIG # End signature block

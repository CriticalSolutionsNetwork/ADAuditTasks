# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubProjectCardTypeName = 'GitHub.ProjectCard'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubProjectCard
{
<#
    .SYNOPSIS
        Get the cards for a given GitHub Project Column.

    .DESCRIPTION
        Get the cards for a given GitHub Project Column.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to retrieve cards for.

    .PARAMETER State
        Only cards with this State are returned.
        Options are all, archived, or NotArchived (default).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999

        Get the the not_archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -State All

        Gets all the cards for column 999999, no matter the State.

    .EXAMPLE
        Get-GitHubProjectCard -Column 999999 -State Archived

        Gets the archived cards for column 999999.

    .EXAMPLE
        Get-GitHubProjectCard -Card 999999

        Gets the card with ID 999999.
#>
    [CmdletBinding(DefaultParameterSetName = 'Card')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Column')]
        [Alias('ColumnId')]
        [int64] $Column,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Card')]
        [Alias('CardId')]
        [int64] $Card,

        [ValidateSet('All', 'Archived', 'NotArchived')]
        [Alias('ArchivedState')]
        [string] $State = 'NotArchived',

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty

    if ($PSCmdlet.ParameterSetName -eq 'Column')
    {
        $telemetryProperties['Column'] = $true

        $uriFragment = "/projects/columns/$Column/cards"
        $description = "Getting cards for column $Column"
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Card')
    {
        $telemetryProperties['Card'] = $true

        $uriFragment = "/projects/columns/cards/$Card"
        $description = "Getting project card $Card"
    }

    if ($PSBoundParameters.ContainsKey('State'))
    {
        $getParams = @()
        $Archived = $State.ToLower().Replace('notarchived','not_archived')
        $getParams += "archived_state=$Archived"

        $uriFragment = "$uriFragment`?" + ($getParams -join '&')
        $description += " with State '$Archived'"
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethodMultipleResult @params | Add-GitHubProjectCardAdditionalProperties)
}

filter New-GitHubProjectCard
{
<#
    .SYNOPSIS
        Creates a new card for a GitHub project.

    .DESCRIPTION
        Creates a new card for a GitHub project.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Column
        ID of the column to create a card for.

    .PARAMETER Note
        The name of the column to create.

    .PARAMETER IssueId
        The ID of the issue you want to associate with this card (not to be confused with
        the Issue _number_ which you see in the URL and can refer to with a hashtag).

    .PARAMETER PullRequestId
        The ID of the pull request you want to associate with this card (not to be confused with
        the Pull Request _number_ which you see in the URL and can refer to with a hashtag).

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.IssueComment
        GitHub.Issue
        GitHub.PullRequest
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -Note 'Note on card'

        Creates a card on column 999999 with the note 'Note on card'.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -IssueId 888888

        Creates a card on column 999999 for the issue with ID 888888.

    .EXAMPLE
        New-GitHubProjectCard -Column 999999 -PullRequestId 888888

        Creates a card on column 999999 for the pull request with ID 888888.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Note')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [Parameter(
            Mandatory,
            ParameterSetName = 'Note')]
        [Alias('Content')]
        [string] $Note,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'Issue')]
        [int64] $IssueId,

        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName = 'PullRequest')]
        [int64] $PullRequestId,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/$Column/cards"
    $apiDescription = "Creating project card"

    if ($PSCmdlet.ParameterSetName -eq 'Note')
    {
        $telemetryProperties['Note'] = $true

        $hashBody = @{
            'note' = $Note
        }
    }
    elseif ($PSCmdlet.ParameterSetName -in ('Issue', 'PullRequest'))
    {
        $contentType = $PSCmdlet.ParameterSetName
        $telemetryProperties['ContentType'] = $contentType

        $hashBody = @{
            'content_type' = $contentType
        }

        if ($PSCmdlet.ParameterSetName -eq 'Issue')
        {
            $hashBody['content_id'] = $IssueId
        }
        else
        {
            $hashBody['content_id'] = $PullRequestId
        }
    }

    if (-not $PSCmdlet.ShouldProcess($Column, 'Create GitHub Project Card'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Post'
        'Description' = $apiDescription
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return (Invoke-GHRestMethod @params | Add-GitHubProjectCardAdditionalProperties)
}

filter Set-GitHubProjectCard
{
<#
    .SYNOPSIS
        Modify a GitHub Project Card.

    .DESCRIPTION
        Modify a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to modify.

    .PARAMETER Note
        The note content for the card.  Only valid for cards without another type of content,
        so this cannot be specified if the card already has a content_id and content_type.

    .PARAMETER Archive
        Archive a project card.

    .PARAMETER Restore
        Restore a project card.

    .PARAMETER PassThru
        Returns the updated Project Card.  By default, this cmdlet does not generate any output.
        You can use "Set-GitHubConfiguration -DefaultPassThru" to control the default behavior
        of this switch.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard

    .OUTPUTS
        GitHub.ProjectCard

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Note UpdatedNote

        Sets the card note to 'UpdatedNote' for the card with ID 999999.

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Archive

        Archives the card with ID 999999.

    .EXAMPLE
        Set-GitHubProjectCard -Card 999999 -Restore

        Restores the card with ID 999999.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName = 'Note')]
    [OutputType({$script:GitHubProjectCardTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [Alias('Content')]
        [string] $Note,

        [Parameter(ParameterSetName = 'Archive')]
        [switch] $Archive,

        [Parameter(ParameterSetName = 'Restore')]
        [switch] $Restore,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card"
    $apiDescription = "Updating card $Card"

    $hashBody = @{}

    if ($PSBoundParameters.ContainsKey('Note'))
    {
        $telemetryProperties['Note'] = $true
        $hashBody.add('note', $Note)
    }

    if ($Archive)
    {
        $telemetryProperties['Archive'] = $true
        $hashBody.add('archived', $true)
    }

    if ($Restore)
    {
        $telemetryProperties['Restore'] = $true
        $hashBody.add('archived', $false)
    }

    if (-not $PSCmdlet.ShouldProcess($Card, 'Set GitHub Project Card'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Patch'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    $result = (Invoke-GHRestMethod @params | Add-GitHubProjectCardAdditionalProperties)
    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Remove-GitHubProjectCard
{
<#
    .SYNOPSIS
        Removes a project card.

    .DESCRIPTION
        Removes a project card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to remove.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999

        Remove project card with ID 999999.

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999 -Confirm:$False

        Remove project card with ID 999999 without prompting for confirmation.

    .EXAMPLE
        Remove-GitHubProjectCard -Card 999999 -Force

        Remove project card with ID 999999 without prompting for confirmation.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubProjectCard')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card"
    $description = "Deleting card $Card"

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Card, 'Remove GitHub Project Card'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $description
        'AccessToken' = $AccessToken
        'Method' = 'Delete'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}

filter Move-GitHubProjectCard
{
<#
    .SYNOPSIS
        Move a GitHub Project Card.

    .DESCRIPTION
        Move a GitHub Project Card.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Card
        ID of the card to move.

    .PARAMETER Top
        Moves the card to the top of the column.

    .PARAMETER Bottom
        Moves the card to the bottom of the column.

    .PARAMETER After
        Moves the card to the position after the card ID specified.

    .PARAMETER Column
        The ID of a column in the same project to move the card to.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        GitHub.ProjectCard
        GitHub.ProjectColumn

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Top

        Moves the project card with ID 999999 to the top of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -Bottom

        Moves the project card with ID 999999 to the bottom of the column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -After 888888

        Moves the project card with ID 999999 to the position after the card ID 888888.
        Within the same column.

    .EXAMPLE
        Move-GitHubProjectCard -Card 999999 -After 888888 -Column 123456

        Moves the project card with ID 999999 to the position after the card ID 888888, in
        the column with ID 123456.
#>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName)]
        [Alias('CardId')]
        [int64] $Card,

        [switch] $Top,

        [switch] $Bottom,

        [int64] $After,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('ColumnId')]
        [int64] $Column,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = "/projects/columns/cards/$Card/moves"
    $apiDescription = "Updating card $Card"

    if (-not ($Top -xor $Bottom -xor ($After -gt 0)))
    {
        $message = 'You must use one (and only one) of the parameters Top, Bottom or After.'
        Write-Log -Message $message -level Error
        throw $message
    }
    elseif ($Top)
    {
        $position = 'top'
    }
    elseif ($Bottom)
    {
        $position = 'bottom'
    }
    else
    {
        $position = "after:$After"
    }

    $hashBody = @{
        'position' = $Position
    }

    if ($PSBoundParameters.ContainsKey('Column'))
    {
        $telemetryProperties['Column'] = $true
        $hashBody.add('column_id', $Column)
    }

    if (-not $PSCmdlet.ShouldProcess($Card, 'Move GitHub Project Card'))
    {
        return
    }

    $params = @{
        'UriFragment' = $uriFragment
        'Description' = $apiDescription
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'AccessToken' = $AccessToken
        'Method' = 'Post'
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'AcceptHeader' = $script:inertiaAcceptHeader
    }

    return Invoke-GHRestMethod @params
}


filter Add-GitHubProjectCardAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Project Card objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.ProjectCard
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
        [string] $TypeName = $script:GitHubProjectCardTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'CardId' -Value $item.id -MemberType NoteProperty -Force

            if ($item.project_url -match '^.*/projects/(\d+)$')
            {
                $projectId = $Matches[1]
                Add-Member -InputObject $item -Name 'ProjectId' -Value $projectId -MemberType NoteProperty -Force
            }

            if ($item.column_url -match '^.*/columns/(\d+)$')
            {
                $columnId = $Matches[1]
                Add-Member -InputObject $item -Name 'ColumnId' -Value $columnId -MemberType NoteProperty -Force
            }

            if ($null -ne $item.content_url)
            {
                $elements = Split-GitHubUri -Uri $item.content_url
                $repositoryUrl = Join-GitHubUri @elements
                Add-Member -InputObject $item -Name 'RepositoryUrl' -Value $repositoryUrl -MemberType NoteProperty -Force

                if ($item.content_url -match '^.*/issues/(\d+)$')
                {
                    $issueNumber = $Matches[1]
                    Add-Member -InputObject $item -Name 'IssueNumber' -Value $issueNumber -MemberType NoteProperty -Force
                }
                elseif ($item.content_url -match '^.*/pull/(\d+)$')
                {
                    $pullRequestNumber = $Matches[1]
                    Add-Member -InputObject $item -Name 'PullRequestNumber' -Value $pullRequestNumber -MemberType NoteProperty -Force
                }
            }

            if ($null -ne $item.creator)
            {
                $null = Add-GitHubUserAdditionalProperties -InputObject $item.creator
            }
        }

        Write-Output $item
    }
}

# SIG # Begin signature block
# MIInuAYJKoZIhvcNAQcCoIInqTCCJ6UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCK+cg24/Q2MaD7
# eJeXWJhFQCmQpOphE2kG20e/dz0ftKCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZjTCCGYkCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBsDAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgAxrlyJm1
# vlRGk+k7wD0Mb0d7zYuciJzYY7Ne+LKHDM0wRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBAHLolBhTlVwInpUcw6JHQx0JDL7jm1mSGM7M4aHX
# j2hfH+0oLm1h6dGPKKkEKOWBRaLAnUT+xs4b+PgOt8KK/1HOQiOhTRoDS9nl7xyP
# pl75UGceKIWkXIsh32q+EcxaaMMfsXicCcN7XWH50JgvZVld1H15FhSiq4DkaxD8
# SjnPV0Glmd81U5qW1UMqWXZneTD+8QG8KWfPjH/y+MXrSdl/FrIxBLiEMW3++QWW
# 76nikGB+KRj5pHXq60nVq4FzI2zTkLgyq8QHl6r2WXTSIW4ZPrkIDj36Xf4uRb4F
# 680EjEJCdadOEzVUpAbxqP+N8xW41pQyXMyCs7/UiXGC2bOhghcVMIIXEQYKKwYB
# BAGCNwMDATGCFwEwghb9BgkqhkiG9w0BBwKgghbuMIIW6gIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBWQYLKoZIhvcNAQkQAQSgggFIBIIBRDCCAUACAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgQYlxq4/rY8b2UcfE+1I9d6lKnbtIM7b8UnCh
# 5VsuD28CBmLeYUyGbRgTMjAyMjA3MjUxNzI1NDYuNjYzWjAEgAIB9KCB2KSB1TCB
# 0jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMk
# TWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1U
# aGFsZXMgVFNTIEVTTjoyQUQ0LTRCOTItRkEwMTElMCMGA1UEAxMcTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgU2VydmljZaCCEWQwggcUMIIE/KADAgECAhMzAAABhnjlGYn4
# JEvMAAEAAAGGMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBD
# QSAyMDEwMB4XDTIxMTAyODE5MjczOVoXDTIzMDEyNjE5MjczOVowgdIxCzAJBgNV
# BAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4w
# HAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29m
# dCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRT
# UyBFU046MkFENC00QjkyLUZBMDExJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFNlcnZpY2UwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDAjcbZ
# am/oHgiMB+uB8mmd0849g7Vh3z6+V+gjExbeB0INP7Mhtp+DXik67S3R6RRDHrSn
# s9p0fg6Oeo0gTWrqV0f2e2PWAh2Xgerit0QdNnokV0TbgNJtWiqpH5HgjDjDcY9t
# 9zZDeR/LIXKP4M6GYJbD8VmJNVOVPht16PIBbqv8mfh+vfEuNu+EhNq2vfpXLLOB
# DRjhavvcfeBRwuNi7SqIe60MNvr6n7IMEaYoXOc5bzBW3sP67ZUQmgTomUrQSlUt
# m6x1LOF5y5TAlfFva7KABleWxr98eXBb1ieUGowcn6Kb0e4rlfjHz/kHl2S4ihfm
# VYaMUxsPYDou78+ZQHiErQIXkbVhpS0GswTvcMAqTKmTtISbcGUlfBj8atWhdZhQ
# YQfJ+uQuTCzRGgQymggSB5tk0qqNHKdEmBHh88IqsSHASJNMBzgNcZyLgcc6brgR
# DWD9IMcwWogpVLGhRuQZt0o0oeGZqG4isDLjB72zutkmyS95lhmIOa0C0G3+BCiP
# FtnW870LXVK2GSuaSRMwtB/1wPOVUQF67oqYdfZLN7qCCd7cjhzL/khQucdneszh
# mklzSzYqkYsdpWsRDLjH+YCfjJph+B4fcwQBaRWPL+pMOHpwMIX+DLPdNpAO28Wc
# ArvQuq1sS8E90Gl4Ib+GT2XSVpjPCLLIZj8eowIDAQABo4IBNjCCATIwHQYDVR0O
# BBYEFBm2o0UD72Z0S7+HfdSEcw3rCFwuMB8GA1UdIwQYMBaAFJ+nFV0AXmJdg/Tl
# 0mWnG1M1GelyMF8GA1UdHwRYMFYwVKBSoFCGTmh0dHA6Ly93d3cubWljcm9zb2Z0
# LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQQ0ElMjAy
# MDEwKDEpLmNybDBsBggrBgEFBQcBAQRgMF4wXAYIKwYBBQUHMAKGUGh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY2VydHMvTWljcm9zb2Z0JTIwVGltZS1T
# dGFtcCUyMFBDQSUyMDIwMTAoMSkuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAww
# CgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQADggIBAMPuZ6Eljd9McoLiGP7AFYHz
# nji5omIwwgeeEr041MztWtpNjPHRT9NwsnqDHDW1HMzm67ySzAk2Uc2ntF52wCLC
# +JVBlX0AvwhtlEslPA16ELCT4FVxjaCHdkZmbHy5q09mtG57KGFNMPY+8VUut/CH
# aWIMb90Q80gdMqPv0OURw8hag4JSnunQ5EzBD3mRVqJulfz2m+OE+XYWbQIE7eld
# cmDRvJ2lDl0MNO/+pvT5ZgX+81URT8ygwRCqVRZa5cQJOrHpNrIm4snq5TsrlDJO
# RD+XbgiEaMPN/kARk6sg1jORZXI19Q6kjGcqxZME3aKOln9O6fmquaj280gNPSWh
# uCe6Vp7Xs1oQ72iIQkkfW1Dfnd2G5GL4DTQ9HvzWJiXMXklTUOsR8TI3HwJaARGL
# 3QsqxiCFkEIONDcOImN9Rkuo414esl9yaHPn9t+bz5oBpQ+lkV4/SDQiid3pc2Th
# iJhtY8Wih9zQvBypIAu24gDLPp/d35RplmynjVTiEIigaPqGgMi5Tzf1uj+Zn8CA
# RLAbEhezSBlToD7aohR7rRB0D3r3BZLO5wo6KyeD0cJJksXV2pzdBRrCvQLRTjXv
# zgqj29yQAbdqTBi5UZyzqEz9KoSGh72MfB7henzUKtMHWX34Qh26QJs/STLPHRZn
# O156IM3mt2KJBH2YEm6WMIIHcTCCBVmgAwIBAgITMwAAABXF52ueAptJmQAAAAAA
# FTANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hp
# bmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jw
# b3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNhdGUgQXV0
# aG9yaXR5IDIwMTAwHhcNMjEwOTMwMTgyMjI1WhcNMzAwOTMwMTgzMjI1WjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAOThpkzntHIhC3miy9ckeb0O1YLT/e6cBwfSqWxOdcjKNVf2AX9s
# SuDivbk+F2Az/1xPx2b3lVNxWuJ+Slr+uDZnhUYjDLWNE893MsAQGOhgfWpSg0S3
# po5GawcU88V29YZQ3MFEyHFcUTE3oAo4bo3t1w/YJlN8OWECesSq/XJprx2rrPY2
# vjUmZNqYO7oaezOtgFt+jBAcnVL+tuhiJdxqD89d9P6OU8/W7IVWTe/dvI2k45GP
# sjksUZzpcGkNyjYtcI4xyDUoveO0hyTD4MmPfrVUj9z6BVWYbWg7mka97aSueik3
# rMvrg0XnRm7KMtXAhjBcTyziYrLNueKNiOSWrAFKu75xqRdbZ2De+JKRHh09/SDP
# c31BmkZ1zcRfNN0Sidb9pSB9fvzZnkXftnIv231fgLrbqn427DZM9ituqBJR6L8F
# A6PRc6ZNN3SUHDSCD/AQ8rdHGO2n6Jl8P0zbr17C89XYcz1DTsEzOUyOArxCaC4Q
# 6oRRRuLRvWoYWmEBc8pnol7XKHYC4jMYctenIPDC+hIK12NvDMk2ZItboKaDIV1f
# MHSRlJTYuVD5C4lh8zYGNRiER9vcG9H9stQcxWv2XFJRXRLbJbqvUAV6bMURHXLv
# jflSxIUXk8A8FdsaN8cIFRg/eKtFtvUeh17aj54WcmnGrnu3tz5q4i6tAgMBAAGj
# ggHdMIIB2TASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQBgjcVAgQWBBQqp1L+
# ZMSavoKRPEY1Kc8Q/y8E7jAdBgNVHQ4EFgQUn6cVXQBeYl2D9OXSZacbUzUZ6XIw
# XAYDVR0gBFUwUzBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMG
# A1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsG
# A1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJc
# YmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
# b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIz
# LmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0
# MA0GCSqGSIb3DQEBCwUAA4ICAQCdVX38Kq3hLB9nATEkW+Geckv8qW/qXBS2Pk5H
# ZHixBpOXPTEztTnXwnE2P9pkbHzQdTltuw8x5MKP+2zRoZQYIu7pZmc6U03dmLq2
# HnjYNi6cqYJWAAOwBb6J6Gngugnue99qb74py27YP0h1AdkY3m2CDPVtI1TkeFN1
# JFe53Z/zjj3G82jfZfakVqr3lbYoVSfQJL1AoL8ZthISEV09J+BAljis9/kpicO8
# F7BUhUKz/AyeixmJ5/ALaoHCgRlCGVJ1ijbCHcNhcy4sa3tuPywJeBTpkbKpW99J
# o3QMvOyRgNI95ko+ZjtPu4b6MhrZlvSP9pEB9s7GdP32THJvEKt1MMU0sHrYUP4K
# WN1APMdUbZ1jdEgssU5HLcEUBHG/ZPkkvnNtyo4JvbMBV0lUZNlz138eW0QBjloZ
# kWsNn6Qo3GcZKCS6OEuabvshVGtqRRFHqfG3rsjoiV5PndLQTHa1V1QJsWkBRH58
# oWFsc/4Ku+xBZj1p/cvBQUl+fpO+y/g75LcVv7TOPqUxUYS8vwLBgqJ7Fx0ViY1w
# /ue10CgaiQuPNtq6TPmb/wrpNPgkNWcr4A245oyZ1uEi6vAnQj0llOZ0dFtq0Z4+
# 7X6gMTN9vMvpe784cETRkPHIqzqKOghif9lwY1NNje6CbaUFEMFxBmoQtB1VM1iz
# oXBm8qGCAtMwggI8AgEBMIIBAKGB2KSB1TCB0jELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3Bl
# cmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoyQUQ0LTRC
# OTItRkEwMTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZaIj
# CgEBMAcGBSsOAwIaAxUAAa7YNHNaQqWOZfJJfWSiscvh8yeggYMwgYCkfjB8MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNy
# b3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMDANBgkqhkiG9w0BAQUFAAIFAOaI38sw
# IhgPMjAyMjA3MjUxNzI0MjdaGA8yMDIyMDcyNjE3MjQyN1owczA5BgorBgEEAYRZ
# CgQBMSswKTAKAgUA5ojfywIBADAGAgEAAgEEMAcCAQACAhFTMAoCBQDmijFLAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAPagvAoHkIImvDuQgpoQo9mcext1k
# e8BHA5jhQ3O7Pf7YULQv/A9Aomdbw5SHP7190g2Rt/KqcK85/1GUaMOmkF4lMqKV
# aZngi9ftVNT6BdXkUAeuRtCT4wBJMLBukvJd+DlU1qdNSAXnPBtYbowtnVpAYXOV
# hwGN4LWpSPzy1RAxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAAYZ45RmJ+CRLzAABAAABhjANBglghkgBZQMEAgEFAKCCAUow
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCCJ4HnT
# ylV44tK7fh/PmIpIdKxrVpKCsqQ9KFbXPSG5DTCB+gYLKoZIhvcNAQkQAi8xgeow
# gecwgeQwgb0EIBqZiOCyLAhUxomMn0QEe5uxWtoLsVTSMNe5nAIqvEJ+MIGYMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGGeOUZifgkS8wA
# AQAAAYYwIgQgRoln6+cBeekSyEQzSKvD23k+uL67bYHyH4DOFEObFRowDQYJKoZI
# hvcNAQELBQAEggIAvCwnuz5ViJ/usEoZMPTAuv5eBAHtw8I/p3J95UmoRaGQQ7yO
# rMuH7Oc1/8Tm+XCglYCBggmyYvetO/o0rFD/GLWLlulHFAN5tb7tAeau69XNXkN5
# Be6e94kxNKwXBoptCoBr1yP0P2oMbAT5BEvorYGdsaVpkrlzXIQ6dfYY6j6xMnVS
# WT6lnFODIWtzaHLG/NE1/8YJq2a/bNWERKJ2t+uKrCUbuW2RZ4rtVNKxZ7zKme9W
# hHq3AcwkcRcmglFdcY7m9MV/DqQqiE5bL/h9cDskKarKcaE5mosMHfFVXnZeaETH
# D3MwzP09/1qUmJ6Me+e9BZ1GjBLSpZL9pc4GZUjJZCI0ZZjfoiZ+fVu8EyRD6n+o
# 2pZk6b1p+V52EdodOFmhFJR0cR2Kbk417p01D7U2nNQKWX2YZ9C51wijyNPwW+IM
# XYjwk3DuAad5RFLTOGxN1mJPQ5Ev/8C4BairVkfKK5SNw/MG7qQu8WCQ925uBJ9D
# v+K2zmou98iHlw0kYv9WNTKANJiehA7NSyLFlcfqESnRBNRlUXhcjaZng+GlGEqT
# pSLOWVmNcNyN0iOBKZ+ACvStrwt0S5QAnqjnsTRZZI2hZSAz9/zDhyFLfKaa24xg
# hz7z0GBW1DNoEvRtlTikoQkQp6O6uN5Ne/bUOkxfgthNV3AETFmEv0ApoRI=
# SIG # End signature block

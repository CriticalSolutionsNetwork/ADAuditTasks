# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

@{
    GitHubGistTypeName = 'GitHub.Gist'
    GitHubGistCommitTypeName = 'GitHub.GistCommit'
    GitHubGistForkTypeName = 'GitHub.GistFork'
    GitHubGistSummaryTypeName = 'GitHub.GistSummary'
 }.GetEnumerator() | ForEach-Object {
     Set-Variable -Scope Script -Option ReadOnly -Name $_.Key -Value $_.Value
 }

filter Get-GitHubGist
{
<#
    .SYNOPSIS
        Retrieves gist information from GitHub.

    .DESCRIPTION
        Retrieves gist information from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to retrieve.

    .PARAMETER Sha
        The specific revision of the gist that you wish to retrieve.

    .PARAMETER Forks
        Gets the forks of the specified gist.

    .PARAMETER Commits
        Gets the commits of the specified gist.

    .PARAMETER UserName
        Gets public gists for the specified user.

    .PARAMETER Path
        Download the files that are part of the specified gist to this path.

    .PARAMETER Force
        If downloading files, this will overwrite any files with the same name in the provided path.

    .PARAMETER Current
        Gets the authenticated user's gists.

    .PARAMETER Starred
        Gets the authenticated user's starred gists.

    .PARAMETER Public
        Gets public gists sorted by most recently updated to least recently updated.
        The results will be limited to the first 3000.

    .PARAMETER Since
        Only gists updated at or after this time are returned.

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
        GitHub.Gist
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary

    .EXAMPLE
        Get-GitHubGist -Starred

        Gets all starred gists for the current authenticated user.

    .EXAMPLE
        Get-GitHubGist -Public -Since ((Get-Date).AddDays(-2))

        Gets all public gists that have been updated within the past two days.

    .EXAMPLE
        Get-GitHubGist -Gist 6cad326836d38bd3a7ae

        Gets octocat's "hello_world.rb" gist.
#>
    [CmdletBinding(
        DefaultParameterSetName='Current',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [OutputType({$script:GitHubGistCommitTypeName})]
    [OutputType({$script:GitHubGistForkTypeName})]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Id',
            Position = 1)]
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            ParameterSetName='Download',
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [Parameter(ParameterSetName='Id')]
        [Parameter(ParameterSetName='Download')]
        [ValidateNotNullOrEmpty()]
        [string] $Sha,

        [Parameter(ParameterSetName='Id')]
        [switch] $Forks,

        [Parameter(ParameterSetName='Id')]
        [switch] $Commits,

        [Parameter(
            Mandatory,
            ParameterSetName='User')]
        [ValidateNotNullOrEmpty()]
        [string] $UserName,

        [Parameter(
            Mandatory,
            ParameterSetName='Download',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [Parameter(ParameterSetName='Download')]
        [switch] $Force,

        [Parameter(ParameterSetName='Current')]
        [switch] $Current,

        [Parameter(ParameterSetName='Current')]
        [switch] $Starred,

        [Parameter(ParameterSetName='Public')]
        [switch] $Public,

        [Parameter(ParameterSetName='User')]
        [Parameter(ParameterSetName='Current')]
        [Parameter(ParameterSetName='Public')]
        [DateTime] $Since,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $uriFragment = [String]::Empty
    $description = [String]::Empty
    $outputType = $script:GitHubGistSummaryTypeName

    if ($PSCmdlet.ParameterSetName -in ('Id', 'Download'))
    {
        $telemetryProperties['ById'] = $true

        if ($PSBoundParameters.ContainsKey('Sha'))
        {
            if ($Forks -or $Commits)
            {
                $message = 'Cannot check for forks or commits of a specific SHA.  Do not specify SHA if you want to list out forks or commits.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $telemetryProperties['SpecifiedSha'] = $true

            $uriFragment = "gists/$Gist/$Sha"
            $description = "Getting gist $Gist with specified Sha"
            $outputType = $script:GitHubGistTypeName
        }
        elseif ($Forks)
        {
            $uriFragment = "gists/$Gist/forks"
            $description = "Getting forks of gist $Gist"
            $outputType = $script:GitHubGistForkTypeName
        }
        elseif ($Commits)
        {
            $uriFragment = "gists/$Gist/commits"
            $description = "Getting commits of gist $Gist"
            $outputType = $script:GitHubGistCommitTypeName
        }
        else
        {
            $uriFragment = "gists/$Gist"
            $description = "Getting gist $Gist"
            $outputType = $script:GitHubGistTypeName
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'User')
    {
        $telemetryProperties['ByUserName'] = $true

        $uriFragment = "users/$UserName/gists"
        $description = "Getting public gists for $UserName"
        $outputType = $script:GitHubGistSummaryTypeName
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Current')
    {
        $telemetryProperties['CurrentUser'] = $true
        $outputType = $script:GitHubGistSummaryTypeName

        if ((Test-GitHubAuthenticationConfigured) -or (-not [String]::IsNullOrEmpty($AccessToken)))
        {
            if ($Starred)
            {
                $uriFragment = 'gists/starred'
                $description = 'Getting starred gists for current authenticated user'
            }
            else
            {
                $uriFragment = 'gists'
                $description = 'Getting gists for current authenticated user'
            }
        }
        else
        {
            if ($Starred)
            {
                $message = 'Starred can only be specified for authenticated users.  Either call Set-GitHubAuthentication first, or provide a value for the AccessToken parameter.'
                Write-Log -Message $message -Level Error
                throw $message
            }

            $message = 'Specified -Current, but not currently authenticated.  Either call Set-GitHubAuthentication first, or provide a value for the AccessToken parameter.'
            Write-Log -Message $message -Level Error
            throw $message
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'Public')
    {
        $telemetryProperties['Public'] = $true
        $outputType = $script:GitHubGistSummaryTypeName

        $uriFragment = "gists/public"
        $description = 'Getting public gists'
    }

    $getParams = @()
    $sinceFormattedTime = [String]::Empty
    if ($null -ne $Since)
    {
        $sinceFormattedTime = $Since.ToUniversalTime().ToString('o')
        $getParams += "since=$sinceFormattedTime"
    }

    $params = @{
        'UriFragment' = $uriFragment + '?' +  ($getParams -join '&')
        'Description' =  $description
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethodMultipleResult @params |
        Add-GitHubGistAdditionalProperties -TypeName $outputType)

    if ($PSCmdlet.ParameterSetName -eq 'Download')
    {
        Save-GitHubGist -GistObject $result -Path $Path -Force:$Force
    }
    else
    {
        if ($result.truncated -eq $true)
        {
            $message = @(
                'Response has been truncated.  The API will only return the first 3000 gist results',
                'the first 300 files within the gist, and the first 1 Mb of an individual',
                'file.  If the file has been truncated, you can call',
                '(Invoke-WebRequest -UseBasicParsing -Method Get -Uri <raw_url>).Content)',
                'where <raw_url> is the value of raw_url for the file in question.  Be aware that',
                'for files larger than 10 Mb, you''ll need to clone the gist via the URL provided',
                'by git_pull_url.')

            Write-Log -Message ($message -join ' ') -Level Warning
        }

        return $result
    }
}

function Save-GitHubGist
{
<#
    .SYNOPSIS
        Downloads the contents of a gist to the specified file path.

    .DESCRIPTION
        Downloads the contents of a gist to the specified file path.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER GistObject
        The Gist PSCustomObject

    .PARAMETER Path
        Download the files that are part of the specified gist to this path.

    .PARAMETER Force
        If downloading files, this will overwrite any files with the same name in the provided path.

    .NOTES
        Internal-only helper
#>
    [CmdletBinding(PositionalBinding = $false)]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $GistObject,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [switch] $Force
    )

    # First, check to see if the response is missing files.
    if ($GistObject.truncated)
    {
        $message = @(
            'Gist response has been truncated.  The API will only return information on',
            'the first 300 files within a gist. To download this entire gist,',
            'you''ll need to clone it via the URL provided by git_pull_url',
            "[$($GistObject.git_pull_url)].")

        Write-Log -Message ($message -join ' ') -Level Error
        throw $message
    }

    # Then check to see if there are files we won't be able to download
    $files = $GistObject.files | Get-Member -Type NoteProperty | Select-Object -ExpandProperty Name
    foreach ($fileName in $files)
    {
        if ($GistObject.files.$fileName.truncated -and
            ($GistObject.files.$fileName.size -gt 10mb))
        {
            $message = @(
                "At least one file ($fileName) in this gist is larger than 10mb.",
                'In order to download this gist, you''ll need to clone it via the URL',
                "provided by git_pull_url [$($GistObject.git_pull_url)].")

            Write-Log -Message ($message -join ' ') -Level Error
            throw $message
        }
    }

    # Finally, we're ready to directly save the non-truncated files,
    # and download the ones that are between 1 - 10mb.
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
    try
    {
        $headers = @{}
        $AccessToken = Get-AccessToken -AccessToken $AccessToken
        if (-not [String]::IsNullOrEmpty($AccessToken))
        {
            $headers['Authorization'] = "token $AccessToken"
        }

        $Path = Resolve-UnverifiedPath -Path $Path
        $null = New-Item -Path $Path -ItemType Directory -Force
        foreach ($fileName in $files)
        {
            $filePath = Join-Path -Path $Path -ChildPath $fileName
            if ((Test-Path -Path $filePath -PathType Leaf) -and (-not $Force))
            {
                $message = "File already exists at path [$filePath].  Choose a different path or specify -Force"
                Write-Log -Message $message -Level Error
                throw $message
            }

            if ($GistObject.files.$fileName.truncated)
            {
                # Disable Progress Bar in function scope during Invoke-WebRequest
                $ProgressPreference = 'SilentlyContinue'

                $webRequestParams = @{
                    UseBasicParsing = $true
                    Method = 'Get'
                    Headers = $headers
                    Uri = $GistObject.files.$fileName.raw_url
                    OutFile = $filePath
                }

                Invoke-WebRequest @webRequestParams
            }
            else
            {
                $stream = New-Object -TypeName System.IO.StreamWriter -ArgumentList ($filePath)
                try
                {
                    $stream.Write($GistObject.files.$fileName.content)
                }
                finally
                {
                    $stream.Close()
                }
            }
        }
    }
    finally
    {
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
    }
}

filter Remove-GitHubGist
{
<#
    .SYNOPSIS
        Removes/deletes a gist from GitHub.

    .DESCRIPTION
        Removes/deletes a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to retrieve.

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
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae

        Removes octocat's "hello_world.rb" gist (assuming you have permission).

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Confirm:$false

        Removes octocat's "hello_world.rb" gist (assuming you have permission).
        Will not prompt for confirmation, as -Confirm:$false was specified.

    .EXAMPLE
        Remove-GitHubGist -Gist 6cad326836d38bd3a7ae -Force

        Removes octocat's "hello_world.rb" gist (assuming you have permission).
        Will not prompt for confirmation, as -Force was specified.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false,
        ConfirmImpact = 'High')]
    [Alias('Delete-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $Force,

        [string] $AccessToken
    )

    Write-InvocationLog

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Gist, "Delete gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist"
        'Method' = 'Delete'
        'Description' =  "Removing gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Copy-GitHubGist
{
<#
    .SYNOPSIS
        Forks a gist from GitHub.

    .DESCRIPTION
        Forks a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to fork.

    .PARAMETER PassThru
        Returns the newly created gist fork.  By default, this cmdlet does not generate any output.
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
        GitHub.GistSummary

    .EXAMPLE
        Copy-GitHubGist -Gist 6cad326836d38bd3a7ae

        Forks octocat's "hello_world.rb" gist.

    .EXAMPLE
        $result = Fork-GitHubGist -Gist 6cad326836d38bd3a7ae -PassThru

        Forks octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Copy-GitHubGist or Fork-GitHubGist.
        Specifying the -PassThru switch enables you to get a reference to the newly created fork.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    [Alias('Fork-GitHubGist')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Forking gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/forks"
        'Method' = 'Post'
        'Description' =  "Forking gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    $result = (Invoke-GHRestMethod @params |
        Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistSummaryTypeName)

    if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
    {
        return $result
    }
}

filter Set-GitHubGistStar
{
<#
    .SYNOPSIS
        Changes the starred state of a gist on GitHub for the current authenticated user.

    .DESCRIPTION
        Changes the starred state of a gist on GitHub for the current authenticated user.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific Gist that you wish to change the starred state for.

    .PARAMETER Star
        Include this switch to star the gist.  Exclude the switch (or use -Star:$false) to
        remove the star.

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
        Set-GitHubGistStar -Gist 6cad326836d38bd3a7ae -Star

        Stars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Set-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Get-GitHubGist -Gist 6cad326836d38bd3a7ae | Set-GitHubGistStar -Star:$false

        Unstars octocat's "hello_world.rb" gist.

#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [switch] $Star,

        [string] $AccessToken
    )

    Write-InvocationLog
    Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

    $PSBoundParameters.Remove('Star')
    if ($Star)
    {
        return Add-GitHubGistStar @PSBoundParameters
    }
    else
    {
        return Remove-GitHubGistStar @PSBoundParameters
    }
}

filter Add-GitHubGistStar
{
<#
    .SYNOPSIS
        Star a gist from GitHub.

    .DESCRIPTION
        Star a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific Gist that you wish to star.

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
        Add-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Stars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Star-GitHubGist -Gist 6cad326836d38bd3a7ae

        Stars octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Add-GitHubGistStar or Star-GitHubGist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [Alias('Star-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Starring gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Put'
        'Description' =  "Starring gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Remove-GitHubGistStar
{
<#
    .SYNOPSIS
        Unstar a gist from GitHub.

    .DESCRIPTION
        Unstar a gist from GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to unstar.

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
        Remove-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.

    .EXAMPLE
        Unstar-GitHubGist -Gist 6cad326836d38bd3a7ae

        Unstars octocat's "hello_world.rb" gist.  This is using the alias for the command.
        The result is the same whether you use Remove-GitHubGistStar or Unstar-GitHubGist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [Alias('Unstar-GitHubGist')]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    if (-not $PSCmdlet.ShouldProcess($Gist, "Unstarring gist"))
    {
        return
    }

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Delete'
        'Description' =  "Unstarring gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    return Invoke-GHRestMethod @params
}

filter Test-GitHubGistStar
{
<#
    .SYNOPSIS
        Checks if a gist from GitHub is starred.

    .DESCRIPTION
        Checks if a gist from GitHub is starred.
        Will return $false if it isn't starred, as well as if it couldn't be checked
        (due to permissions or non-existence).

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID of the specific gist that you wish to check.

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
        Boolean indicating if the gist was both found and determined to be starred.

    .EXAMPLE
        Test-GitHubGistStar -Gist 6cad326836d38bd3a7ae

        Returns $true if the gist is starred, or $false if isn't starred or couldn't be checked
        (due to permissions or non-existence).
#>
    [CmdletBinding(PositionalBinding = $false)]
    [OutputType([bool])]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}
    $params = @{
        'UriFragment' = "gists/$Gist/star"
        'Method' = 'Get'
        'Description' =  "Checking if gist $Gist is starred"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
        'ExtendedResult' = $true
    }

    try
    {
        $response = Invoke-GHRestMethod @params
        return $response.StatusCode -eq 204
    }
    catch
    {
        return $false
    }
}

filter New-GitHubGist
{
<#
    .SYNOPSIS
        Creates a new gist on GitHub.

    .DESCRIPTION
        Creates a new gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER File
        An array of filepaths that should be part of this gist.
        Use this when you have multiple files that should be part of a gist, or when you simply
        want to reference an existing file on disk.

    .PARAMETER FileName
        The name of the file that Content should be stored in within the newly created gist.

    .PARAMETER Content
        The content of a single file that should be part of the gist.

    .PARAMETER Description
        A descriptive name for this gist.

    .PARAMETER Public
        When specified, the gist will be public and available for anyone to see.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api.  Otherwise, will attempt to use the configured value or will run unauthenticated.

    .INPUTS
        String - Filename(s) of file(s) that should be the content of the gist.

    .OUTPUTS
        GitHub.GitDetail

    .EXAMPLE
        New-GitHubGist -FileName 'sample.txt' -Content 'Body of my file.' -Description 'This is my gist!' -Public

        Creates a new public gist with a single file named 'sample.txt' that has the body of "Body of my file."

    .EXAMPLE
        New-GitHubGist -File 'c:\files\foo.txt' -Description 'This is my gist!'

        Creates a new private gist with a single file named 'foo.txt'.  Will populate it with the
        content of the file at c:\files\foo.txt.

    .EXAMPLE
        New-GitHubGist -File ('c:\files\foo.txt', 'c:\other\bar.txt', 'c:\octocat.ps1') -Description 'This is my gist!'

        Creates a new private gist with a three files named 'foo.txt', 'bar.txt' and 'octocat.ps1'.
        Each will be populated with the content from the file on disk at the specified location.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='FileRef',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ParameterSetName='FileRef',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string[]] $File,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $Content,

        [string] $Description,

        [switch] $Public,

        [string] $AccessToken
    )

    begin
    {
        $files = @{}
    }

    process
    {
        foreach ($path in $File)
        {
            $path = Resolve-UnverifiedPath -Path $path
            if (-not (Test-Path -Path $path -PathType Leaf))
            {
                $message = "Specified file [$path] could not be found or was inaccessible."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $content = [System.IO.File]::ReadAllText($path)
            $fileName = (Get-Item -Path $path).Name

            if ($files.ContainsKey($fileName))
            {
                $message = "You have specified more than one file with the same name [$fileName].  gists don't have a concept of directory structures, so please ensure each file has a unique name."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $files[$fileName] = @{ 'content' = $Content }
        }
    }

    end
    {
        Write-InvocationLog

        $telemetryProperties = @{}

        if ($PSCmdlet.ParameterSetName -eq 'Content')
        {
            $files[$FileName] = @{ 'content' = $Content }
        }

        if (($files.Keys.StartsWith('gistfile') | Where-Object { $_ -eq $true }).Count -gt 0)
        {
            $message = "Don't name your files starting with 'gistfile'. This is the format of the automatic naming scheme that Gist uses internally."
            Write-Log -Message $message -Level Error
            throw $message
        }

        $hashBody = @{
            'description' = $Description
            'public' = $Public.ToBool()
            'files' = $files
        }

        if (-not $PSCmdlet.ShouldProcess('Create new gist'))
        {
            return
        }

        $params = @{
            'UriFragment' = "gists"
            'Body' = (ConvertTo-Json -InputObject $hashBody)
            'Method' = 'Post'
            'Description' =  "Creating a new gist"
            'AccessToken' = $AccessToken
            'TelemetryEventName' = $MyInvocation.MyCommand.Name
            'TelemetryProperties' = $telemetryProperties
        }

        return (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistTypeName)
    }
}

filter Set-GitHubGist
{
<#
    .SYNOPSIS
        Updates a gist on GitHub.

    .DESCRIPTION
        Updates a gist on GitHub.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER Update
        A hashtable of files to update in the gist.
        The key should be the name of the file in the gist as it exists right now.
        The value should be another hashtable with the following optional key/value pairs:
            fileName - Specify a new name here if you want to rename the file.
            filePath - Specify a path to a file on disk if you wish to update the contents of the
                       file in the gist with the contents of the specified file.
                       Should not be specified if you use 'content' (below)
            content  - Directly specify the raw content that the file in the gist should be updated with.
                       Should not be used if you use 'filePath' (above).

    .PARAMETER Delete
        A list of filenames that should be removed from this gist.

    .PARAMETER Description
        New description for this gist.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
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
        GitHub.GistDetail

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Description 'This is my newer description'

        Updates the description for the specified gist.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Delete 'hello_world.rb' -Force

        Deletes the 'hello_world.rb' file from the specified gist without prompting for confirmation.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Delete 'hello_world.rb' -Description 'This is my newer description'

        Deletes the 'hello_world.rb' file from the specified gist and updates the description.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Update @{'hello_world.rb' = @{ 'fileName' = 'hello_universe.rb' }}

        Renames the 'hello_world.rb' file in the specified gist to be 'hello_universe.rb'.

    .EXAMPLE
        Set-GitHubGist -Gist 6cad326836d38bd3a7ae -Update @{'hello_world.rb' = @{ 'fileName' = 'hello_universe.rb' }}

        Renames the 'hello_world.rb' file in the specified gist to be 'hello_universe.rb'.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Content',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="PassThru is accessed indirectly via Resolve-ParameterWithDefaultConfigurationValue")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipelineByPropertyName,
            Position = 1)]
        [Alias('GistId')]
        [ValidateNotNullOrEmpty()]
        [string] $Gist,

        [hashtable] $Update,

        [string[]] $Delete,

        [string] $Description,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog

    $telemetryProperties = @{}

    $files = @{}

    $shouldProcessMessage = 'Update gist'

    # Mark the files that should be deleted.
    if ($Delete.Count -gt 0)
    {
        $ConfirmPreference = 'Low'
        $shouldProcessMessage = 'Update gist (and remove files)'

        foreach ($toDelete in $Delete)
        {
            $files[$toDelete] = $null
        }
    }

    # Then figure out which ones need content updates and/or file renames
    if ($null -ne $Update)
    {
        foreach ($toUpdate in $Update.GetEnumerator())
        {
            $currentFileName = $toUpdate.Key

            $providedContent = $toUpdate.Value.Content
            $providedFileName = $toUpdate.Value.FileName
            $providedFilePath = $toUpdate.Value.FilePath

            if (-not [String]::IsNullOrWhiteSpace($providedContent))
            {
                $files[$currentFileName] = @{ 'content' = $providedContent }
            }

            if (-not [String]::IsNullOrWhiteSpace($providedFilePath))
            {
                if (-not [String]::IsNullOrWhiteSpace($providedContent))
                {
                    $message = "When updating a file [$currentFileName], you cannot provide both a path to a file [$providedFilePath] and the raw content."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $providedFilePath = Resolve-Path -Path $providedFilePath
                if (-not (Test-Path -Path $providedFilePath -PathType Leaf))
                {
                    $message = "Specified file [$providedFilePath] could not be found or was inaccessible."
                    Write-Log -Message $message -Level Error
                    throw $message
                }

                $newContent = [System.IO.File]::ReadAllText($providedFilePath)
                $files[$currentFileName] = @{ 'content' = $newContent }
            }

            # The user has chosen to rename the file.
            if (-not [String]::IsNullOrWhiteSpace($providedFileName))
            {
                $files[$currentFileName] = @{ 'filename' = $providedFileName }
            }
        }
    }

    $hashBody = @{}
    if (-not [String]::IsNullOrWhiteSpace($Description)) { $hashBody['description'] = $Description }
    if ($files.Keys.count -gt 0) { $hashBody['files'] = $files }

    if ($Force -and (-not $Confirm))
    {
        $ConfirmPreference = 'None'
    }

    if (-not $PSCmdlet.ShouldProcess($Gist, $shouldProcessMessage))
    {
        return
    }

    $ConfirmPreference = 'None'
    $params = @{
        'UriFragment' = "gists/$Gist"
        'Body' = (ConvertTo-Json -InputObject $hashBody)
        'Method' = 'Patch'
        'Description' =  "Updating gist $Gist"
        'AccessToken' = $AccessToken
        'TelemetryEventName' = $MyInvocation.MyCommand.Name
        'TelemetryProperties' = $telemetryProperties
    }

    try
    {
        $result = (Invoke-GHRestMethod @params |
            Add-GitHubGistAdditionalProperties -TypeName $script:GitHubGistTypeName)

        if (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        {
            return $result
        }
    }
    catch
    {
        if ($_.Exception.Message -like '*(422)*')
        {
            $message = 'This error can happen if you try to delete a file that doesn''t exist.  Be aware that casing matters.  ''A.txt'' is not the same as ''a.txt''.'
            Write-Log -Message $message -Level Warning
        }

        throw
    }
}

function Set-GitHubGistFile
{
<#
    .SYNOPSIS
        Updates content of file(s) in an existing gist on GitHub,
        or adds them if they aren't already part of the gist.

    .DESCRIPTION
        Updates content of file(s) in an existing gist on GitHub,
        or adds them if they aren't already part of the gist.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER File
        An array of filepaths that should be part of this gist.
        Use this when you have multiple files that should be part of a gist, or when you simply
        want to reference an existing file on disk.

    .PARAMETER FileName
        The name of the file that Content should be stored in within the newly created gist.

    .PARAMETER Content
        The content of a single file that should be part of the gist.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
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
        GitHub.Gist

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -Content 'Body of my file.' -FileName 'sample.txt'

        Adds a file named 'sample.txt' that has the body of "Body of my file." to the existing
        specified gist, or updates the contents of 'sample.txt' in the gist if is already there.

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -File 'c:\files\foo.txt'

        Adds the file 'foo.txt' to the existing specified gist, or updates its content if it
        is already there.

    .EXAMPLE
        Set-GitHubGistFile -Gist 1234567 -File ('c:\files\foo.txt', 'c:\other\bar.txt', 'c:\octocat.ps1')

        Adds all three files to the existing specified gist, or updates the contents of the files
        in the gist if they are already there.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParameterSetName='Content',
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Alias('Add-GitHubGistFile')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
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
            ValueFromPipeline,
            ParameterSetName='FileRef',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]] $File,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            ParameterSetName='Content',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $Content,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $files = @{}
    }

    process
    {
        foreach ($path in $File)
        {
            $path = Resolve-UnverifiedPath -Path $path
            if (-not (Test-Path -Path $path -PathType Leaf))
            {
                $message = "Specified file [$path] could not be found or was inaccessible."
                Write-Log -Message $message -Level Error
                throw $message
            }

            $fileName = (Get-Item -Path $path).Name
            $files[$fileName] = @{ 'filePath' = $path }
        }
    }

    end
    {
        Write-InvocationLog
        Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

        if ($PSCmdlet.ParameterSetName -eq 'Content')
        {
            $files[$FileName] = @{ 'content' = $Content }
        }

        $params = @{
            'Gist' = $Gist
            'Update' = $files
            'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            'AccessToken' = $AccessToken
        }

        return (Set-GitHubGist @params)
    }
}

function Remove-GitHubGistFile
{
<#
    .SYNOPSIS
        Removes one or more files from an existing gist on GitHub.

    .DESCRIPTION
        Removes one or more files from an existing gist on GitHub.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER FileName
        An array of filenames (no paths, just names) to remove from the gist.

    .PARAMETER Force
        If this switch is specified, you will not be prompted for confirmation of command execution.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
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
        GitHub.Gist

    .EXAMPLE
        Remove-GitHubGistFile -Gist 1234567 -FileName ('foo.txt')

        Removes the file 'foo.txt' from the specified gist.

    .EXAMPLE
        Remove-GitHubGistFile -Gist 1234567 -FileName ('foo.txt') -Force

        Removes the file 'foo.txt' from the specified gist without prompting for confirmation.

    .EXAMPLE
        @('foo.txt', 'bar.txt') | Remove-GitHubGistFile -Gist 1234567

        Removes the files 'foo.txt' and 'bar.txt' from the specified gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Alias('Delete-GitHubGistFile')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
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
            ValueFromPipeline,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string[]] $FileName,

        [switch] $Force,

        [switch] $PassThru,

        [string] $AccessToken
    )

    begin
    {
        $files = @()
    }

    process
    {
        foreach ($name in $FileName)
        {
            $files += $name
        }
    }

    end
    {
        Write-InvocationLog
        Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

        $params = @{
            'Gist' = $Gist
            'Delete' = $files
            'Force' = $Force
            'Confirm' = ($Confirm -eq $true)
            'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
            'AccessToken' = $AccessToken
        }

        return (Set-GitHubGist @params)
    }
}

filter Rename-GitHubGistFile
{
<#
    .SYNOPSIS
        Renames a file in a gist on GitHub.

    .DESCRIPTION
        Renames a file in a gist on GitHub.

        This is a helper function built on top of Set-GitHubGist.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Gist
        The ID for the gist to update.

    .PARAMETER FileName
        The current file in the gist to be renamed.

    .PARAMETER NewName
        The new name of the file for the gist.

    .PARAMETER PassThru
        Returns the updated gist.  By default, this cmdlet does not generate any output.
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
        GitHub.Gist

    .EXAMPLE
        Rename-GitHubGistFile -Gist 1234567 -FileName 'foo.txt' -NewName 'bar.txt'

        Renames the file 'foo.txt' to 'bar.txt' in the specified gist.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        PositionalBinding = $false)]
    [OutputType({$script:GitHubGistTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="This is a helper method for Set-GitHubGist which will handle ShouldProcess.")]
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
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string] $FileName,

        [Parameter(
            Mandatory,
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string] $NewName,

        [switch] $PassThru,

        [string] $AccessToken
    )

    Write-InvocationLog
    Set-TelemetryEvent -EventName $MyInvocation.MyCommand.Name

    $params = @{
        'Gist' = $Gist
        'Update' = @{$FileName = @{ 'fileName' = $NewName }}
        'PassThru' = (Resolve-ParameterWithDefaultConfigurationValue -Name PassThru -ConfigValueName DefaultPassThru)
        'AccessToken' = $AccessToken
    }

    return (Set-GitHubGist @params)
}

filter Add-GitHubGistAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.Gist
        GitHub.GistCommit
        GitHub.GistFork
        GitHub.GistSummary
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistTypeName})]
    [OutputType({$script:GitHubGistFormTypeName})]
    [OutputType({$script:GitHubGistSummaryTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistSummaryTypeName
    )

    if ($TypeName -eq $script:GitHubGistCommitTypeName)
    {
        return Add-GitHubGistCommitAdditionalProperties -InputObject $InputObject
    }
    elseif ($TypeName -eq $script:GitHubGistForkTypeName)
    {
        return Add-GitHubGistForkAdditionalProperties -InputObject $InputObject
    }

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'GistId' -Value $item.id -MemberType NoteProperty -Force

            @('user', 'owner') |
                ForEach-Object {
                    if ($null -ne $item.$_)
                    {
                        $null = Add-GitHubUserAdditionalProperties -InputObject $item.$_
                    }
                }

            if ($null -ne $item.forks)
            {
                $item.forks = Add-GitHubGistForkAdditionalProperties -InputObject $item.forks
            }

            if ($null -ne $item.history)
            {
                $item.history = Add-GitHubGistCommitAdditionalProperties -InputObject $item.history
            }
        }

        Write-Output $item
    }
}

filter Add-GitHubGistCommitAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub GistCommit objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistCommit
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistCommitTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistCommitTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            $hostName = $(Get-GitHubConfiguration -Name 'ApiHostName')
            if ($item.url -match "^https?://(?:www\.|api\.|)$hostName/gists/([^/]+)/(.+)$")
            {
                $id = $Matches[1]
                $sha = $Matches[2]

                if ($sha -ne $item.version)
                {
                    $message = "The gist commit url no longer follows the expected pattern.  Please contact the PowerShellForGitHubTeam: $item.uri"
                    Write-Log -Message $message -Level Warning
                }
            }

            Add-Member -InputObject $item -Name 'GistId' -Value $id -MemberType NoteProperty -Force
            Add-Member -InputObject $item -Name 'Sha' -Value $item.version -MemberType NoteProperty -Force

            $null = Add-GitHubUserAdditionalProperties -InputObject $item.user
        }

        Write-Output $item
    }
}

filter Add-GitHubGistForkAdditionalProperties
{
<#
    .SYNOPSIS
        Adds type name and additional properties to ease pipelining to GitHub Gist Fork objects.

    .PARAMETER InputObject
        The GitHub object to add additional properties to.

    .PARAMETER TypeName
        The type that should be assigned to the object.

    .INPUTS
        [PSCustomObject]

    .OUTPUTS
        GitHub.GistFork
#>
    [CmdletBinding()]
    [OutputType({$script:GitHubGistForkTypeName})]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Internal helper that is definitely adding more than one property.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [PSCustomObject[]] $InputObject,

        [ValidateNotNullOrEmpty()]
        [string] $TypeName = $script:GitHubGistForkTypeName
    )

    foreach ($item in $InputObject)
    {
        $item.PSObject.TypeNames.Insert(0, $TypeName)

        if (-not (Get-GitHubConfiguration -Name DisablePipelineSupport))
        {
            Add-Member -InputObject $item -Name 'GistId' -Value $item.id -MemberType NoteProperty -Force

            # See here for why we need to work with both 'user' _and_ 'owner':
            # https://github.community/t/gist-api-v3-documentation-incorrect-for-forks/122545
            @('user', 'owner') |
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAh4sA9mSDSlaxQ
# 2s4kYld7oPdDLqa5eOOehJlvmRGoE6CCDXYwggX0MIID3KADAgECAhMzAAACURR2
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
# /Xmfwb1tbWrJUnMTDXpQzTGCGYEwghl9AgEBMIGVMH4xCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNp
# Z25pbmcgUENBIDIwMTECEzMAAAJRFHbMxYWDbgsAAAAAAlEwDQYJYIZIAWUDBAIB
# BQCggbAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO51O/HGZbWRPIYFteMmYcOB
# CzJy2QTbnhY7TchlUOckMEQGCisGAQQBgjcCAQwxNjA0oBSAEgBNAGkAYwByAG8A
# cwBvAGYAdKEcgBpodHRwczovL3d3dy5taWNyb3NvZnQuY29tIDANBgkqhkiG9w0B
# AQEFAASCAQANTlWcdQ1rWRtg/8IwsorSIHPBcomMSnd7UelkFk+7shgVBaTGaGDn
# V5aJ/bVJ5y86g95+FyNb/RcDHsvHIPNy5EFNKZEUiVpu2ne6cFeeGkH7lfhQ4yYj
# 0KcX4qO/JEmNiP+XMt1H7zaT8Vbwll+pmygXmEgjouevlm1Il0Z9+bR1mZT6FTr8
# cAnfvNouwwylsmFBDPtwIVcIgkjmWQKhuXeYVER1ZvmBrXSdpLmovW5lQH15ZFuy
# ePZ+A82BRj5GHY9i/wdX4MSfnDbn3/icEaNrpuaQ8UlYaIvMs0ejVsBQq/e4EhXZ
# 4E5fI+eugqwyipC9aHnC8xUOe/o9wMyXoYIXCTCCFwUGCisGAQQBgjcDAwExghb1
# MIIW8QYJKoZIhvcNAQcCoIIW4jCCFt4CAQMxDzANBglghkgBZQMEAgEFADCCAVUG
# CyqGSIb3DQEJEAEEoIIBRASCAUAwggE8AgEBBgorBgEEAYRZCgMBMDEwDQYJYIZI
# AWUDBAIBBQAEILObDprUKiTx+ek02jTxLgT/vrDo1Ty+YZG3S5xuj2DvAgZi2vyR
# IgwYEzIwMjIwNzI1MTcyNTI1LjU0NlowBIACAfSggdSkgdEwgc4xCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBP
# cGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpG
# NzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2Vy
# dmljZaCCEVwwggcQMIIE+KADAgECAhMzAAABqqUxmwvLsggOAAEAAAGqMA0GCSqG
# SIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMB4XDTIyMDMw
# MjE4NTEyNloXDTIzMDUxMTE4NTEyNlowgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjpGNzdGLUUzNTYtNUJB
# RTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgU2VydmljZTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAKBP7HK51bWHf+FDSh9O7YyrQtkNMvdH
# zHiazvOdI9POGjyJIYrs1WOMmSCp3o/mvsuPnFSP5c0dCeBuUq6u6J30M81ZaNOP
# /abZrTwYrYN+N5nStrOGdCtRBum76hy7Tr3AZDUArLwvhsGlXhLlDU1wioaxM+BV
# wCNI7LmTaYKqjm58hEgsYtKIHk59LzOnI4aenbPLBP/VYYjI6a4KIcun0EZErAuk
# t5PC/mKUaOphUMGYm0PxfpY9BkG5sPfczFyIfA13LLRS4sGhbUrcM54EvE2FlWBQ
# aJo7frKW7CVjITLEX4E2lxwQG/MuZ+1wDYg9OOErT5h+6zecj67eenwxeUoaOEbK
# tiUxaJUYnyQKxCWTkNdWRXTKSmIxx0tbsP5irWjqXvT6t/zeJKw05NY8hPT56vW2
# 0q0DYK2NteOCDD0UD6ZNAFLV87GOkl0eBqXcToFVdeJwwOTE6aA4RqYoNr2QUPBI
# U6JEiUGBs9c4qC5mBHTY46VaR/odaFDLcxQI4OPkn5al/IPsd8/raDmMfKik66xc
# Nh2qN4yytYM3uiDenX5qeFdx3pdi43pYAFN/S1/3VRNk+/GRVUUYWYBjDZSqxsli
# dE8hsxC7K8qLfmNoaQ2aAsu13h1faTMSZIEVxosz1b9yIeXmtM6NlrjV3etwS7JX
# YwGhHMdVYEL1AgMBAAGjggE2MIIBMjAdBgNVHQ4EFgQUP5oUvFOHLthfd0Wz3hGt
# nQVGpJ4wHwYDVR0jBBgwFoAUn6cVXQBeYl2D9OXSZacbUzUZ6XIwXwYDVR0fBFgw
# VjBUoFKgUIZOaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWlj
# cm9zb2Z0JTIwVGltZS1TdGFtcCUyMFBDQSUyMDIwMTAoMSkuY3JsMGwGCCsGAQUF
# BwEBBGAwXjBcBggrBgEFBQcwAoZQaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3Br
# aW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgx
# KS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDCDANBgkqhkiG
# 9w0BAQsFAAOCAgEA3wyATZBFEBogrcwHs4zI7qX2y0jbKCI6ZieGAIR96RiMrjZv
# WG39YPA/FL2vhGSCtO7ea3iBlwhhTyJEPexLugT4jB4W0rldOLP5bEc0zwxs9NtT
# FS8Ul2zbJ7jz5WxSnhSHsfaVFUp7S6B2a1bjKmWIo/Svd3W1V3mcIYzhbpLIUVlP
# 3CbTJEE+cC3hX+JggnSYRETyo+mI7Hz/KMWFaRWBUYI4g0BrwiV2lYqKyekjNp6r
# j7b8l6OhbgX/JP0bzNxv6io0Y4iNlIzz/PdIh/E2pj3pXPiQJPRlEkMksRecE8Vn
# FyqhR4fb/F6c5ywY4+mEpshIAg2YUXswFqqbK9Fv+U8YYclYPvhK/wRZs+/5auK4
# FM+QTjywj0C5rmr8MziqmUGgAuwZQYyHRCopnVdlaO/xxSZCfaZR7w7B3OBEl8j+
# Voofs1Kfq9AmmQAWZOjt4DnNk5NnxThPvjQVuOU/y+HTErwqD/wKRCl0AJ3UPTJ8
# PPYp+jbEXkKmoFhU4JGer5eaj22nX19pujNZKqqart4yLjNUOkqWjVk4KHpdYRGc
# JMVXkKkQAiljUn9cHRwNuPz/Tu7YmfgRXWN4HvCcT2m1QADinOZPsO5v5j/bExw0
# WmFrW2CtDEApnClmiAKchFr0xSKE5ET+AyubLapejENr9vt7QXNq6aP1XWcwggdx
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
# Ooo6CGJ/2XBjU02N7oJtpQUQwXEGahC0HVUzWLOhcGbyoYICzzCCAjgCAQEwgfyh
# gdSkgdEwgc4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYD
# VQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKTAn
# BgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMSYwJAYDVQQL
# Ex1UaGFsZXMgVFNTIEVTTjpGNzdGLUUzNTYtNUJBRTElMCMGA1UEAxMcTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgU2VydmljZaIjCgEBMAcGBSsOAwIaAxUA4G0m0J4eAllj
# cP/jvOv9/pm/68aggYMwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2Fz
# aGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENv
# cnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAx
# MDANBgkqhkiG9w0BAQUFAAIFAOaIxsowIhgPMjAyMjA3MjUxMTM3NDZaGA8yMDIy
# MDcyNjExMzc0NlowdDA6BgorBgEEAYRZCgQBMSwwKjAKAgUA5ojGygIBADAHAgEA
# AgIb+DAHAgEAAgIRRTAKAgUA5ooYSgIBADA2BgorBgEEAYRZCgQCMSgwJjAMBgor
# BgEEAYRZCgMCoAowCAIBAAIDB6EgoQowCAIBAAIDAYagMA0GCSqGSIb3DQEBBQUA
# A4GBAKDThbkonImTmhJPPjFka1CX5IcwDfzxrEiUahZPGVNBjaWkdQtrjIPhqd36
# I2BHpMHtvjJxNKPHkk8+XXbpfd3lJ5DfuC2Cgm5Af4r2h92wEpycf0YQgv1KjGl/
# X9nt9BFoLY10SpsrBncFPS6RnzB0T3r/xmCmcxtrnR2lbwNvMYIEDTCCBAkCAQEw
# gZMwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGqpTGbC8uyCA4A
# AQAAAaowDQYJYIZIAWUDBAIBBQCgggFKMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0B
# CRABBDAvBgkqhkiG9w0BCQQxIgQggM4hfD/WpfTq+K1y86+GPYKR7LdX4/q6iH17
# FS81tmkwgfoGCyqGSIb3DQEJEAIvMYHqMIHnMIHkMIG9BCBWtQJDHFq8EeBz3TXu
# gCqRhSI/JCZbATYEIwTG8bMewDCBmDCBgKR+MHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABqqUxmwvLsggOAAEAAAGqMCIEIAgnyiOb4VneQunDDkWk
# NMblh3kwkMIxWKGNpL571AO2MA0GCSqGSIb3DQEBCwUABIICACVMJzXXjGEAv0vR
# Yl4BsPCgKStPeYT0Wg8eKXBooveippjdGrsUzpx/ZEcqtaevjH6KkHsC8zBssCQF
# tyRTZiXHlxDgg+MNos6viTzI8cHzjmeZWZVz2xMxe0zoj8YS52ZSWKNFyKwekdDy
# YGR0JzsI5NBn/t9j8swHeF/fGawaDCHXd3Xz8GchkKNVWMdiiMjQqLaz72zrvz3K
# JFh/IEdEdzeS/PUiQgg2mZJ94fwiy4NjMeI4h0Rr6OLcSwWs0ibiBUEma1P9O6Pp
# tVT8ki9rkVRGbjytNdt2zsZAJQd9XOZRP5/SYN3TgFX4sYZO5W+LcA8xpikktPw8
# eCZmBJ+Ydi/i2znFV9e1ECG3FfmUyGdrxKysE8p8DY6dk/sQC0iAbpdWF246i1Oj
# JsNJzmmU3MOY++GPHkbe+zR5drWJq09bh+n+jHbvTQ4gJgSliMc2hgZ37O7NDH7y
# lNFwI5uBPSN59QGxvs55mW25ONSjxU3FukfvVY57BW0rfehrsDBxy3m3HhWBiwQ6
# 9uCHsKFrVkgz3QOIgOidytgFKRniFD0ByDY/qxjTtzG0rsnyrYkCw1JP6TFYKHAo
# E9baeBOjMId8uG84X3uNPia/tVz3NZZQc8l0X0XAah+zfbDTC9yCODa190d/YMdL
# jDKnEZhl7x4WhJ5SmE2c1IGJLV+d
# SIG # End signature block

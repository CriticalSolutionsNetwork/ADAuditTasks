#Region './Public/Get-GHOwnerRepoFromRemoteUrl.ps1' 0
<#
    .SYNOPSIS
        Extract GitHub Owner and Repository Name from Uri (ssh or https).

    .DESCRIPTION
        This function will look into a remote Url (https:// or ssh://) and will extract the GitHub owner
        and the repository name.

        from https://github.com/PowerShell/vscode-powershell/blob/master/tools/GitHubTools.psm1
        Copyright (c) Microsoft Corporation. All rights reserved.
        Licensed under the MIT License.

    .PARAMETER RemoteUrl
        Remote URL of the repository, you can get it in a cloned repository by doing: `git remote get-url origin`

    .EXAMPLE
        Get-GHOwnerRepoFromRemoteUrl -RemoteUrl git@github.com:gaelcolas/Sampler.GitHubTasks.git

#>
function Get-GHOwnerRepoFromRemoteUrl
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param
    (
        [Parameter()]
        [System.String]
        $RemoteUrl
    )

    if ($RemoteUrl.EndsWith('.git'))
    {
        $RemoteUrl = $RemoteUrl.Substring(0, $RemoteUrl.Length - 4)
    }
    else
    {
        $RemoteUrl = $RemoteUrl.Trim('/')
    }

    $lastSlashIdx = $RemoteUrl.LastIndexOf('/')
    $repository = $RemoteUrl.Substring($lastSlashIdx + 1)
    $secondLastSlashIdx = $RemoteUrl.LastIndexOfAny(('/', ':'), $lastSlashIdx - 1)
    $Owner = $RemoteUrl.Substring($secondLastSlashIdx + 1, $lastSlashIdx - $secondLastSlashIdx - 1)

    return @{
        Owner      = $Owner
        Repository = $repository
    }
}
#EndRegion './Public/Get-GHOwnerRepoFromRemoteUrl.ps1' 50
#Region './suffix.ps1' 0
# Inspired from https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tasks\*') -Include '*.build.*' |
    ForEach-Object -Process {
        $ModuleName = ([System.IO.FileInfo] $MyInvocation.MyCommand.Name).BaseName
        $taskFileAliasName = "$($_.BaseName).$ModuleName.ib.tasks"
        Set-Alias -Name $taskFileAliasName -Value $_.FullName

        Export-ModuleMember -Alias $taskFileAliasName
    }
#EndRegion './suffix.ps1' 10

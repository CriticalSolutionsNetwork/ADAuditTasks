# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

function Group-GitHubIssue
{
<#
    .SYNOPSIS
        Groups the provided issues based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided issues based on the specified grouping criteria.

        Currently able to group Issues by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Issue
        The Issue(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Issues by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the issue
        if part of.

    .INPUTS
        GitHub.Issue

    .OUTPUTS
        [PSCustomObject[]]
        Collection of issues and counts, by week, along with the total count of issues.

    .EXAMPLE
        $issues = @()
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $issues += Get-GitHubIssue -Uri 'https://github.com/powershell/xactivedirectory'
        $issues | Group-GitHubIssue -Weeks 12 -DateType Closed
#>
    [CmdletBinding(DefaultParameterSetName = 'Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="DateType due to PowerShell/PSScriptAnalyzer#1472")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $Issue,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Closed')]
        [string] $DateType = 'Created'
    )

    begin
    {
        Write-InvocationLog

        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $weekDates = Get-WeekDate -Weeks $Weeks

            $result = [ordered]@{}
            foreach ($week in $weekDates)
            {
                $result[$week] = ([PSCustomObject]([ordered]@{
                    'WeekStart' = $week
                    'Count' = 0
                    'Issues' = @()
                }))
            }

            $result['total'] = ([PSCustomObject]([ordered]@{
                'WeekStart' = 'total'
                'Count' = 0
                'Issues' = @()
            }))
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $endOfWeek = Get-Date
            foreach ($week in $weekDates)
            {
                $filteredIssues = @($Issue | Where-Object {
                    (($DateType -eq 'Created') -and
                     ($_.created_at -ge $week) -and
                     ($_.created_at -le $endOfWeek)) -or
                    (($DateType -eq 'Closed') -and
                     ($_.closed_at -ge $week) -and
                     ($_.closed_at -le $endOfWeek))
                })

                $endOfWeek = $week

                $result[$week].Issues += $filteredIssues
                $result[$week].Count += ($filteredIssues.Count)

                $result['total'].Issues += $filteredIssues
                $result['total'].Count += ($filteredIssues.Count)
            }
        }
        else
        {
            Write-Output -InputObject $Issue
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            foreach ($entry in $result.Values.GetEnumerator())
            {
                Write-Output -InputObject $entry
            }
        }
    }
}

function Group-GitHubPullRequest
{
<#
    .SYNOPSIS
        Groups the provided pull requests based on the specified grouping criteria.

    .DESCRIPTION
        Groups the provided pull requests based on the specified grouping criteria.

        Currently able to group Pull Requests by week.

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER PullRequest
        The Pull Requests(s) to be grouped.

    .PARAMETER Weeks
        The number of weeks to group the Pull Requests by.

    .PARAMETER DateType
        The date property that should be inspected when determining which week grouping the
        pull request if part of.

    .INPUTS
        GitHub.PullRequest

    .OUTPUTS
        [PSCustomObject[]] Collection of pull requests and counts, by week, along with the
        total count of pull requests.

    .EXAMPLE
        $pullRequests = @()
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xpsdesiredstateconfiguration'
        $pullRequests += Get-GitHubPullRequest -Uri 'https://github.com/powershell/xactivedirectory'
        $pullRequests | Group-GitHubPullRequest -Weeks 12 -DateType Closed
#>
    [CmdletBinding(DefaultParameterSetName='Weekly')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification="DateType due to PowerShell/PSScriptAnalyzer#1472")]
    param
    (
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject[]] $PullRequest,

        [Parameter(
            Mandatory,
            ParameterSetName='Weekly')]
        [ValidateRange(0, 10000)]
        [int] $Weeks,

        [Parameter(ParameterSetName='Weekly')]
        [ValidateSet('Created', 'Merged')]
        [string] $DateType = 'Created'
    )

    begin
    {
        Write-InvocationLog

        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $weekDates = Get-WeekDate -Weeks $Weeks

            $result = [ordered]@{}
            foreach ($week in $weekDates)
            {
                $result[$week] = ([PSCustomObject]([ordered]@{
                    'WeekStart' = $week
                    'Count' = 0
                    'PullRequests' = @()
                }))
            }

            $result['total'] = ([PSCustomObject]([ordered]@{
                'WeekStart' = 'total'
                'Count' = 0
                'PullRequests' = @()
            }))
        }
    }

    process
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            $endOfWeek = Get-Date
            foreach ($week in $weekDates)
            {
                $filteredPullRequests = @($PullRequest | Where-Object {
                    (($DateType -eq 'Created') -and
                     ($_.created_at -ge $week) -and
                     ($_.created_at -le $endOfWeek)) -or
                    (($DateType -eq 'Merged') -and
                     ($_.merged_at -ge $week) -and
                     ($_.merged_at -le $endOfWeek))
                })

                $endOfWeek = $week

                $result[$week].PullRequests += $filteredPullRequests
                $result[$week].Count += ($filteredPullRequests.Count)

                $result['total'].PullRequests += $filteredPullRequests
                $result['total'].Count += ($filteredPullRequests.Count)
            }
        }
        else
        {
            Write-Output -InputObject $PullRequest
        }
    }

    end
    {
        if ($PSCmdlet.ParameterSetName -eq 'Weekly')
        {
            foreach ($entry in $result.Values.GetEnumerator())
            {
                Write-Output -InputObject $entry
            }
        }
    }
}

function Get-WeekDate
{
<#
    .SYNOPSIS
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

    .DESCRIPTION
        Retrieves an array of dates with starts of $Weeks previous weeks.
        Dates are sorted in reverse chronological order

        The Git repo for this module can be found here: http://aka.ms/PowerShellForGitHub

    .PARAMETER Weeks
        The number of weeks prior to today that should be included in the final result.

    .OUTPUTS
        [DateTime[]] List of DateTimes representing the first day of each requested week.

    .EXAMPLE
        Get-WeekDate -Weeks 10
#>
    [CmdletBinding()]
    [OutputType([DateTime[]])]
    param(
        [ValidateRange(0, 10000)]
        [int] $Weeks = 12
    )

    $dates = @()

    $midnightToday = Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0
    $startOfWeek = $midnightToday.AddDays(- ($midnightToday.DayOfWeek.value__ - 1))

    $i = 0
    while ($i -lt $Weeks)
    {
        $dates += $startOfWeek
        $startOfWeek = $startOfWeek.AddDays(-7)
        $i++
    }

    return $dates
}

# SIG # Begin signature block
# MIInrAYJKoZIhvcNAQcCoIInnTCCJ5kCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBsqaUSZNZy0oqs
# YxQV8iSxHQ0y4VdmtTXJd2iUnpj+kKCCDYEwggX/MIID56ADAgECAhMzAAACUosz
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
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQg0n0cEb8c
# IMHGlwEj5CNwMJ2mgsx1Fl3b3CRvFxrSfbswRAYKKwYBBAGCNwIBDDE2MDSgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRyAGmh0dHBzOi8vd3d3Lm1pY3Jvc29mdC5jb20g
# MA0GCSqGSIb3DQEBAQUABIIBAIaG7jxaIyu/aluavUibrzA9pQBqQNZ/spYFlovw
# ESQAbH9AQOMo+65uBKOu8bIEXLlEXL+0o70q/ZDVelsE05Fl3ypftwVoINACzJIb
# S/erFqV3dY7ceh+Kl0qG25Spz6YUEzmqv7S5OEsRx/Yf0SM9THFgNKf+JaaUkCkM
# 7tNx6wDOenTc7zgK45VT+RZ2qj6YsC9LRQEp2JIaDAG6cSW0STuFZ9hTEqbsxI10
# Wf3ND5LvUbBR+fLJLrs6olAChUxNeXOAo2MZvgQh5jcT8ramLUjDaD/gp2uARqLt
# 66vZmKK02T9eT4bwJEqax9L510JJKBYmmaUDSHyWBd4teW+hghcJMIIXBQYKKwYB
# BAGCNwMDATGCFvUwghbxBgkqhkiG9w0BBwKgghbiMIIW3gIBAzEPMA0GCWCGSAFl
# AwQCAQUAMIIBVQYLKoZIhvcNAQkQAQSgggFEBIIBQDCCATwCAQEGCisGAQQBhFkK
# AwEwMTANBglghkgBZQMEAgEFAAQgXvsoB+/f4s+sfQ7yu0zP3JFGB9+sOU0fnp9G
# SrbZPFUCBmLbKvbLchgTMjAyMjA3MjUxNzI1MDQuMjEyWjAEgAIB9KCB1KSB0TCB
# zjELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1Jl
# ZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMg
# TWljcm9zb2Z0IE9wZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOkY4N0EtRTM3NC1EN0I5MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBTZXJ2aWNloIIRXDCCBxAwggT4oAMCAQICEzMAAAGuqgtcszSllRoA
# AQAAAa4wDQYJKoZIhvcNAQELBQAwfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwHhcNMjIwMzAyMTg1MTM3WhcNMjMwNTExMTg1MTM3WjCBzjELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEpMCcGA1UECxMgTWljcm9zb2Z0IE9w
# ZXJhdGlvbnMgUHVlcnRvIFJpY28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkY4
# N0EtRTM3NC1EN0I5MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2
# aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAk4wa8SE1DAsdpy3O
# c+ljwmDmojxCyCnSaGXYbbO1U+ieriCw4x7m72nl/Xs8gzUpeNRoo2Xd2Odyrb0u
# Kqaqdoo5GCA8c0STtD61qXkjJz5LyT9HfWAIa3iq9BWoEtA2K/E66RR9qkbjUtN0
# sd4zi7AieT5CsZAfYrjCM22JSmKsXY90JxuRfIAsSnJPZGvDMmbNyZt0KxxjQ3dE
# fGsx5ZDeTuw23jU0Fk5P7ikKaTDxSSAqJIlczMqzfwzFSrH86VLzR0sNMd35l6LV
# LX+psK1MbM2bRuPqp+SVQzckUAXUktfDC+qBlF0NBTrbbjC0afBqVNo4jRHR5f5y
# tw+lcYHbsQiBhT7SWjZofv1I2uw9YRx0EgJ3TJ+EVTaeJUl6kbORd60m9sXFbeI3
# uxyMt/D9LpRcXvC0TN041dWIjk/ZQzvv0/oQhn6DzUTYxZfxeMtXK8iy/PJyQngU
# WL6HXI8T6/NyQ/HMc6yItpp+5yzIyMBoAzxbBr7TYG6MQ7KV8tLKTSK/0i9Ij1mQ
# lb+Au9DjZTT5TTflmFSEKpsoRYQwivbJratimtQwQpxd/hH3stU8F+wmduQ1S5ul
# QDgrWLuKNDWmRSW35hD/fia0TLt5KKBWlXOep+s1V6sK8cbkjB94VWE81sDArqUE
# RDb2cxiNFePhAvK+YpGao4kz/DUCAwEAAaOCATYwggEyMB0GA1UdDgQWBBTTMG/f
# vyhgisGprXT+/O1kOmFR7jAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJlpxtTNRnp
# cjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtp
# b3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAxMCgxKS5j
# cmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3RhbXAlMjBQ
# Q0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMIMA0GCSqGSIb3DQEBCwUAA4ICAQBdv5Hw/VUARA48rTMDEAMhc/hwlCZqu2NU
# UswSQtiHf08W1Vu3zhG/RDUZJNiaE/x/846+eYLl6PDc1zVVGLvitYZQhO/Xxaqv
# x4G8BJ3h4MDEVsDySc46b9nJKQwMNh1vrvfxpDTK+p/sBZyGA+e0Jz+eE1qlImaP
# NSR7sS+MHx6LQGdjTGX4BBxLEkb9Weyb0jA56vwTWaJUth8+f18gN1pq/Vur2L6C
# dl/WFLtqkanFuK0ImvUoYPiMjIAGTEeF6g86GG1CbW7OcTtuUrEfylTtbYD56qCC
# w2QzdUHSevNFkGqbhKYFI2E4/PLeh86YtxEr9qWg4Cvqd6GLyLmWGZODUuQ4DEKE
# vAe+W6IJj0r7a8im3jyKgr+H63PlGBV1v5LzHCfvbyU3wo+SQHZFrmKJyu+2ADnn
# BJR2HoUXFfF5L5uyAFrKftnJp9OkMzsFA4FjBqh2y5V/leAavIbHziThHnyY/AHd
# DT0JEAazfk063pOs9epzKU27pnPzFNANxomnnikrI6hbmIgMWOkud5dMSO1YIUKA
# CjjNun0I0hOn3so+dzeBlVoy8SlTxKntVnA31yRHZYMrI6MOCEhx+4UlMs52Q64w
# saxY92djqJ21ZzZtQNBrZBvOY1JnIW2ESmvBDYaaBoZsYq5hVWpSP9i3bUcPQ8F4
# MjkxqXxJzDCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUwDQYJKoZI
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
# Y28xJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkY4N0EtRTM3NC1EN0I5MSUwIwYD
# VQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNloiMKAQEwBwYFKw4DAhoD
# FQC8mrCT/GfJyBXkZ3LlvgjAT9Na46CBgzCBgKR+MHwxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVN
# aWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFBDQSAyMDEwMA0GCSqGSIb3DQEBBQUAAgUA5oj1LzAiGA8yMDIyMDcyNTE0
# NTU0M1oYDzIwMjIwNzI2MTQ1NTQzWjB0MDoGCisGAQQBhFkKBAExLDAqMAoCBQDm
# iPUvAgEAMAcCAQACAgp3MAcCAQACAhEEMAoCBQDmikavAgEAMDYGCisGAQQBhFkK
# BAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAIAgEAAgMBhqAwDQYJ
# KoZIhvcNAQEFBQADgYEAAxQSIxJbvI8n15rHs/68qeIkqdb6EhOwaEeSXoKpiiHQ
# U+YoRs1qJnLTdUPuP9YplC1Vac7SUHoicGQvWyXDj6hmJVpKPSVIdRGgnEeBjf0c
# v8DVWsxnaCQVbpygGRhPvSe2kauWlhqJjohs5vRBSN80LuTsxXvRXmsdR/we15Mx
# ggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAA
# Aa6qC1yzNKWVGgABAAABrjANBglghkgBZQMEAgEFAKCCAUowGgYJKoZIhvcNAQkD
# MQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCAm3j//rKx+L7S8lB1yRMks
# 4miLaecjyvWTCoFr5rZukzCB+gYLKoZIhvcNAQkQAi8xgeowgecwgeQwgb0EIEko
# HT64jMNaoe6fT2apNTy46Dq17DTK7W5DSJT8Um9oMIGYMIGApH4wfDELMAkGA1UE
# BhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0
# IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGuqgtcszSllRoAAQAAAa4wIgQg9yZT
# 1frl4KppPFyHVOi8fy1ANhMtUxNM7gIsEDk/+N0wDQYJKoZIhvcNAQELBQAEggIA
# M6qzKDBVr363deXiPYawMFq9VmzZQlsckHpJUkL4unmnN8qOiMolEtEwcxR9FeEh
# DutPiAXWRJBx5Mli6Mm4Gcn/VuCfB+LAVvbo0UaxdqXR7t+Hrjf+l0IZatpnxzuv
# 3r0HlmlT3hc49j4hOnohtxWNmmReaVML5WdS8Ehx86quYuBwdBVPz67LrJnWtWtr
# nBM5M8tYlm1aoO3lrSYNGTUaGsOfbYGdAdnxaG/3HGrTH7PjnA5QIyGt27Bv26Bi
# KGvpns4VkyEcrbFWFwdmELUZ/RKcxz60mbBS18gqj15RSgwtuhmOrA8l0RLZ1zMC
# Q336cnr82F86TO4soN+8zY9pobD76LpxbTCU9I3r7/Ahv3CZ1RF0BwQQzU8Qgg01
# 9jmfhQUQ8LRoxq8Pl/ixO113kZ5XtcEnG++5PcO2urngx/JCBkkVrl8ZW4bqXfwr
# 1JGkjZiVRd5AF5J+p2yyyiEXcDAp6Op0g3W8Im3mQLTaxrJASSqkpeUXCZD6xVMY
# VgJdPmQqHJpPQcunkOtcy8eWnyxiIQExCPKNRcaY472T4DpEiYpB+DE+CtI+Tf0W
# yS38aMwNbsyRl/70C3aJFw+CIPJwgSHVu8TuPGwFu32VQ6X34ZIbLMNBzbGyBoke
# fVUq7BB367mbUD9I2X2rMSaFnXC6Pml7h8dYOWKwc4M=
# SIG # End signature block

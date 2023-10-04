function Get-QuickPing {
    <#
    .SYNOPSIS
    Performs a quick ping on a range of IP addresses and returns an array of IP addresses
    that responded to the ping and an array of IP addresses that failed to respond.
    .DESCRIPTION
    This function performs a quick ping on a range of IP addresses specified by the IPRange parameter.
    The ping is done with a Time-to-Live (TTL) value of 128 (by default). The function returns an array
    of IP addresses that responded to the ping and an array of IP addresses that failed to respond.
    This function has specific behaviors depending on the PowerShell version. For PowerShell 7 and
    above, it uses the 'Test-Connection' cmdlet's '-OutVariable' parameter.
    .PARAMETER IPRange
    Specifies a range of IP addresses to ping. Can be a string with a single IP address.
    .PARAMETER TTL
    Specifies the Time-to-Live (TTL) value to use for the ping. The default value is 128.
    .PARAMETER BufferSize
    Specifies the size of the buffer to use for the ping. The default value is 16.
    .PARAMETER Count
    Specifies the number of times to send the ping request. The default value is 1.
    .EXAMPLE
    Get-QuickPing -IPRange 192.168.1.1
    Performs a quick ping on the IP address 192.168.1.1 with a TTL of 128 and returns an
    array of IP addresses that responded to the ping and an array of IP addresses that
    failed to respond.
    .EXAMPLE
    Get-QuickPing -IPRange "192.168.1.1", "192.168.1.2", "192.168.1.3"
    Performs a quick ping on the IP addresses 192.168.1.1, 192.168.1.2, and 192.168.1.3 with
    a TTL of 128 and returns an array of IP addresses that responded to the ping and an array
    of IP addresses that failed to respond.
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-QuickPing
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-QuickPing
#>
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
                if ($_ -match "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$") {
                    $true
                }
                else {
                    throw "Invalid IP address format"
                }
            })]
        [Array]$IPRange,

        [ValidateRange(1, 255)]
        [int]$TTL = 128,

        [ValidateRange(16, 65500)]
        [int32]$BufferSize = 16,

        [ValidateRange(1, [int]::MaxValue)]
        [int32]$Count = 1
    )

    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }

        $FailedToPing = @()
        $Success = @()
        $TotalIPs = $IPRange.Count
        $ProcessedIPs = 0
    }
    process {
        foreach ($IP in $IPRange) {
            $ProcessedIPs++
            $ProgressPercentage = ($ProcessedIPs / $TotalIPs) * 100
            Write-Progress -Activity "Scanning IP addresses" -Status "Scanning $IP ($ProcessedIPs of $TotalIPs)" -PercentComplete $ProgressPercentage
            try {
                if ($PSVersionTable.PSVersion.Major -ge 7) {
                    [void](Test-Connection $IP -BufferSize $BufferSize -TimeToLive $TTL -Count $Count -ErrorAction Stop -OutVariable test)
                    if ($test.Status -eq 'Success') {
                        Write-AuditLog "$IP Found!" -Severity Information
                        $Success += $IP
                    }
                    else {
                        $FailedToPing += $IP
                    }
                }
                else {
                    try {
                        [void](Test-Connection $IP -BufferSize $BufferSize -TimeToLive $TTL -Count $Count -ErrorAction Stop)
                        Write-AuditLog "$IP Found!"
                        $Success += $IP
                    }
                    catch {
                        $FailedToPing += $IP
                    }
                }
            }
            catch { throw $_.Exception }
        }
        if ($FailedToPing.Count -eq 0) {
            $FailedToPing = "NoIPs"
        }
        if ($Success.Count -eq 0) {
            $FailedToPing = "NoIPs"
        }
    }
    end {
        Write-AuditLog -EndFunction
        return $Success, $FailedToPing
    }
}

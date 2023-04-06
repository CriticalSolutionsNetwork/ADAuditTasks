function Get-QuickPing {
    <#
    .SYNOPSIS
    Performs a quick ping on a range of IP addresses and returns an array of IP addresses
    that responded to the ping and an array of IP addresses that failed to respond.

    .DESCRIPTION
    This function performs a quick ping on a range of IP addresses specified by the IPRange parameter.
    The ping is done with a Time-to-Live (TTL) value of 128 (by default), meaning only the local network
    will be pinged. The function returns an array of IP addresses that responded to the ping and an array
    of IP addresses that failed to respond.

    .PARAMETER IPRange
    Specifies a range of IP addresses to ping. Can be a string with a single IP address,
    a range of IP addresses in CIDR notation, or an array of IP addresses.
    .PARAMETER TTL
    Specifies the Time-to-Live (TTL) value to use for the ping. The default value is 128.
    .EXAMPLE
    Get-QuickPing -IPRange 192.168.1.1
    Performs a quick ping on the IP address 192.168.1.1 with a TTL of 128 and returns an
    array of IP addresses that responded to the ping and anget- array of IP addresses that
    failed to respond.
    .EXAMPLE
    Get-QuickPing -IPRange 192.168.1.0/24
    Performs a quick ping on all IP addresses in the 192.168.1.0/24 network with a TTL of
    128 and returns an array of IP addresses that responded to the ping and an array of IP
    addresses that failed to respond.
    .EXAMPLE
    Get-QuickPing -IPRange @(192.168.1.1, 192.168.1.2, 192.168.1.3)
    Performs a quick ping on the IP addresses 192.168.1.1, 192.168.1.2, and 192.168.1.3 with
    a TTL of 128 and returns an array of IP addresses that responded to the ping and an array
    of IP addresses that failed to respond.
    .NOTES
    Author: DrIOSx
    #>
    param (
        $IPRange,
        [int]$TTL = 128,
        [int32]$BufferSize = 16,
        [int32]$Count = 1
    )
    begin {
        $SoloRun = $false
        if (!$Script:LogString) {
            $Script:LogString = @()
            #Begin Logging
            $Script:LogString += Write-AuditLog -Message "Begin Log"
            $SoloRun = $true
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
                        $Script:LogString += Write-AuditLog -Message "$IP Found!" -Severity Information
                        $Success += $IP
                    }
                    else {
                        $FailedToPing += $IP
                    }
                }
                else {
                    try {
                        [void](Test-Connection $IP -BufferSize $BufferSize -TimeToLive $TTL -Count $Count -ErrorAction Stop)
                        $Script:LogString += Write-AuditLog -Message "$IP Found!"
                        $Success += $IP
                    }
                    catch {
                        $FailedToPing += $IP
                    }
                }
            }
            catch {}
        }
        if ($null -eq $FailedToPing) {
            $FailedtoPing = "NoIPs"
        }
        if ($null -eq $Success) {
            $FailedtoPing = "NoIPs"
        }
    }
    end {
        if ($SoloRun) {
            $Script:LogString += Write-AuditLog -Message "End Log!"
        }
        return $Success, $FailedToPing
    }
}
function Get-WebCertAudit {
<#
    .SYNOPSIS
    Retrieves the certificate information for a web server.
    .DESCRIPTION
    The Get-WebCert function retrieves the certificate information for
    a web server by creating a TCP connection and using SSL to retrieve
    the certificate information.
    .PARAMETER Url
    The URL of the web server.
    .EXAMPLE
    Get-WebCertAudit -Url "https://www.example.com"
    This example retrieves the certificate information for the web server at https://www.example.com.
    .OUTPUTS
    PSCustomObject
    Returns a PowerShell custom object with the following properties:

    Subject: The subject of the certificate.
    Thumbprint: The thumbprint of the certificate.
    Expires: The expiration date of the certificate.
    .NOTES
    This function requires access to the target web server over port 443 (HTTPS).
    .LINK
    https://github.com/CriticalSolutionsNetwork/ADAuditTasks/wiki/Get-WebCertAudit
    .LINK
    https://criticalsolutionsnetwork.github.io/ADAuditTasks/#Get-WebCertAudit
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Url
    )
    begin {
        #Write-AuditLog -Start
        $Export = @()
    }
    process {
        foreach ($link in $Url) {
            $Req = [System.Net.Sockets.TcpClient]::new($link, '443')
            $Stream = [System.Net.Security.SslStream]::new($Req.GetStream())
            $Stream.AuthenticateAsClient($link)
            $hash = [ordered]@{
                URL        = $link
                Subject    = $Stream.RemoteCertificate.Subject
                Thumbprint = $Stream.RemoteCertificate.GetCertHashString()
                Expires    = $Stream.RemoteCertificate.GetExpirationDateString()
            }
            New-Object -TypeName PSCustomObject -Property $hash -OutVariable PSObject | Out-Null
            $Export += $PSObject
        }
    }
    end {
        #Write-AuditLog -EndFunction
        return $Export
    }
}

function Get-WebCert {
    <#
    .SYNOPSIS
    Retrieves the certificate information for a web server.
    .DESCRIPTION
    The Get-WebCert function retrieves the certificate information for a web server by creating a TCP connection and using SSL to retrieve the certificate information.
    .PARAMETER Url
    The URL of the web server.
    .EXAMPLE
    Get-WebCert -Url "https://www.example.com"

    This example retrieves the certificate information for the web server at https://www.example.com.
    .OUTPUTS
    PSCustomObject
    Returns a PowerShell custom object with the following properties:

    Subject: The subject of the certificate.
    Thumbprint: The thumbprint of the certificate.
    Expires: The expiration date of the certificate.
    #>
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $false)]
        [string]$Url
    )
    $Req = [System.Net.Sockets.TcpClient]::new($url, '443')
    $Stream = [System.Net.Security.SslStream]::new($Req.GetStream())
    $Stream.AuthenticateAsClient($url)
    $hash = [ordered]@{
        Subject             = $Stream.RemoteCertificate.Subject
        Thumbprint          = $Stream.RemoteCertificate.GetCertHashString()
        Expires             = $Stream.RemoteCertificate.GetExpirationDateString()
    }
    New-Object -TypeName PSCustomObject -Property $hash -OutVariable PSObject | Out-Null
    return $PSObject
}
function Submit-FTPUpload {
    <#
    .SYNOPSIS
    Uploads a file to an FTP server using the WinSCP module.
    .DESCRIPTION
    The Submit-FTPUpload function uploads a file to an FTP server using the WinSCP module.
    The function takes several parameters, including the FTP server name, the username and
    password of the account to use, the protocol to use, and the file to upload.
    .PARAMETER FTPUserName
    Specifies the username to use when connecting to the FTP server.
    .PARAMETER Password
    Specifies the password to use when connecting to the FTP server.
    .PARAMETER FTPHostName
    Specifies the name of the FTP server to connect to.
    .PARAMETER Protocol
    Specifies the protocol to use when connecting to the FTP server. The default value is SFTP.
    .PARAMETER FTPSecure
    Specifies the level of security to use when connecting to the FTP server. The default value is None.
    .PARAMETER SshHostKeyFingerprint
    Specifies the fingerprint of the SSH host key to use when connecting to the FTP server. This parameter is mandatory with SFTP and SCP.
    .PARAMETER LocalFilePath
    Specifies the local path to the file to upload to the FTP server.
    .PARAMETER RemoteFTPPath
    Specifies the remote path to upload the file to on the FTP server.
    .OUTPUTS
    The function does not generate any output.
    .EXAMPLE
    PS C:\> Submit-FTPUpload -FTPUserName "username" -Password $Password -FTPHostName "ftp.example.com" -Protocol "Sftp" -FTPSecure "None" -SshHostKeyFingerprint "00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff" -LocalFilePath "C:\temp\file.txt" -RemoteFTPPath "/folder"

    In this example, the Submit-FTPUpload function is used to upload a file to an FTP server.
    The FTP server is named "ftp.example.com" and the file to upload is located at "C:\temp\file.txt".
    The SSH host key fingerprint is also provided.
    .NOTES
    This function requires the WinSCP PowerShell module.
    .LINK
    https://winscp.net/eng/docs/library_powershell
    #>
    [CmdletBinding()]
    param (
        [string]$FTPUserName, # FTP username
        [securestring]$Password, # FTP password
        [string]$FTPHostName, # FTP host name
        [ValidateSet("Sftp", "SCP", "FTP", "Webdav", "s3")]
        [string]$Protocol = "Sftp", # FTP protocol
        [ValidateSet("None", "Implicit ", "Explicit")]
        [string]$FTPSecure = "None", # FTP security
        #[int]$FTPPort = 0, # Not used
        # Mandatory with SFTP/SCP
        [string[]]$SshHostKeyFingerprint, # SSH host key fingerprint
        #[string]$SshPrivateKeyPath, # Not used
        [string[]]$LocalFilePath, # Local file path
        # Send-WinSCPItem
        # './remoteDirectory'
        [string]$RemoteFTPPath # Remote FTP path
    )
    process {
        # This script will run in the context of the user. Please be sure it's a local admin with cached credentials.
        # Required Modules
        Import-Module WinSCP
        # Capture credentials.
        $Credential = [System.Management.Automation.PSCredential]::new($FTPUserName, $Password)
        # Open the session using the SessionOptions object.
        $sessionOption = New-WinSCPSessionOption -Credential $Credential -HostName $FTPHostName -SshHostKeyFingerprint $SshHostKeyFingerprint -Protocol $Protocol -FtpSecure $FTPSecure
        # New-WinSCPSession sets the PSDefaultParameterValue of the WinSCPSession parameter for all other cmdlets to this WinSCP.Session object.
        # You can set it to a variable if you would like, but it is only necessary if you will have more then one session open at a time.
        $WinSCPSession = New-WinSCPSession -SessionOption $sessionOption
        # Check if the remote FTP path exists. If it doesn't, create it.
        if (!(Test-WinSCPPath -Path $RemoteFTPPath -WinSCPSession $WinSCPSession)) {
            New-WinSCPItem -Path $RemoteFTPPath -ItemType Directory -WinSCPSession $WinSCPSession
        }
        # Upload each file in the local file path array to the remote FTP path.
        $errorindex = 0
        foreach ($File in $LocalFilePath) {
            $sendvar = Send-WinSCPItem -Path $File -Destination $RemoteFTPPath -WinSCPSession $WinSCPSession -ErrorAction Stop -ErrorVariable SendWinSCPErr
            if ($sendvar.IsSuccess -eq $false) {
                $ADLogString += Write-AuditLog -Message $SendWinSCPErr -Severity Error
                $errorindex += 1
            }
        }
        # If there was an error during the file upload, throw an error and exit.
        if ($errorindex -ne 0) {
            Write-Output "Error"
            throw 1
        }
        # Close and remove the session object.
        Remove-WinSCPSession -WinSCPSession $WinSCPSession
    }
}

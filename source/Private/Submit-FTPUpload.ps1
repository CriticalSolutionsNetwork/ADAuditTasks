function Submit-FTPUpload {
    [CmdletBinding()]
    param (
        [string]$FTPUserName,
        [securestring]$Password,
        [string]$FTPHostName,
        [ValidateSet("Sftp", "SCP", "FTP", "Webdav", "s3")]
        [string]$Protocol = "Sftp",
        [ValidateSet("None", "Implicit ", "Explicit")]
        [string]$FTPSecure = "None",
        #[int]$FTPPort = 0,
        # Mandatory with SFTP/SCP
        [string[]]$SshHostKeyFingerprint,
        #[string]$SshPrivateKeyPath,
        [string[]]$LocalFilePath,
        # Send-WinSCPItem
        # './remoteDirectory'
        [string]$RemoteFTPPath
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
        if (!(Test-WinSCPPath -Path $RemoteFTPPath -WinSCPSession $WinSCPSession)) {
            New-WinSCPItem -Path $RemoteFTPPath -ItemType Directory -WinSCPSession $WinSCPSession
        }
        # Upload a file to the directory.
        $errorindex = 0
        foreach ($File in $LocalFilePath) {
            $sendvar = Send-WinSCPItem -Path $File -Destination $RemoteFTPPath -WinSCPSession $WinSCPSession -ErrorAction Stop -ErrorVariable SendWinSCPErr
            if ($sendvar.IsSuccess -eq $false) {
                $ADLogString += Write-AuditLog -Message $SendWinSCPErr -Severity Error
                $errorindex += 1
            }
        }
        if ($ErrorIndex -ne 0) {
            Write-Output "Error"
            throw 1
        }
        # Close and remove the session object.
        Remove-WinSCPSession -WinSCPSession $WinSCPSession
    }
}
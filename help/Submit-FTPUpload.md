---
external help file: ADAuditTasks-help.xml
Module Name: ADAuditTasks
online version: https://github.com/CriticalSolutionsNetwork/ADAuditTasks/tree/main/help/Submit-FTPUpload.md
schema: 2.0.0
---

# Submit-FTPUpload

## SYNOPSIS
Uploads a file to an FTP server using the WinSCP module.

## SYNTAX

```
Submit-FTPUpload [[-FTPUserName] <String>] [[-Password] <SecureString>] [[-FTPHostName] <String>]
 [[-Protocol] <String>] [[-FTPSecure] <String>] [[-SshHostKeyFingerprint] <String[]>]
 [[-LocalFilePath] <String[]>] [[-RemoteFTPPath] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Submit-FTPUpload function uploads a file to an FTP server using the WinSCP module.
The function takes several parameters, including the FTP server name, the username and
password of the account to use, the protocol to use, and the file to upload.

## EXAMPLES

### EXAMPLE 1
```
Submit-FTPUpload -FTPUserName "username" -Password $Password -FTPHostName "ftp.example.com" -Protocol "Sftp" -FTPSecure "None" -SshHostKeyFingerprint "00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff" -LocalFilePath "C:\temp\file.txt" -RemoteFTPPath "/folder"
```

In this example, the Submit-FTPUpload function is used to upload a file to an FTP server.
The FTP server is named "ftp.example.com" and the file to upload is located at "C:\temp\file.txt".
The SSH host key fingerprint is also provided.

## PARAMETERS

### -FTPUserName
Specifies the username to use when connecting to the FTP server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
Specifies the password to use when connecting to the FTP server.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FTPHostName
Specifies the name of the FTP server to connect to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Protocol
Specifies the protocol to use when connecting to the FTP server.
The default value is SFTP.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: Sftp
Accept pipeline input: False
Accept wildcard characters: False
```

### -FTPSecure
Specifies the level of security to use when connecting to the FTP server.
The default value is None.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SshHostKeyFingerprint
Specifies the fingerprint of the SSH host key to use when connecting to the FTP server.
This parameter is mandatory with SFTP and SCP.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalFilePath
Specifies the local path to the file to upload to the FTP server.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteFTPPath
Specifies the remote path to upload the file to on the FTP server.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 8
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The function does not generate any output.
## NOTES
This function requires the WinSCP PowerShell module.

## RELATED LINKS

[https://winscp.net/eng/docs/library_powershell](https://winscp.net/eng/docs/library_powershell)



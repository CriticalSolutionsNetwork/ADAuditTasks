$ProjectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$ProjectName = ((Get-ChildItem -Path $ProjectPath\*\*.psd1).Where{
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try { Test-ModuleManifest $_.FullName -ErrorAction Stop } catch { $false } )
    }).BaseName


Import-Module $ProjectName

InModuleScope $ProjectName {
    $ErrorActionPreference = "Stop"

    Describe "Submit-FTPUpload" {
        Context "when all required parameters are provided" {
            It "should upload the file to the remote FTP server" {
                # Arrange
                $FTPUserName = "username"
                $Password = ConvertTo-SecureString "password" -AsPlainText -Force
                $FTPHostName = "ftp.example.com"
                $Protocol = "Sftp"
                $FTPSecure = "None"
                $SshHostKeyFingerprint = "00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff"
                $LocalFilePath = "C:\temp\file.txt"
                $RemoteFTPPath = "/folder"
                $WriteAuditLogMock = New-ModuleFunction -Name 'Write-AuditLog' -ScriptBlock { return }
                Mock Write-AuditLog -Mock $WriteAuditLogMock

                # Mock the necessary cmdlets and functions from the module
                Mock Submit-FTPUpload { return }
                Mock Test-WinSCPPath { return $true }
                Mock Send-WinSCPItem { return @{ IsSuccess = $true } }
                Mock Remove-WinSCPSession { return }
                Mock New-WinSCPSessionOption { return }
                Mock New-WinSCPSession { return }

                # Act
                Submit-FTPUpload -FTPUserName $FTPUserName `
                    -Password $Password `
                    -FTPHostName $FTPHostName `
                    -Protocol $Protocol `
                    -FTPSecure $FTPSecure `
                    -SshHostKeyFingerprint $SshHostKeyFingerprint `
                    -LocalFilePath $LocalFilePath `
                    -RemoteFTPPath $RemoteFTPPath

                # Assert
                Assert-MockCalled Submit-FTPUpload -Exactly 1 -Scope It
                Assert-MockCalled Test-WinSCPPath -Exactly 1 -Scope It
                Assert-MockCalled Send-WinSCPItem -Exactly 1 -Scope It
                Assert-MockCalled Remove-WinSCPSession -Exactly 1 -Scope It
                Assert-MockCalled New-WinSCPSessionOption -Exactly 1 -Scope It
                Assert-MockCalled New-WinSCPSession -Exactly 1 -Scope It
                Assert-MockCalled Write-AuditLog -Exactly 1 -Scope It
            }
        }
    }
}

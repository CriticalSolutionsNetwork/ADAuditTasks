function Send-GraphAppEmail {
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "The New-GraphEmailApp API application object for sending the email.")]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]$GraphEmailApp,

        [Parameter(Mandatory = $true, HelpMessage = "The email address of the recipient.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")]
        [string]$To,

        [Parameter(Mandatory = $true, HelpMessage = "The email address of the sender.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")]
        [string]$FromAddress,

        [Parameter(Mandatory = $true, HelpMessage = "The subject line of the email.")]
        [ValidateNotNullOrEmpty()]
        [string]$Subject,

        [Parameter(Mandatory = $true, HelpMessage = "The body text of the email.")]
        [ValidateNotNullOrEmpty()]
        [string]$EmailBody,

        [Parameter(Mandatory = $false, HelpMessage = "An array of file paths for any attachments to include in the email.")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [string[]]$AttachmentPath

    )
    begin {
        $module = Get-Module -Name Microsoft.Graph -ListAvailable -InformationAction SilentlyContinue
        if (-not $module) {
            Write-Warning "Install Microsoft.Graph Module 1.22.0?"
            try {
                Install-Module Microsoft.Graph -Scope CurrentUser -RequiredVersion "1.22.0"
            }
            catch {
                "You must install the Microsoft.Graph module to continue"
                throw $InstallADModuleError
            }
        } # End If not Module
        try {
            Import-Module Microsoft.Graph.Authentication
            Import-Module Microsoft.Graph.Applications
            Import-Module Microsoft.Graph.Identity.SignIns
            Import-Module Microsoft.Graph.Users
        }
        catch {
            throw "You must import the Microsoft.Graph module to continue"
        } # End Try Catch
        # Step 2:
        # Install and import the ExchangeOnlineManagement module. Tested: 3.1.0
        $module2 = Get-Module -Name ExchangeOnlineManagement -ListAvailable -InformationAction SilentlyContinue
        if (-not $module2) {
            Write-Warning "Install ExchangeOnlineManagement Module 3.1.0?"
            try {
                Install-Module ExchangeOnlineManagement -Scope CurrentUser -RequiredVersion "3.1.0"
            }
            catch {
                throw "You must install the ExchangeOnlineManagement module to continue"
            }
        } # End If not Module
        try {
            Import-Module ExchangeOnlineManagement
        }
        catch {
            throw "You must import the Microsoft.Graph module to continue"
        } # End Try Catch
        Write-Verbose "Successfully imported ExchangeOnlineManagement and Microsoft Graph modules."
        # If a GraphEmailApp object was not passed in, attempt to retrieve it from the local machine
        if (!$GraphEmailApp) {
            try {
                $dataFilePath = "$env:ProgramData\GraphEmailApp\Graphemailapp-$($env:USERDNSDOMAIN).bin"
                $keyFilePath = "$env:ProgramData\GraphEmailApp\GraphAppkey-$($env:USERDNSDOMAIN).bin"
                if (Test-Path $dataFilePath) {
                    $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect([System.IO.File]::ReadAllBytes($dataFilePath), (Get-Content $keyFilePath -Encoding Byte), 'CurrentUser')
                    $decryptedData = [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
                    $decryptedObject = ConvertFrom-Json $decryptedData
                    $GraphEmailApp = $decryptedObject
                }
            }
            catch {
                Write-Error $_.Exception.Message
            }
        } # End Region If
        if (!$GraphEmailApp) {
            Write-Error "GraphEmailApp object not found. Please specify the GraphEmailApp object or provide the AppName and RedirectUri parameters."
            return
        } # End Region If
        # Instatiate the required variables for retreiving the token.
        $AppId = $GraphEmailApp.AppId
        $CertThumbprint = $GraphEmailApp.CertThumbprint
        $Tenant = $GraphEmailApp.TenantID
        $Expiration = $GraphEmailApp.CertExpires
        Write-Verbose "The Certificate $CertThumbprint will expire on $Expiration"
        # Retrieve the self-signed certificate from the local machine's certificate store
        $cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }
        if (!($cert)) {
            throw "Certificate with thumbprint $CertThumbprint not found in local machine's certificate store"
        } # End Region If
        Write-Output "The certificate thumbprint is $CertThumbprint"
    } # End Region Begin
    Process {
        # Authenticate with Azure AD and obtain an access token for the Microsoft Graph API using the certificate
        $MSToken = Get-MsalToken -ClientId $AppId -TenantId $Tenant -ClientCertificate $Cert
        # Set up the request headers
        $authheader = @{Authorization = "Bearer $($MSToken.AccessToken)" }
        # Set up the request URL
        $url = "https://graph.microsoft.com/v1.0/users/$($FromAddress)/sendMail"
        # Build the message body
        $Message =
@"
{
    "message": {
        "subject": "$Subject",
        "body": {
            "contentType": "Text",
            "content": "$EmailBody"
        },
        "toRecipients": [
            {
                "emailAddress": {
                    "address": "$To"
                }
            }
        ]
    }
}
"@
        # Add attachment, if specified
        if ($AttachmentPath) {
            $attachmentName = (Split-Path -Path $AttachmentPath -Leaf)
            $attachmentBytes = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($AttachmentPath))
            $attachment = @{
                "@odata.type"  = "#microsoft.graph.fileAttachment"
                "Name"         = $attachmentName
                "ContentBytes" = $attachmentBytes
            }
            $body.Message.Attachments = $attachment
        } # End Region If
        # Convert the message to JSON format
        $jsonMessage = $message | ConvertTo-Json -Depth 4
        # Set up the request body
        $body = $jsonMessage
    }
    End {
        # Send the email message using the Invoke-RestMethod cmdlet
        Invoke-RestMethod -Headers $authHeader -Uri $url -Body $body -Method POST -ContentType 'application/json'
    } # End Region End
}
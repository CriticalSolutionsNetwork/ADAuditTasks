function Send-GraphAppEmail {
    <#
    .SYNOPSIS
    Sends an email using the Microsoft Graph API.
    .DESCRIPTION
    The Send-GraphAppEmail function uses the Microsoft Graph API to send an email to a specified recipient.
    The function requires the Microsoft Graph API to be set up and requires a pre-created Microsoft Graph API
    app to send the email. The AppName can be passed in as a parameter and the function will retrieve the
    associated authentication details from the Credential Manager.
    .PARAMETER AppName
    The pre-created Microsoft Graph API app name used to send the email.
    .PARAMETER To
    The email address of the recipient.
    .PARAMETER FromAddress
    The email address of the sender who is a member of the Security Enabled Group allowed to send email
    that was configured using the New-GraphEmailApp.
    .PARAMETER Subject
    The subject line of the email.
    .PARAMETER EmailBody
    The body text of the email.
    .PARAMETER AttachmentPath
    An array of file paths for any attachments to include in the email.
    .EXAMPLE
    Send-GraphAppEmail -AppName "GraphEmailApp" -To "recipient@example.com" -FromAddress "sender@example.com" -Subject "Test Email" -EmailBody "This is a test email."
    .NOTES
    The function requires the Microsoft.Graph and MSAL.PS modules to be installed and imported.
    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "The Pre-created New-GraphEmailApp Name for sending the email.")]
        [ValidateNotNullOrEmpty()]
        [string]$AppName,

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
        $Script:LogString = @()
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        $Script:LogString += Write-AuditLog -Message "###############################################"
        # Install and import the Microsoft.Graph module. Tested: 1.22.0
        $PublicMods = `
            "Microsoft.PowerShell.SecretManagement", "SecretManagement.JustinGrote.CredMan", "MSAL.PS"
        $PublicVers = `
            "1.1.2", "1.0.0", "4.37.0.0"
        $params1 = @{
            PublicModuleNames      = $PublicMods
            PublicRequiredVersions = $PublicVers
            Scope                  = "CurrentUser"
        }
        Initialize-ModuleEnv @params1
        # If a GraphEmailApp object was not passed in, attempt to retrieve it from the local machine
        if ($AppName) {
            try {
                # Step 7:
                # Define the application Name and Encrypted File Paths.
                $Auth = Get-Secret -Name "$AppName" -Vault GraphEmailAppLocalStore -AsPlainText -ErrorAction Stop
                $delimiter = "|"
                $values = $Auth.Split($delimiter)

                # Create a new PSCustomObject using the values
                $authobj = [PSCustomObject] @{
                    AppId                  = $values[0]
                    CertThumbprint         = $values[1]
                    TenantID               = $values[2]
                    CertExpires            = $values[3]
                    SendAsUser             = $values[4]
                    AppRestrictedSendGroup = $values[5]
                }
                $GraphEmailApp = $authobj
            }
            catch {
                Write-Error $_.Exception.Message
            }
        } # End Region If
        if (!$GraphEmailApp) {
            throw "GraphEmailApp object not found. Please specify the GraphEmailApp object or provide the AppName and RedirectUri parameters."
        } # End Region If
        # Instatiate the required variables for retreiving the token.
        $AppId = $GraphEmailApp.AppId
        $CertThumbprint = $GraphEmailApp.CertThumbprint
        $Tenant = $GraphEmailApp.TenantID
        $Expiration = $GraphEmailApp.CertExpires
        $Script:LogString += Write-AuditLog -Message "The Certificate $CertThumbprint will expire on $Expiration"
        # Retrieve the self-signed certificate from the CurrentUser's certificate store
        $cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }
        if (!($cert)) {
            throw "Certificate with thumbprint $CertThumbprint not found in CurrentUser's certificate store"
        } # End Region If
        Write-Output "The certificate thumbprint is $CertThumbprint"
    } # End Region Begin
    Process {
        # Authenticate with Azure AD and obtain an access token for the Microsoft Graph API using the certificate
        $MSToken = Get-MsalToken -ClientCertificate $Cert -ClientId $AppId -TenantId $Tenant -Authority "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token" -ErrorAction Stop
        # Set up the request headers
        $authheader = @{Authorization = "Bearer $($MSToken.AccessToken)" }
        # Set up the request URL
        $url = "https://graph.microsoft.com/v1.0/users/$($FromAddress)/sendMail"
        # Build the message body
        # Add a "from" field to the message object in $Message
        $FromField = @{
            emailAddress = @{
                address = "$($FromAddress)"
            }
        }
        $Message = @{
            message = @{
                subject      = "$Subject"
                body         = @{
                    contentType = "text"
                    content     = "$EmailBody"
                }
                toRecipients = @(
                    @{
                        emailAddress = @{
                            address = "$To"
                        }
                    }
                )
                from         = $FromField
            }
        }

        if ($AttachmentPath) {
            $attachmentName = (Split-Path -Path $AttachmentPath -Leaf)
            $attachmentBytes = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($AttachmentPath))
            $attachment = @{
                "@odata.type"  = "#microsoft.graph.fileAttachment"
                "Name"         = $attachmentName
                "ContentBytes" = $attachmentBytes
            }
            $Message.message.attachments = $attachment
        }

        $jsonMessage = $message | ConvertTo-Json -Depth 4
        $body = $jsonMessage
    }
    End {
        try {
            # Send the email message using the Invoke-RestMethod cmdlet
            $Script:LogString += Write-AuditLog -Message "Sending email via Microsoft Graph"
            Invoke-RestMethod -Headers $authHeader -Uri $url -Body $body -Method POST -ContentType 'application/json'
            $Script:LogString += Write-AuditLog -Message "Message sent to $To from $FromAddress with $(($Message.message.attachments).Count) attachments."
        }
        catch {
            throw $_.Exception
        }
    } # End Region End
}
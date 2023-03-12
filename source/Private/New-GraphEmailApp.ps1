function New-GraphEmailApp {
    <#
    .SYNOPSIS
        Creates a new Microsoft Graph Email app and associated certificate for app-only authentication.
    .DESCRIPTION
        This cmdlet creates a new Microsoft Graph Email app and associated certificate for app-only authentication.
        It requires a 2 to 4 character long prefix ID for the app, files and certs that are created, as well as the
        email address of the sender and the Group the sender is a part of to assign app policy restrictions.
        This cmdlet also requires that the user running the cmdlet is a local administrator and has the necessary
        permissions to create the app and connect to Exchange Online.
    .PARAMETER Prefix
        The 2 to 4 character long prefix ID of the app, files and certs that are created.
    .PARAMETER UserId
        The email address of the sender.
    .PARAMETER MailEnabledSendingGroup
        The email of the Group the sender is a member of to assign app policy restrictions.
        For Example: IT-AuditEmailGroup@contoso.com

        You can create the group using the admin center at https://admin.microsoft.com or you can create it
        using the following commands as an example.
            # Import the ExchangeOnlineManagement module
            Import-Module ExchangeOnlineManagement

            # Connect to Exchange Online
            Connect-ExchangeOnline -UserPrincipalName admin@contoso.com

            # Create a new mail-enabled security group
            New-DistributionGroup -Name "My Group" -Members "user1@contoso.com", "user2@contoso.com" -MemberDepartRestriction Closed
    .PARAMETER CertThumbprint
        The thumbprint of the certificate to use. If not specified, a self-signed certificate will be generated.
    .EXAMPLE
        PS C:\> New-GraphEmailApp -Prefix ABC -UserId jdoe@example.com -MailEnabledSendingGroup "Example Mail Group" -CertThumbprint "9B8B40C5F148B710AD5C0E5CC8D0B71B5A30DB0C"
    .INPUTS
        None
    .OUTPUTS
        Returns a pscustomobject containing the AppId, CertThumbprint, TenantID, and CertExpires.
    .NOTES
        This cmdlet requires that the user running the cmdlet is a local administrator and has the necessary permissions
        to create the app and connect to Exchange Online. In addition, a mail-enabled security group must already exist
        in Exchange Online for the MailEnabledSendingGroup parameter.

        # https://www.powershellgallery.com/packages/Microsoft.Graph/1.23.0 Updated: 3/4/2023
        $params1 = @{
            PublicModuleNames      = "PSnmap","Microsoft.Graph"
            PublicRequiredVersions = "1.3.1","1.23.0"
            ImportModuleNames      = "Microsoft.Graph.Authentication", "Microsoft.Graph.Identity.SignIns"
            Scope                  = "CurrentUser"
        }
        Initialize-ModuleEnv @params1 -Verbose
    #>

    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The 2 to 4 character long prefix ID of the app, files and certs that are created.")]
        [ValidatePattern('^[A-Z]{2,4}$')]
        [string]$Prefix,

        [Parameter(Mandatory = $true, HelpMessage = "The email address of the sender.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")]
        [String] $UserId,

        [Parameter(Mandatory = $true, HelpMessage = "The Group the sender is a part of to assign app policy restrictions.")]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$")]
        [String] $MailEnabledSendingGroup,

        [Parameter(Mandatory = $false, HelpMessage = "The thumbprint of the certificate to use")]
        [String] $CertThumbprint = $null
    )
    begin {
        # Step 0:
        # Test-IsAdmin
        if (!(Test-IsAdmin)) {
            throw "The function must be running as a local administrator."
        }
        # Step 1:
        # Install and import the Microsoft.Graph module. Tested: 1.22.0
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
        # Step 3:
        # Create the file paths for the encrypted files.
        $dataFilePath = "$env:ProgramData\GraphEmailApp\Graphemailapp-$($env:USERDNSDOMAIN).bin"
        $keyFilePath = "$env:ProgramData\GraphEmailApp\GraphAppkey-$($env:USERDNSDOMAIN).bin"
        # Begin Logging
        Write-Verbose "Begin Log"
        # Step 4:
        # Connect to MSGraph with the appropriate permission scopes and then Exchange.
        Write-Verbose "Connecting to MSGraph and ExchangeOnline"
        Connect-MgGraph -Scopes "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "Directory.ReadWrite.All"
        Connect-ExchangeOnline
        # Step 5:
        # Get the MGContext
        $context = Get-MgContext
        # Step 6:
        # Instantiate the user variable.
        $user = Get-MgUser -Filter "Mail eq '$UserId'"
        # Step 7:
        # Define the application Name and Encrypted File Paths.
        $AppName = "$($Prefix)-AuditGraphEmail-$($env:USERDNSDOMAIN)-As-$($user.DisplayName.Replace(' ',''))"
        # Step 8:
        # Instantiate the Microsoft Graph API resource ID.
        Write-Verbose "Verifying Microsoft Graph Service Principal AppId"
        $graphServicePrincipal = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'"
        $graphResourceId = $graphServicePrincipal.AppId
        Write-Verbose "Microsoft Graph Service Principal AppId is $graphResourceId"
        # Step 9:
        # Build resource requirements variable using Find-MgGraphCommand -Command New-MgApplication | Select -First 1 -ExpandProperty Permissions
        # Find-MgGraphPermission -PermissionType Application -All | ? {$_.name -eq "Mail.Send"}
        $resId = (Find-MgGraphPermission -PermissionType Application -All | Where-Object { $_.name -eq "Mail.Send" }).Id

    }
    process {
        # Step 10:
        # Create or retrieve certificate from the store.
        try {
            if (!$CertThumbprint) {
                # Create a self-signed certificate for the app.
                $Cert = New-SelfSignedCertificate -Subject "CN=$AppName" -CertStoreLocation "Cert:\LocalMachine\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
                $CertThumbprint = $Cert.Thumbprint
                $CertExpirationDate = $Cert.NotAfter
            }
            else {
                if (Test-Path $dataFilePath) {
                    $answer = Read-Host "It Appears you have a previous configuration. Would you still like to continue?"
                    if ($answer -eq "y") {
                        Continue
                    }
                    else {
                        throw "Exiting function to preserve previous configuration on the local device."
                    }
                }
                # Retrieve the certificate from the local machine's certificate store.
                $Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }
                if (!($Cert)) {
                    throw "Certificate with thumbprint $CertThumbprint not found in local machine's certificate store."
                }
                $CertThumbprint = $Cert.Thumbprint
                $CertExpirationDate = $Cert.NotAfter
            }
        }
        catch {
            # If there is an error, throw an exception with the error message.
            throw $Error[0].Exception
        }

        # Step 11:
        # Create the app registration with the required permissions and the self-signed certificate.
        try {
            Write-Verbose "Creating app registration..."

            # Build required resource access list.
            $RequiredResourceAccess = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
            $RequiredResourceAccess.ResourceAppId = $GraphResourceId
            $RequiredResourceAccess.ResourceAccess += @{ Id = $ResID; Type = "Role" }
            $AppPermissions = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
            $AppPermissions.Add($RequiredResourceAccess)
            Write-Verbose "App permissions are: $AppPermissions"
            # Create app registration.
            $AppRegistration = New-MgApplication -DisplayName $AppName -SignInAudience "AzureADMyOrg" `
                -Web @{ RedirectUris = "http://localhost"; } `
                -RequiredResourceAccess $RequiredResourceAccess `
                -AdditionalProperties @{} -KeyCredentials @(@{ Type = "AsymmetricX509Cert"; Usage = "Verify"; Key = $Cert.RawData })

            Write-Verbose "App registration created with app ID $($AppRegistration.AppId)"
            Start-Sleep 15
        }
        catch {
            # If there is an error, throw an exception with the error message.
            throw $Error[0].Exception
        } # End Region catch
        # Step 12:
        # Create a Service Principal for the app.
        Write-Verbose "Creating service principal for app with AppId $($AppRegistration.AppId)"
        New-MgServicePrincipal -AppId $AppRegistration.AppId -AdditionalProperties @{}
        # Step 13:
        # Get the client Service Principal for the created app.
        $ClientSp = Get-MgServicePrincipal -Filter "appId eq '$($AppRegistration.AppId)'"
        # Step 14:
        # Build the parameters for the New-MgOauth2PermissionGrant and create the grant.
        $Params = @{
            "ClientId"    = $ClientSp.Id
            "ConsentType" = "AllPrincipals"
            "ResourceId"  = $GraphServicePrincipal.Id
            "Scope"       = "Mail.Send"
        }
        New-MgOauth2PermissionGrant -BodyParameter $Params
        # Step 15:
        # Create the admin consent url:
        $adminConsentUrl = "https://login.microsoftonline.com/" + $context.TenantId + "/adminconsent?client_id=" `
            + $appRegistration.AppId
        Write-Host -ForegroundColor Yellow "Please go to the following URL in your browser to provide admin consent"
        Write-Host $adminConsentUrl
        Write-Host "Graph Command you can save:"
        # Step 16:
        # Generate graph command that can be used to connect later that can be copied and saved.
        $connectGraph = "Connect-MgGraph -ClientId """ + $appRegistration.AppId + """ -TenantId """`
            + $context.TenantId + """ -CertificateName """ + $cert.SubjectName.Name + """"
        Write-Host -ForegroundColor Cyan "After providing admin consent, you can use the following values with Connect-MgGraph for app-only authentication:"
        Write-Host $connectGraph

    } # End Region Process
    end {
        # Step 17:
        # Set app access policy in Exchange Online and constrain to Mail Enabled Sending Group.
        New-ApplicationAccessPolicy -AppId $appRegistration.AppId -PolicyScopeGroupId $MailEnabledSendingGroup -AccessRight RestrictAccess -Description "Limit MSG application to only send emails as a group of users"
        # Step 18:
        # Create the output object with the certificate thumbprint and expiration, the tenantid and appid.
        $output = [PSCustomObject] @{
            AppId          = $appRegistration.AppId
            CertThumbprint = $CertThumbprint
            TenantID       = $context.TenantId
            CertExpires    = $certExpirationDate.ToString("yyyy-MM-dd HH:mm:ss")
        }
        # Step 19:
        # Create local Encrypted file for retrieval.
        # Generate a random AES key and store it securely on the system

        if (!(Test-Path $keyFilePath)) {
            $key = New-Object Byte[] 32
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($key)
            Set-Content -Path $keyFilePath -Value $key -Encoding Byte
        }

        # Remove the file if it already exists
        if (Test-Path $dataFilePath) {
            Remove-Item $dataFilePath -Force
        }
        # Create the directory if it doesn't exist
        $dataDir = Split-Path $dataFilePath -Parent
        if (!(Test-Path $dataDir)) {
            New-Item -ItemType Directory -Path $dataDir | Out-Null
        }
        # Convert the object to a JSON string
        $jsonString = ConvertTo-Json $output
        # Encrypt the string using the AES key
        $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect([System.Text.Encoding]::UTF8.GetBytes($jsonString), (Get-Content $keyFilePath -Encoding Byte), 'CurrentUser')
        # Save the encrypted bytes to a file
        [System.IO.File]::WriteAllBytes($dataFilePath, $encryptedBytes)
        return $output
    } # End Region End
}
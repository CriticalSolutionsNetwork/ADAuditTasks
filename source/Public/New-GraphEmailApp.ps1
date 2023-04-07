function New-GraphEmailApp {
    <#
    .SYNOPSIS
    Creates a new Microsoft Graph Email app and associated certificate for app-only authentication.
    .DESCRIPTION
    This cmdlet creates a new Microsoft Graph Email app and associated certificate for app-only authentication.
    It requires a 2 to 4 character long prefix ID for the app, files and certs that are created, as well as the
    email address of the sender and the email of the Group the sender is a part of to assign app policy restrictions.
    .PARAMETER Prefix
    The 2 to 4 character long prefix ID of the app, files and certs that are created. Meant to group multiple runs
    so that if run in different environments, they will stack naturally in Azure. Ensure you use the same prefix each
    time if you'd like this behavior.
    .PARAMETER UserId
    The email address of the sender.
    .PARAMETER MailEnabledSendingGroup
    The email of the Group the sender is a member of to assign app policy restrictions.
    For Example: IT-AuditEmailGroup@contoso.com
    You can create the group using the admin center at https://admin.microsoft.com or you can create it
    using the following commands as an example.
        # Import the ExchangeOnlineManagement module
        Import-Module ExchangeOnlineManagement

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
    This cmdlet requires that the user running the cmdlet have the necessary permissions
    to create the app and connect to Exchange Online. In addition, a mail-enabled security
    group must already exist in Exchange Online for the MailEnabledSendingGroup parameter.
    #>

    [OutputType([pscustomobject])]
    [CmdletBinding(HelpURI = "https://criticalsolutionsnetwork.github.io/ADAuditTasks/#New-GraphEmailApp")]
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
        # Begin Logging
        $Script:LogString = @()
        $Script:LogString += Write-AuditLog -Message "Begin Log"
        $Script:LogString += Write-AuditLog -Message "###############################################"
        # Install and import the Microsoft.Graph module. Tested: 1.22.0
        $PublicMods = `
            "Microsoft.Graph", "ExchangeOnlineManagement", `
            "Microsoft.PowerShell.SecretManagement", "SecretManagement.JustinGrote.CredMan"
        $PublicVers = `
            "1.22.0", "3.1.0", `
            "1.1.2", "1.0.0"
        $ImportMods = `
            "Microsoft.Graph.Authentication", `
            "Microsoft.Graph.Applications", `
            "Microsoft.Graph.Identity.SignIns", `
            "Microsoft.Graph.Users"
        $params1 = @{
            PublicModuleNames      = $PublicMods
            PublicRequiredVersions = $PublicVers
            ImportModuleNames      = $ImportMods
            Scope                  = "CurrentUser"
        }
        Initialize-ModuleEnv @params1


        # Step 4:
        # Connect to MSGraph with the appropriate permission scopes and then Exchange.
        $Script:LogString = Write-AuditLog "Connecting to MgGraph and ExchangeOnline using modern authentication pop-up."
        try {
            $Script:LogString = Write-AuditLog "Connecting to MgGraph..."
            Connect-MgGraph -Scopes "Application.ReadWrite.All", "DelegatedPermissionGrant.ReadWrite.All", "Directory.ReadWrite.All"
            $Script:LogString = Write-AuditLog "Connected to MgGraph"
            Read-Host "Press Enter to connect to ExchangeOnline." -ErrorAction Stop
            Connect-ExchangeOnline -ErrorAction Stop
            $Script:LogString = Write-AuditLog "Connected to ExchangeOnline."
            Read-Host "Press Enter to continue." -ErrorAction Stop
        }
        catch {
            throw $_.Exception
        }


        # Step 5:
        # Get the MGContext
        $context = Get-MgContext
        # Step 6:
        # Instantiate the user variable.
        $user = Get-MgUser -Filter "Mail eq '$UserId'"
        # Step 7:
        # Define the application Name and Encrypted File Paths.
        $AppName = "$($Prefix)-AuditGraphEmail-$($env:USERDNSDOMAIN)-As-$(($user.UserPrincipalName).Split("@")[0])"
        $graphServicePrincipal = Get-MgServicePrincipal -Filter "DisplayName eq 'Microsoft Graph'"
        $graphResourceId = $graphServicePrincipal.AppId
        $Script:LogString = Write-AuditLog "Microsoft Graph Service Principal AppId is $graphResourceId"
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
                $Cert = New-SelfSignedCertificate -Subject "CN=$AppName" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable -KeySpec Signature -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256
                $CertThumbprint = $Cert.Thumbprint
                $CertExpirationDate = $Cert.NotAfter
            }
            else {
                # Retrieve the certificate from the CurrentUser's certificate store.
                $Cert = Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Thumbprint -eq $CertThumbprint }
                if (!($Cert)) {
                    throw "Certificate with thumbprint $CertThumbprint not found in CurrentUser's certificate store."
                }
                $CertThumbprint = $Cert.Thumbprint
                $CertExpirationDate = $Cert.NotAfter
            }
        }
        catch {
            # If there is an error, throw an exception with the error message.
            throw $_.Exception
        }
        # Step 11:
        # Create the app registration with the required permissions and the self-signed certificate.
        try {
            $Script:LogString = Write-AuditLog "Creating app registration..."
            # Build required resource access list.
            $RequiredResourceAccess = New-Object -TypeName Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess
            $RequiredResourceAccess.ResourceAppId = $GraphResourceId
            $RequiredResourceAccess.ResourceAccess += @{ Id = $ResID; Type = "Role" }
            $AppPermissions = New-Object -TypeName System.Collections.Generic.List[Microsoft.Graph.PowerShell.Models.MicrosoftGraphRequiredResourceAccess]
            $AppPermissions.Add($RequiredResourceAccess)
            $Script:LogString = Write-AuditLog "App permissions are: $AppPermissions"
            # Create app registration.
            $AppRegistration = New-MgApplication -DisplayName $AppName -SignInAudience "AzureADMyOrg" `
                -Web @{ RedirectUris = "http://localhost"; } `
                -RequiredResourceAccess $RequiredResourceAccess `
                -AdditionalProperties @{} `
                -KeyCredentials @(@{ Type = "AsymmetricX509Cert"; Usage = "Verify"; Key = $Cert.RawData })
            if (!($AppRegistration)) {
                throw "The app creation failed for $($AppName)."
            }
            $Script:LogString = Write-AuditLog "App registration created with app ID $($AppRegistration.AppId)"
            Start-Sleep 15
        }
        catch {
            # If there is an error, throw an exception with the error message.
            throw $_.Exception
        } # End Region catch
        # Step 12:
        # Create a Service Principal for the app.
        $Script:LogString = Write-AuditLog "Creating service principal for app with AppId $($AppRegistration.AppId)"
        New-MgServicePrincipal -AppId $AppRegistration.AppId -AdditionalProperties @{}
        # Step 13:
        # Get the client Service Principal for the created app.

        $ClientSp = Get-MgServicePrincipal -Filter "appId eq '$($AppRegistration.AppId)'"
        if (!($ClientSp)) {
            Write-AuditLog "Client service Principal not found for $($AppRegistration.AppId)" -Error
            throw "Unable to find Client Service Principal."
        }

        # Step 14:
        # Build the parameters for the New-MgOauth2PermissionGrant and create the grant.
        $Params = @{
            "ClientId"    = $ClientSp.Id
            "ConsentType" = "AllPrincipals"
            "ResourceId"  = $GraphServicePrincipal.Id
            "Scope"       = "Mail.Send"
        }
        New-MgOauth2PermissionGrant -BodyParameter $Params -Confirm:$false
        # Step 15:
        # Create the admin consent url:
        $adminConsentUrl = `
            "https://login.microsoftonline.com/" + $context.TenantId + "/adminconsent?client_id=" + $appRegistration.AppId
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
        try {
            $Script:LogString = Write-AuditLog -Message "Creating Exchange Application policy for $($MailEnabledSendingGroup) for AppId $($AppRegistration.AppId)."
            New-ApplicationAccessPolicy -AppId $appRegistration.AppId `
                -PolicyScopeGroupId $MailEnabledSendingGroup -AccessRight RestrictAccess `
                -Description "Limit MSG application to only send emails as a group of users" -ErrorAction Stop
            $Script:LogString = Write-AuditLog -Message "Created Exchange Application policy for $($MailEnabledSendingGroup)."
        }
        catch {
            throw $_.Exception
        }


        # Step 18:
        # Create the output object with the certificate thumbprint and expiration, the tenantid and appid.

        if (!(Get-SecretVault -Name GraphEmailAppLocalStore)) {
            try {
                $Script:LogString = Write-AuditLog -Message "Registering CredMan Secret Vault"
                Register-SecretVault -Name GraphEmailAppLocalStore -ModuleName "SecretManagement.JustinGrote.CredMan" -ErrorAction Stop
                $Script:LogString = Write-AuditLog -Message "Secret Vault: GraphEmailAppLocalStore registered."
            }
            catch {
                throw $_.Exception
            }
        }
        elseif ((Get-SecretInfo -Name "CN=$AppName" -Vault GraphEmailAppLocalStore) ) {
            $Script:LogString = Write-AuditLog -Message "Secret found! Would you like to delete the previous configuration for `"CN=$AppName.`"?" -Severity Warning
            try {
                Remove-Secret -Name "CN=$AppName" -Vault GraphEmailAppLocalStore -Confirm:$false -ErrorAction Stop
                $Script:LogString = Write-AuditLog -Message "Previous secret CN=$AppName removed."
            }
            catch {
                throw $_.Exception
            }
        }
        $output = [PSCustomObject] @{
            AppId                  = $appRegistration.AppId
            CertThumbprint         = $CertThumbprint
            TenantID               = $context.TenantId
            CertExpires            = $certExpirationDate.ToString("yyyy-MM-dd HH:mm:ss")
            SendAsUser             = $($user.UserPrincipalName.Split("@")[0])
            AppRestrictedSendGroup = $MailEnabledSendingGroup
        }
        $delimiter = '|'
        $joinedString = ($output.PSObject.Properties.Value) -join $delimiter
        try {

            Set-Secret -Name "CN=$AppName" -Secret $joinedString -Vault GraphEmailAppLocalStore -ErrorAction Stop
        }
        catch {
            throw $_.Exception
        }
        $Script:LogString = Write-AuditLog -Message "Returning output. Save the AppName $("CN=$AppName"). The AppName will be needed to retreive the secret containing authentication info."
        return $output
    } # End Region End
}
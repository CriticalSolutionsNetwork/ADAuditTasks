function Send-AuditEmail {
    <#
    .SYNOPSIS
    This is a wrapper function for Send-MailKitMessage and takes string arrays as input.
    .DESCRIPTION
    Other Audit tasks can be used as the -AttachmentFiles parameter when used with the report switch.
    .EXAMPLE
    Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
    -From "Username@contoso.com" -To "user@anothercompany.com" -Pass (Read-Host -AsSecureString) -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -SSL

        This will automatically send the report zip via email to the parameters specified.
        There is no cleanup of files. Please cleanup the directory of zip's if neccessary.
    .EXAMPLE
    Send-AuditEmail -SMTPServer "smtp.office365.com" -Port 587 -UserName "Username@contoso.com" `
    -From "Username@contoso.com" -To "user@anothercompany.com" -AttachmentFiles "$(Get-ADActiveUserAudit -Report)" -FunctionApp "MyVaultFunctionApp" `
    -Function "MyClientSpecificFunction" -Token "ABCDEF123456" -SSL

        This will automatically send the report zip via email to the parameters specified.
        There is no cleanup of files. Please cleanup the directory of zip's if neccessary.
    .PARAMETER SMTPServer
        The SMTP Server address. For example: "smtp.office365.com"
    .PARAMETER AttachmentFiles
        The full filepath to the zip you are sending:
            -AttachmentFiles "C:\temp\ADHostAudit\2023-01-04_03.45.14_Get-ADHostAudit_AD.CONTOSO.COM.Servers.zip"

        The Audit reports output this filename if the "-Report" switch is used allowing it to be nested in this parameter
        for ease of automation.
    .PARAMETER Port
        The following ports can be used to send email:
            "993", "995", "587", "25"
    .PARAMETER UserName
        The Account authorized to send email via SMTP. From parameter is usually the same.
    .PARAMETER SSL
        Switch to ensure SSL is used during transport.
    .PARAMETER From
        This is who the email will appear to originate from. This is either the same as the UserName,
        or, if delegated, access to an email account the Username account has delegated permissions to send for.
        Link:
            https://learn.microsoft.com/en-us/microsoft-365/admin/add-users/give-mailbox-permissions-to-another-user?view=o365-worldwide
    .PARAMETER To
        This is the mailbox who will be the recipient of the communication.
    .PARAMETER Subject
        The subject is automatically populated with the name of the function that ran the script,
        as well as the domain and hostname.

        If you specify subject in the parameters, it will override the default with your subject.
    .PARAMETER Body
        The body of the message, pre-populates with the same data as the subject line. Specify body text
        in the function parameters to override.
    .PARAMETER Pass
        Takes a SecureString as input. The password must be added to the command by using:
            -Pass (Read-Host -AsSecureString)
            You will be promted to enter the password for the UserName parameter.
    .PARAMETER Function
        If you are using the optional function feature and created a password retrieval function,
        this is the name of the function in Azure AD that accesses the vault.
    .PARAMETER FunctionApp
        If you are using the optional function feature, this is the name of the function app in Azure AD.
    .PARAMETER Token
        If you are using the optional function feature, this is the api token for the specific function.
        Ensure you are using the "Function Key" and NOT the "Host Key" to ensure access is only to the specific funtion.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Pass')]
    param (
        [Parameter(
            MandaTory = $true,
            HelpMessage = 'Enter the Zip file paths as comma separated array with quotes for each filepath',
            ValueFromPipelineByPropertyName = $true
        )][string[]]$AttachmentFiles,
        [string]$SMTPServer,
        [Parameter(
            HelpMessage = 'Enter the port number for the mail relay',
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateSet("993", "995", "587", "25")]
        [int]$Port,
        [string]$UserName,
        [switch]$SSL,
        [string]$From,
        [string]$To,
        [string]$Subject = "$($script:MyInvocation.MyCommand.Name -replace '\..*') report ran for $($env:USERDNSDOMAIN) on host $($env:COMPUTERNAME).",
        [string]$Body = "$($script:MyInvocation.MyCommand.Name -replace '\..*') report ran for $($env:USERDNSDOMAIN) on host $($env:COMPUTERNAME).",
        [Parameter(
            ParameterSetName = 'Pass',
            HelpMessage = 'Enter this as the parameter: (Read-Host -AsSecureString)'
        )]
        [securestring]$Pass,
        [Parameter(
            ParameterSetName = 'Func',
            HelpMessage = 'Enter the name of the Function as showing in the function app'
        )]
        [string]$Function,
        [Parameter(
            ParameterSetName = 'Func',
            HelpMessage = 'Enter the name of the function app'
        )]
        [string]$FunctionApp,
        [Parameter(
            ParameterSetName = 'Func',
            HelpMessage = 'Enter the API key associated with the function. Not the Host Key.'
        )]
        [string]$Token
    )
    begin {
        $module = Get-Module -Name Send-MailKitMessage -ListAvailable
        if (-not $module) {
            Install-Module -Name Send-MailKitMessage -AllowPrerelease -Scope CurrentUser -Force
        }
        try {
            Import-Module "Send-MailKitMessage" -Global -ErrorAction STop -ErrorVariable MailkitErr | Out-Null
        }
        catch {
            # End run and log To file.
            $ADLogString += Write-AuditLog -Message "The Module Was not installed. Use `"Save-Module -Name Send-MailKitMessage -AllowPrerelease -Path C:\temp`" on another Windows Machine."
            $ADLogString += Write-AuditLog -Message "End Log" -Severity Error
            throw MailkitErr
        }
        # Recipient
        $RecipientList = [MimeKit.InternetAddressList]::new()
        $RecipientList.Add([MimeKit.InternetAddress]$To)
        # Attachment
        $AttachmentList = [System.Collections.Generic.List[string]]::new()
        foreach ($currentItem in $attachmentfiles) {
            $AttachmentList.Add("$currentItem")
        }
        # From
        $From = [MimeKit.MailboxAddress]$From
        # Mail Account variable
        $User = $UserName
        if ($Pass) {
            # Set Credential To $Password parameter input.
            $Credential = `
                [System.Management.AuTomation.PSCredential]::new($User, $Pass)
        }
        elseif ($FunctionApp) {
            $url = "https://$($FunctionApp).azurewebsites.net/api/$($Function)"
            # Retrieve credentials From function app url inTo a SecureString.
            $a, $b = (Invoke-RestMethod $url -Headers @{ 'x-functions-key' = "$Token" }).split(',')
            $Credential = `
                [System.Management.AuTomation.PSCredential]::new($User, (ConvertTo-SecureString -String $a -Key $b.split(' ')) )
        }
    }
    Process {
        $Parameters = @{
            "UseSecureConnectionIfAvailable" = $SSL
            "Credential"                     = $Credential
            "SMTPServer"                     = $SMTPServer
            "Port"                           = $Port
            "From"                           = $From
            "RecipientList"                  = $RecipientList
            "Subject"                        = $Subject
            "TextBody"                       = $Body
            "AttachmentList"                 = $AttachmentList
        }
        Send-MailKitMessage @Parameters
    }
    End {
        Clear-Variable -Name "a", "b", "Credential", "Token" -Scope Local -ErrorAction SilentlyContinue
    }
}
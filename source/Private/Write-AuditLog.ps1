function Write-AuditLog {
    <#
    .SYNOPSIS
    Writes an audit log entry with a specified message and severity level.
    .DESCRIPTION
    The Write-AuditLog function writes an audit log entry to the console,
    providing information about the time, the version of the module and the
    function, the PowerShell version, whether the user is an administrator,
    the user's domain and username, the computer name, the severity level,
    and the specified message.
    .PARAMETER Message
    Specifies the message to include in the audit log entry. This parameter is mandatory.
    .PARAMETER Severity
    Specifies the severity level of the audit log entry. Valid values are 'Information',
    'Warning', and 'Error'. The default value is 'Information'.
    .OUTPUTS
    Returns a pscustomobject representing the audit log entry with the following properties:
    - Time: The date and time when the log entry was created.
    - PSVersion: The version of PowerShell.
    - IsAdmin: Whether the user is an administrator.
    - User: The domain and username of the user who invoked the function.
    - HostName: The name of the computer where the function was invoked.
    - InvokedBy: The name and version of the module and the function.
    - Severity: The severity level of the audit log entry.
    - Message: The message included in the audit log entry.
    .EXAMPLE
    Write-AuditLog -Message "Successful login." -Severity Information

    This example writes an audit log entry with the message "Successful login" and the severity level 'Information'.
    .NOTES
    This function is intended to be used for auditing purposes to keep track of events happening in a PowerShell script or module.
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    # Define the parameters of the function.
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Input a Message string.',
            Position = 0
        )]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
        [Parameter(
            HelpMessage = 'Information, Warning or Error.',
            Position = 1
        )]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Severity = 'Information'
    )
    # Switch statement to determine what action to take based on the severity parameter.
    switch ($Severity) {
        'Warning' { Write-Warning $Message -WarningAction Inquire }
        'Error' { Write-Error $Message }
        Default { Write-Verbose $Message }
    }
    # Set the error action preference to silently continue.
    $ErrorActionPreference = "SilentlyContinue"
    # Define variables to hold information about the command that was invoked.
    $ModuleName = $Script:MyInvocation.MyCommand.Name -replace '\..*'
    $FuncName = (Get-PSCallStack)[1].Command
    $ModuleVer = $MyInvocation.MyCommand.Version.ToString()
    # Set the error action preference to continue.
    $ErrorActionPreference = "Continue"
    # Return a custom object containing the specified properties with their values.
    return [pscustomobject]@{
        Time      = ((Get-Date).ToString('yyyy-MM-dd hh:mmTss'))
        PSVersion = ($PSVersionTable.PSVersion).ToString()
        IsAdmin   = $(Test-IsAdmin)
        User      = "$Env:USERDOMAIN\$Env:USERNAME"
        HostName  = $Env:COMPUTERNAME
        InvokedBy = $( $ModuleName + "/" + $FuncName + '.v' + $ModuleVer )
        Severity  = $Severity
        Message   = $Message
    }
}

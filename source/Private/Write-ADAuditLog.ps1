function Write-AuditLog {
    [OutputType([pscustomobject])]
    [CmdletBinding()]
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
    switch ($Severity) {
        'Warning' { Write-Warning $Message -WarningAction Inquire }
        'Error' { Write-Error $Message }
        Default { Write-Verbose $Message }
    }
    $ErrorActionPreference = "SilentlyContinue"
    $ModuleName = $Script:MyInvocation.MyCommand.Name -replace '\..*'
    $FuncName = (Get-PSCallStack)[1].Command
    $ModuleVer = $MyInvocation.MyCommand.Version.ToString()
    $ErrorActionPreference = "Continue"
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
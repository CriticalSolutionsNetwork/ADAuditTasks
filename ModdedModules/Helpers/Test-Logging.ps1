function Invoke-PrivateFunction1 {
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog 'Invoke-PrivateFunction1 Verbose Log'
    Start-Sleep -Seconds 2

    Write-AuditLog -EndFunction
}

function Invoke-PrivateFunction2 {
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog 'Invoke-PrivateFunction2 Verbose Log'

    Start-Sleep -Seconds 1

    Write-AuditLog -EndFunction
}

function Invoke-MainFunction {
    Write-AuditLog -Start
    Write-AuditLog "Calling 2 private functions."
    # Call the private functions
    Invoke-PrivateFunction1
    Invoke-PrivateFunction2

    Write-AuditLog "Reports saved to: $(Get-Location)"

    $logTime = (Get-Date).ToString('yyyy-MM-dd.hh.mmTss')
    $outputPath = Join-Path -Path (Get-Location) -ChildPath "AuditLog_$($logTime).csv"
    Write-AuditLog -End -OutputPath $outputPath
}


# Ensure the script's verbose output is displayed
$VerbosePreference = 'Continue'

# Run the main function
Invoke-MainFunction

# Reset the verbose preference
$VerbosePreference = 'SilentlyContinue'
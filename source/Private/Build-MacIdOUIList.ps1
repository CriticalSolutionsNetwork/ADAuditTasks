<#
.SYNOPSIS
    Builds a list of MAC ID OUIs.
.DESCRIPTION
    This function builds a list of MAC ID OUIs. The function retrieves the OUI
    list from the IEEE Standards Association website or from a local CSV file.
.OUTPUTS
    System.Collections.Generic.List[System.Management.Automation.PSCustomObject]
    A list of custom objects that contains MAC ID OUIs.
.EXAMPLE
    $ouilist = Build-MacIdOUIList
    $ouilist
.NOTES
    Author: DrIOSx
#>

function Build-MacIdOUIList {
    if (!($script:LogString)) {
        Write-AuditLog -Start
    }
    else {
        Write-AuditLog -BeginFunction
    }
    Write-AuditLog -Message "Retrieving MACID OUI list from https://standards-oui.ieee.org/oui/oui.csv"
    try {
        $ouiobject = Invoke-RestMethod https://standards-oui.ieee.org/oui/oui.csv | ConvertFrom-Csv -ErrorAction Stop
        Write-AuditLog -Message "Successfully downloaded the OUI list!"
        Write-AuditLog -EndFunction
        return $ouiobject
    }
    catch {
        Write-Warning "List not downloaded. Continuing with local MACID OUI list." -WarningAction Continue
        $ouiobject = Import-Csv source\assets\oui.csv
        write-auditlog -message "Successfully imported the local OUI list!"
        Write-AuditLog -EndFunction
    }
}
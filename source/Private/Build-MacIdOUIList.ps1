function Build-MacIdOUIList {
    Write-AuditLog -Message "Retrieving MACID OUI list from https://standards-oui.ieee.org/oui/oui.csv"
    try {
        $ouiobject = Invoke-RestMethod https://standards-oui.ieee.org/oui/oui.csv | ConvertFrom-Csv -ErrorAction Stop
        Write-AuditLog -Message "Successfully downloaded the OUI list!"
        return $ouiobject
    }
    catch {
        Write-Warning "List not downloaded. Continuing with local MACID OUI list." -WarningAction Continue
        $ouiobject = Import-Csv source\assets\oui.csv
    }
}
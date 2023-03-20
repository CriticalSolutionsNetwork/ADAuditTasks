function Group-UpdateByProduct {
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$AllUpdates,
        [string[]]$OSList
    )

    $Updates = @{}

    foreach ($OS in $OSList) {
        $Updates[$OS] = $AllUpdates | Where-Object { $_.Product -like "$OS*" }
    }

    return $Updates
}
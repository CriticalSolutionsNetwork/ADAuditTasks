function Request-DedupedObject {
    <#
    .SYNOPSIS
        Returns a deduplicated version of a CSV object based on
        a specified suspect property and filter property.
    .DESCRIPTION
        The `Request-DedupedObject` function takes in three parameters: the suspect property, the filter property, and a CSV object,
        and returns a deduplicated version of the CSV object. The function groups the CSV object by the suspect property,
        sorts each group by the filter property in descending order, and selects the first item from each group.
    .PARAMETER DupedPropertySuspect
        Specifies the name of the property to group the CSV object by. This parameter is required.
    .PARAMETER FilterProperty
        Specifies the name of the property to sort each group by. This parameter is required.
    .PARAMETER csv
        Specifies the CSV object to deduplicate. This parameter is required.
    .INPUTS
        DupedPropertySuspect: Specifies the name of the property to group the CSV object by.
        FilterProperty: Specifies the name of the property to sort each group by.
        csv: Specifies the CSV object to deduplicate.
    .OUTPUTS
        A deduplicated version of the CSV object.
    .EXAMPLE
        $csv = Import-Csv -Path C:\data.csv
        $deduplicated = Request-DedupedObject -DupedPropertySuspect "Name" -FilterProperty "Date" -csv $csv
        $deduplicated | Export-Csv -Path C:\deduplicated_data.csv -NoTypeInformation

        This example imports a CSV file, deduplicates it based on the "Name" property and the "Date" property, and exports the deduplicated data to a new CSV file.
    .NOTES
        Author: DrIOSx
        Date: 4/12/2023
        Version: 0.1.0
    #>
    [OutputType([PSObject[]])]
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [AllowEmptyCollection()]
        [PSObject[]]$csv,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$FilterProperty,
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$DupedPropertySuspect
    )
    begin {
        if (!($script:LogString)) {
            Write-AuditLog -Start
        }
        else {
            Write-AuditLog -BeginFunction
        }
        Write-AuditLog "Begin deduplication for $DupedPropertySuspect based on datetime filter $FilterProperty."
        if ($csv.Count -eq 0) {
            return [PSObject[]]@()
        }
        $sampleOutput = @()
        $random = New-Object Random
    }
    process {
        $grouped = $csv | Group-Object -Property $DupedPropertySuspect
        $progressCount = 0
        $startTime = Get-Date
        $deduped = foreach ($group in $grouped) {
            $progressCount++
            $elapsedTime = (Get-Date) - $startTime
            $timePerGroup = $elapsedTime.TotalSeconds / $progressCount
            $estimatedTimeRemaining = ($grouped.Count - $progressCount) * $timePerGroup

            # Update progress every 60 groups
            if ($progressCount % 60 -eq 0) {
                Write-Progress -Activity "Deduplicating CSV" -Status "Processing groups" -PercentComplete (($progressCount / $grouped.Count) * 100) -SecondsRemaining $estimatedTimeRemaining
            }

            if ($group.Count -eq 1) {
                $group.Group
            }
            else {
                $selectedRow = $group.Group | Sort-Object -Property $FilterProperty -Descending | Select-Object -First 1

                # Randomly select 5 samples
                if ($sampleOutput.Count -lt 5 -and ($random.Next(1, 100) -le 20)) {
                    $sample = New-Object PSObject -Property @{
                        Name     = $group.Name
                        Oldest   = $group.Group | Sort-Object $FilterProperty | Select-Object -First 1
                        Latest   = $group.Group | Sort-Object $FilterProperty -Descending | Select-Object -First 1
                        Selected = $selectedRow
                    }
                    $sampleOutput += $sample
                }
                $selectedRow
            }
        }
    }
    end {
        Write-AuditLog "##### Random Sample Comparisons #####"
        foreach ($sample in $sampleOutput) {
            Write-AuditLog "Name: $($sample.Name)"
            Write-AuditLog "Oldest: $($sample.Oldest.$FilterProperty)"
            Write-AuditLog "Latest: $($sample.Latest.$FilterProperty)"
            Write-AuditLog "Selected: $($sample.Selected.$FilterProperty)"
            Write-AuditLog "-----------------------------------"
        }
        Write-AuditLog "End deduplication for `"$DupedPropertySuspect`" based on datetime filter `"$FilterProperty`"."
        Write-AuditLog -EndFunction
        return $deduped
    }
}

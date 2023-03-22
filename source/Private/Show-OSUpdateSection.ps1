function Show-OSUpdateSection {
    param(
        $osUpdates
    )
    $sectionHtml = ""
    foreach ($os in $osUpdates) {
        $sectionHtml += @"
<h3>$($os.Title)</h3>

"@
        $groupedUpdates = $os.Updates | Group-Object -Property Article

        foreach ($group in $groupedUpdates) {
            $firstUpdate = $group.Group[0]
            $tableId = "table_" + (New-Guid).ToString()
            $arrowId = "arrow_" + (New-Guid).ToString()
            $sectionHtml += @"
<h4 onclick='toggleTable("$tableId", "$arrowId")' style='cursor:pointer;'><span id='$arrowId' class='arrow'>▶</span><span class='kb-number'>KB$($group.Name)</span> - Max Severity: $($firstUpdate.'Max Severity') - <a href='$($firstUpdate.ArticleUrl)' target='_parent'>Article URL</a> | Type: $($firstUpdate.Download) - <a href='$($firstUpdate.'Download Url')' target='_parent'>Download URL</a></h4>
<table id='$tableId' style='display:none;'>
<tr>
    <th onclick='onHeaderClick("$tableId", 0)'>Release Date</th>
    <th onclick='onHeaderClick("$tableId", 1)'>Impact</th>
    <th onclick='onHeaderClick("$tableId", 2)'>Build Number</th>
    <th onclick='onHeaderClick("$tableId", 3)'>Details</th>
    <th onclick='onHeaderClick("$tableId", 4)'>Details URL</th>
    <th onclick='onHeaderClick("$tableId", 5)'>Base Score</th>
</tr>
"@

            foreach ($update in $group.Group) {
                $sectionHtml += @"
<tr>
    <td>$($update.'Release Date')</td>
    <td>$($update.Impact)</td>
    <td>$($update.'Build Number')</td>
    <td>$($update.Details)</td>
    <td><a href='$($update.'Details Url' -replace "(?<=https://)(.*)//", '$1/')' target='_parent'>Link</a></td>
    <td>$($update.'Base Score')</td>
</tr>
"@
            }

            $sectionHtml += @"
</table>
"@
        }
    }
    return $sectionHtml
}
<#
.SYNOPSIS
    Generates HTML code for displaying OS updates in a collapsible table format.

.DESCRIPTION
    This function takes an array of OS update objects and generates HTML code to display them in a collapsible table format.

.PARAMETER osUpdates
    An array of OS update objects. Each OS update object must have a 'Title' property and an 'Updates' property, where 'Updates' is an array of update objects with the following properties:
    - 'Article': The KB article number of the update.
    - 'Max Severity': The maximum severity of the update.
    - 'ArticleUrl': The URL of the KB article.
    - 'Download': The type of download (e.g. 'Security Update').
    - 'Download Url': The URL of the download.
    - 'Release Date': The release date of the update.
    - 'Impact': The impact of the update.
    - 'Build Number': The build number of the update.
    - 'Details': A description of the update.
    - 'Details Url': The URL of the details page.

.OUTPUTS
    System.String
    The generated HTML code for displaying the OS updates in a collapsible table format.

.EXAMPLE
    $osUpdates = @(
        @{
            Title = "Windows 10, version 21H1"
            Updates = @(
                @{
                    Article = "KB5001330"
                    'Max Severity' = "Critical"
                    ArticleUrl = "https://support.microsoft.com/en-us/topic/kb5001330-cumulative-update-preview-for-windows-10-version-21h1-april-20-2021-57a87a06-64de-45e7-9d3b-6b8a58a00bc6"
                    Download = "Security Update"
                    'Download Url' = "https://www.microsoft.com/download/details.aspx?id=12345"
                    'Release Date' = "04/20/2021"
                    Impact = "Remote Code Execution"
                    'Build Number' = "19043.928"
                    Details = "This update fixes a vulnerability in blah blah blah."
                    'Details Url' = "https://support.microsoft.com/en-us/topic/kb5001330-cumulative-update-preview-for-windows-10-version-21h1-april-20-2021-57a87a06-64de-45e7-9d3b-6b8a58a00bc6"
                }
            )
        }
    )
    Show-OSUpdateSection -osUpdates $osUpdates

.NOTES
    Author: DrIOSx
#>
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
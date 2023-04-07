function New-PatchTuesdayReport {
    <#
    .SYNOPSIS
    Generates a Patch Tuesday report HTML file based on a CSV input file.
    .DESCRIPTION
    The function generates an HTML report file with the latest Microsoft updates released on Patch Tuesday. The report file includes separate sections for client and server operating systems.

    To use this function, follow these steps:

    Go to the Microsoft Security Response Center website at https://msrc.microsoft.com/update-guide.
    Select the appropriate filters to display the updates you want to include in the report. For example, select the following options:
        Product:
        Windows Server 2022, Windows Server 2019, Windows Server 2016, Windows Server 2012 R2, Windows 11 Version 22H2 for x64-based Systems, Windows 10 Version 22H2 for x64-based Systems.
        Severity: Critical
        Release Date: Last 30 days
    Click on "Download all as CSV" to download the updates as a CSV file.
    The function will import the CSV file with the appropriate headers:
        Import-Csv -Path $Path -Header 'Release Date','Product','Platform','Impact','Max Severity','Article','ArticleUrl','Download','Download Url','Build Number','Details','Details Url','Base Score'
    Use the New-PatchTuesdayReport function to generate the HTML report file.
    Future updates will include options to specify the parameters.
    .PARAMETER CsvPath
    The path to the CSV input file containing the Microsoft update information.
    .PARAMETER DateId
    A string value used to identify the date of the Patch Tuesday report.
    .PARAMETER LogoUrl
    A string value representing the URL of the logo to be displayed in the report.
    .PARAMETER ImportHeaderAs
    An array of strings representing the header row of the CSV input file.
    .PARAMETER OSList
    An array of strings representing the list of operating systems to include in the report.
    .EXAMPLE
    PS C:> New-PatchTuesdayReport -CsvPath "C:\updates.csv" -DateId "2022-Oct" -LogoUrl "https://example.com/logo.png" -OSList @("Windows Server 2012 R2", "Windows Server 2016", "Windows Server 2019", "Windows Server 2022", "Windows 11", "Windows 10")

    This example generates a Patch Tuesday report for October 2022 with updates for Windows Server 2012 R2, Windows Server 2016, Windows Server 2019, Windows Server 2022, Windows 11, and Windows 10 operating systems. The report includes a logo displayed at the top of the report.
    .INPUTS
    None.
    .OUTPUTS
    A string value containing the HTML code for the Patch Tuesday report.

    .NOTES
    None.
    #>

    [CmdletBinding(HelpURI = "https://criticalsolutionsnetwork.github.io/ADAuditTasks/#New-PatchTuesdayReport")]
    param(
        [ValidateNotNull()]
        [string]$CsvPath,
        [ValidateNotNull()]
        [string]$DateId,
        [string]$LogoUrl,
        [string[]]$ImportHeaderAs = @("Release Date", "Product", "Platform", "Impact", "Max Severity", "Article", "ArticleUrl", "Download", "Download Url", "Build Number", "Details", "Details Url", "Base Score"),
        [string[]]$OSList = @('Windows Server 2012 R2', 'Windows Server 2016', 'Windows Server 2019', 'Windows Server 2022', 'Windows 11', 'Windows 10')
    )
    begin {
        $AllUpdates = Import-Csv -Path $CsvPath -Header $ImportHeaderAs
        $Updates = Group-UpdateByProduct -AllUpdates $AllUpdates -OSList $OSList
        # Read CSS, JavaScript, and HTML template
        $moduleBase = (Get-Module ADAuditTasks).ModuleBase
        $assetsPath = Join-Path $moduleBase "assets"
        $cssContent = Read-FileContent -FilePath (Join-Path $assetsPath "styles.css")
        $jsContent = Read-FileContent -FilePath (Join-Path $assetsPath "scripts.js")
        $htmlTemplate = Read-FileContent -FilePath (Join-Path $assetsPath "template.html")
        # Replace placeholders in the HTML template with the CSS and JavaScript content
        $htmlTemplate = $htmlTemplate -replace '/\* CSS-PLACEHOLDER \*/', $cssContent
        $htmlTemplate = $htmlTemplate -replace '/\* JS-PLACEHOLDER \*/', $jsContent
    }
    Process {
        # Generate the report content using the HTML template
        $html = $htmlTemplate -replace "<!--LOGO-URL-PLACEHOLDER-->", $LogoUrl -replace "<!--DATE-ID-PLACEHOLDER-->", $DateId
        $clientOSList = @('Windows 11', 'Windows 10')
        $serverOSList = $OSList | Where-Object { $_ -notin $clientOSList }
        $clientUpdates = $clientOSList | ForEach-Object {
            @{
                'Title'   = "$_ Updates";
                'Updates' = $Updates[$_]
            }
        }
        $serverUpdates = $serverOSList | ForEach-Object {
            @{
                'Title'   = "$_ Updates";
                'Updates' = $Updates[$_]
            }
        }
        $clientUpdatesHtml = Show-OSUpdateSection $clientUpdates
        $serverUpdatesHtml = Show-OSUpdateSection $serverUpdates
        $html = $html -replace "<!--CLIENT-UPDATES-PLACEHOLDER-->", $clientUpdatesHtml
        $html = $html -replace "<!--SERVER-UPDATES-PLACEHOLDER-->", $serverUpdatesHtml
    }
    End {
        return $html
    }
}

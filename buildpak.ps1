function Build-TestBuildFunc {
    Remove-Module ADAuditTasks
    Remove-Item .\output\ADAuditTasks -Recurse
    Remove-Item ".\output\ADAuditTasks.*.nupkg"
    Remove-Item .\output\ReleaseNotes.md
    Remove-Item .\output\CHANGELOG.md
    .\build.ps1 -tasks build -CodeCoverageThreshold 0
}
function Build-Docs {
    Import-Module .\output\ADAuditTasks\*\*.psd1
    .\ModdedModules\psDoc-master\src\psDoc.ps1 -moduleName ADAuditTasks -outputDir docs -template ".\ModdedModules\psDoc-master\src\out-html-template.ps1"
}
Build-TestBuildFunc
Build-Docs


$workstations       = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
$servers            = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
$nonWindows         = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
$activeUsers        = Get-ADActiveUserAudit -Report -Verbose
$privilegedUsers    = Get-ADUserPrivilegeAudit -Report -Verbose
$wildcardUsers      = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
$netaudit           = Get-NetworkAudit -LocalSubnets -NoHops -AddService -Report -Verbose
Merge-ADAuditZip -FilePaths  $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers,$netaudit -OpenDirectory -Verbose

$netaudit           = Get-NetworkAudit -LocalSubnets -Report -Verbose

$script = {Get-NetworkAudit -LocalSubnets -NoHops -Report -Verbose}
$script2 = {Get-NetworkAudit -LocalSubnets -Report -ThrottleLimit 320 -Verbose}
Measure-Command -Expression $script -Verbose
Measure-Command -Expression $script2 -Verbose

Merge-ADAuditZip -FilePaths $netaudit -OpenDirectory



Get-NetworkAudit -Ports 443 -Computers $test1 -Verbose
Get-NetworkAudit -Ports 443 -Computers $test1 -Report
Get-NetworkAudit -Ports 443 -Computers $test1 -NoHops -AddService
Get-NetworkAudit -Ports 443 -Computers $test1 -Report -NoHops -AddService


# .\build.ps1 -tasks build, pack, publish -CodeCoverageThreshold 0
# .\build.ps1 -tasks Build, Test -CodeCoverageThreshold 0
# .\build.ps1 -BuildConfig .\.git
# .\build.ps1 -ResolveDependency -tasks noop
# .\build.ps1 -tasks build -CodeCoverageThreshold 0

<#
1. Merge the pull request that contains the code documentation and comments.
2. Switch to the main branch in your local repository using `git checkout main`.
3. Pull the latest changes from the remote repository using `git pull origin main`.
4. Verify that the module works as expected by importing it into a PowerShell session and running the cmdlets.
5. Tag the main branch with the version number 0.1.7 using `git tag -a v0.1.7 -m "Release version 0.1.7"`.
6. Push the tag to the remote repository using `git push origin v0.1.7`.
7. Run the build using the pack task to create the NuGet package: `.\build.ps1 -tasks pack -CodeCoverageThreshold 0`.
8. Upload the NuGet package to the PowerShell Gallery using the publish task: `.\build.ps1 -tasks publish -CodeCoverageThreshold 0`.
#>

<#
$ver = "v0.3.8"
git checkout main
git pull origin main
git tag -a $ver -m "Release version $ver Update"
git push origin $ver
"Fix: PR #37"
git push origin $ver
# git tag -d $ver
#>

# https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv



$CsvPath = "C:\Users\$User\Downloads\Security Updates 2023-03-17-063046pm.csv"
# Generate email content
$HTMLReport = New-PatchTuesdayReport -csvpath $CsvPath -DateId "2023-Mar" -LogoUrl $logo -Verbose
$HTMLReport | Out-File C:\temp\reports.html
Start-Process C:\temp\reports.html

Get-HostTag -PhysicalOrVirtual Physical -Prefix "NY" -SystemOS 'Windows Server' -DeviceFunction 'Directory Server' -HostCount 5
Get-ADUserLogonAudit -SamAccountName "<USERNAME>" -Verbose
Get-NetworkAudit -LocalSubnets -Report -Verbose
Get-NetworkAudit -LocalSubnets -NoHops -AddService -Report -Verbose

$workstations
$servers
$nonWindows
$activeUsers
$privilegedUsers
$wildcardUsers
$netaudit

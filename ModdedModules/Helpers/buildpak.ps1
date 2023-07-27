function Build-TestBuildFunc {
    Remove-Module ADAuditTasks
    Remove-Item .\output\ADAuditTasks -Recurse
    Remove-Item ".\output\module\ADAuditTasks.*.nupkg"
    Remove-Item .\output\ReleaseNotes.md
    Remove-Item .\output\CHANGELOG.md
    .\build.ps1 -tasks build -CodeCoverageThreshold 0
}
function Build-Docs {
    Import-Module .\output\module\ADAuditTasks\*\*.psd1
    .\ModdedModules\psDoc-master\src\psDoc.ps1 -moduleName ADAuditTasks -outputDir docs -template ".\ModdedModules\psDoc-master\src\out-html-template.ps1"
}
Build-TestBuildFunc
Build-Docs
.\build.ps1 -tasks build, test -CodeCoverageThreshold 0

<#

#>

$workstations       = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
$servers            = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
$nonWindows         = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
$activeUsers        = Get-ADActiveUserAudit -Report -Verbose
$privilegedUsers    = Get-ADUserPrivilegeAudit -Report -Verbose
$wildcardUsers      = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
$netaudit           = Get-NetworkAudit -LocalSubnets -AddService -Report -Verbose
Merge-ADAuditZip -FilePaths  $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers, $netaudit -OpenDirectory -Verbose

$netaudit = Get-NetworkAudit -LocalSubnets -Report -Verbose

$script     = { Get-NetworkAudit -LocalSubnets -NoHops -Report -Verbose }
$script2    = { Get-NetworkAudit -LocalSubnets -Report -ThrottleLimit 320 -Verbose }
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
    $ver = "v0.7.5"
    git checkout main
    git pull origin main
    git tag -a $ver -m "Release version $ver fix"
    git push origin $ver
    "Fix: PR #37"
    git push origin $ver
    # git tag -d $ver
#>

# https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.csv



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


#######################################################################################
################################### 1. Build Module ###################################
#######################################################################################

# TODO: PIPE out task path in sampler

#######################################################################################
################################## Sign Module ########################################
#######################################################################################
<#
    # Install Secret Management
    # Install-Module -Name "Microsoft.PowerShell.SecretManagement", `
    # "SecretManagement.JustinGrote.CredMan" -Scope CurrentUser
    # Register-SecretVault -Name ADAuditTasks -ModuleName `
    # "SecretManagement.JustinGrote.CredMan" -ErrorAction Stop
    # Set-Secret -Name "CertPass" -Vault ADAuditTasks -ErrorAction Stop

    # Create a self-signed code signing certificate valid for 24 months
    # $cert = New-SelfSignedCertificate -CertStoreLocation "Cert:\CurrentUser\My" `
    # -Subject "CN=ADAuditTasks Code Signing Cert" -KeyExportPolicy Exportable `
    # -NotAfter (Get-Date).AddMonths(24) -Type CodeSigningCert

    # Export-PfxCertificate -Cert $cert `
    # -FilePath "ModdedModules\Helpers\Certs\ADAuditTasks.pfx" `
    # -Password (Get-Secret -Name "CertPass" -Vault ADAuditTasks)

    # Verify Authenticode
    # $Path = ".\TestSign.ps1"
    # Get-AuthenticodeSignature "output\module\ADAuditTasks\0.0.1\ADAuditTasks.psd1"
#>
#######################################################################################
################################ Functions ############################################
#######################################################################################
function Initialize-Signing {
    .\build.ps1 -tasks Sign_Module_Task
}
function Initialize-BuildFunc {
    Remove-Module ADAuditTasks
    Remove-Item .\output\module\ADAuditTasks -Recurse
    Remove-Item ".\output\module\ADAuditTasks.*.nupkg"
    Remove-Item .\output\ReleaseNotes.md
    Remove-Item .\output\CHANGELOG.md
    .\build.ps1 -tasks build -CodeCoverageThreshold 0
}
function Get-Doc {
    Import-Module ".\output\module\*\*\*.psd1"
    .\ModdedModules\psDoc-master\src\psDoc.ps1 -moduleName ADAuditTasks -outputDir docs -template ".\ModdedModules\psDoc-master\src\out-html-template.ps1"
}
function Initialize-Test {
    .\build.ps1 -tasks build, test
}
#######################################################################################
################################## Execution ##########################################
#######################################################################################
.\build.ps1 -tasks Sign_Module_Task, pack -CodeCoverageThreshold 0

#Initialize-BuildFunc
Initialize-Signing
Get-Doc
# Initialize-Test
<#
    #.\build.ps1 -tasks noop -ResolveDependency
    # Export Log to CSV
    # git log --pretty=format:'"%h","%an","%ad","%s"' --date=short | ConvertFrom-Csv `
    # | Export-Csv -Path 'commit_history.csv' -NoTypeInformation
    # $Branch = git branch --show-current
    # git checkout master
    # git merge $Branch
    # .\build.ps1 -tasks noop -ResolveDependency
    # .\build.ps1 -tasks build,test
    # .\build.ps1 -tasks build,test,pack
    # .\build.ps1 -tasks build,test,pack -CodeCoverageThreshold 0
#>


function New-PrivateFunctionTests {
    param (
        [string[]]$PrivateFunctions
    )

    $testDirectory = ".\tests\Unit\Private"

    foreach ($functionName in $PrivateFunctions) {
        $functionDirectory = $testDirectory
        $testFile = Join-Path -Path $functionDirectory -ChildPath "$functionName.tests.ps1"
        New-Item -Path $testFile -ItemType File | Out-Null
    }
}
$PrivateFunctions = @(
    "Build-ADAuditTasksComputer",
    "Build-ADAuditTasksUser",
    "Build-MacIdOUIList",
    "Build-NetScanObject",
    "Build-ReportArchive",
    "Get-AdExtendedRight",
    "Get-ADGroupMemberof",
    "Group-UpdateByProduct",
    "Initialize-DirectoryPath",
    "Initialize-ModuleEnv",
    "Install-ADModule",
    "Read-FileContent",
    "Request-DedupedObject",
    "Show-OSUpdateSection",
    "Test-IsAdmin",
    "Write-AuditLog"
)
New-PrivateFunctionTests -PrivateFunctions $PrivateFunctions
function New-MissingPublicTestFiles {
    $publicTestsPath = '.\tests\Unit\Public'
    $publicFunctions = Get-ChildItem -Path ".\source\Public" -File -Name
    foreach ($publicFunction in $publicFunctions) {
        $testFileName = "Test-$publicFunction"
        $testFilePath = Join-Path $publicTestsPath $testFileName
        if (!(Test-Path $testFilePath)) {
            New-Item -ItemType File -Path $testFilePath -Value "" | Out-Null
            Write-Host "Created missing test file: $testFileName"
        }
    }
}
New-MissingPublicTestFiles
function New-MissingPublicTestFiles {
    $projectPath = ".\" | Convert-Path
    $publicTestPath = Join-Path $projectPath 'tests\Unit\Public'
    $publicFunctionPath = Join-Path $projectPath 'source\Public'

    $publicFunctions = Get-ChildItem $publicFunctionPath -Filter *.ps1
    $publicTests = Get-ChildItem $publicTestPath -Filter *.tests.ps1

    foreach ($functionFile in $publicFunctions) {
        $testFilename = Join-Path $publicTestPath ($functionFile.BaseName + '.tests.ps1')

        if (!(Test-Path $testFilename)) {
            $testContent = @"
`$ProjectPath = `"$PSScriptRoot\..\..\..`" | Convert-Path
`$ProjectName = ((Get-ChildItem -Path `$ProjectPath\*\*.psd1).Where{
        (`$_.Directory.Name -match 'source|src' -or `$_.Directory.Name -eq `$_.BaseName) -and
        `$(
            try {
                Test-ModuleManifest `$_.FullName -ErrorAction Stop
            } catch {
                `$false
            }
        )
    }).BaseName


Import-Module `$ProjectName

InModuleScope `$ProjectName {
    Describe $($functionFile.BaseName) {
        It `"Should exist`" {
            Test-Path function:\$($functionFile.BaseName) | Should Be `$true
        }
    }
}
"@
            Out-File -FilePath $testFilename -Encoding utf8 -InputObject $testContent
            Write-Output "Created missing test file $($testFilename)"
        }
    }
}
function New-MissingTestFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Private', 'Public')]
        [string]$FunctionType
    )

    $projectPath = ".\" | Convert-Path
    $testPath = Join-Path $projectPath "tests\Unit\$FunctionType"
    $functionPath = Join-Path $projectPath "source\$FunctionType"

    $functions = Get-ChildItem $functionPath -Filter *.ps1
    $tests = Get-ChildItem $testPath -Filter *.tests.ps1

    foreach ($function in $functions) {
        $testFilename = Join-Path $testPath ($function.BaseName + '.tests.ps1')

        if (!(Test-Path $testFilename)) {
            $testContent = @"
                `$ProjectPath = `"$PSScriptRoot\..\..\..`" | Convert-Path
                `$ProjectName = ((Get-ChildItem -Path `$ProjectPath\*\*.psd1).Where{
                        (`$_.Directory.Name -match 'source|src' -or `$_.Directory.Name -eq `$_.BaseName) -and
                        `$(
                            try {
                                Test-ModuleManifest `$_.FullName -ErrorAction Stop
                            } catch {
                                `$false
                            }
                        )
                    }).BaseName


                Import-Module `$ProjectName

                InModuleScope `$ProjectName {
                    Describe $($function.BaseName) {
                        It `"Should exist`" {
                            Test-Path function:\$($function.BaseName) | Should Be `$true
                        }
                    }
                }
"@
            Out-File -FilePath $testFilename -Encoding utf8 -InputObject $testContent
            Write-Output "Created missing test file $($testFilename)"
        }
    }
}
New-MissingTestFiles -FunctionType 'Private'

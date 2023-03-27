# Changelog for ADAuditTasks

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Added option for throttle limit to network audit. 
- Added powershellget installation to module installer. 

## [0.3.7] - 2023-03-23

### Added

- Throttle Limit to `Get-NetworkAudit`.

### Fixed

- Fix confirm preference IP output that was going off screen.
- Fix `Initialize-ModuleEnv` so that it installs latest powershell get and adds TLS to the session.
- Fix `Initialize-ModuleEnv` so that it only sets the `$script:MaximumFunctionCount = 8192` at the script scope instead of globally.

## [0.3.7] - 2023-03-23

### Added

- Added option to confirm scan if `-NoHops` selected in `Get-NetworkAudit`.
- Added progress bar to `Get-QuickPing`.
<<<<<<< HEAD
## [0.3.6] - 2023-03-22


=======
>>>>>>> 3be1b7c0850da557fe482f7d0d8f568e594dd67e
## [0.3.6] - 2023-03-22

### Added

- Added option to scan local subnets without a hop.
- Added public function `Get-QuickPing`
- Added additional logging to `Merge-ADAuditZip` function.

### Fixed

- Fixed subnet calculation in `Get-NetworkAudit`.
- Fixed `Build-NetScanObject` so `$NetworkAudit` is replaced with `$NetSCanObject` in `switch ($IncludeNoPing)`
- Fixed `Build-NetScanObject` so output columns are port numbers without the word "Port "


## [0.3.5] - 2023-03-19

### Added

- Added public function Get-WebCert. #40
- Added public function New-GraphEmailApp. #38
- Added public function Send-GraphAppEmail. #39
- Added public function New-PatchTuesdayReport. #42
- Added private function Group-UpdateByProduct. #42
- Added private function Read-FileContent. #42
- Added private function Show-OSUpdateSection. #42

## [0.3.4] - 2023-03-15

### Fixed

- Fixed missing comment help block in `Get-ADHostAudit`

## [0.3.3] - 2023-03-15

### Added

- Added private function `Build-DirectoryPath`.

## [0.3.2] - 2023-03-15

### Added

- Added private builder function for `ADAuditTasksComputer` class [#30](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/issues/30).
- Created tester function called `New-RandomFiles` to assist with testing the `Merge-ADAudit` function.[#32](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/issues/32)
- Added private builder function for NetScan, and MacID OUI List objects. [#28](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/issues/28)

# Fixed

- Fixed `Merge-ADAudit` function's creation of file parts for files over default 25MB size. [#32](https://github.com/CriticalSolutionsNetwork/ADAuditTasks/issues/32)

## [0.3.1] - 2023-03-13

### Added

- Added private function `Build-ADAuditTasksUser` for ADAuditTasksUser Class.
- Integrated new private function into `Get-ADActiveUserAudit` and `Get-ADUserWildCardAudit`

## [0.3.0] - 2023-03-12

### Changed

- Changed public functions `Get-NetworkAudit` and `Send-AuditEmail` to incorporate private function `Initialize-ModuleEnv`
- Changed public functions `Get-ADActiveUserAudit`, `Get-ADHostAudit`,`Get-ADUserLogonAudit`,`Get-ADUserPrivilegeAudit`,`Get-ADUserPrivilegeAudit`, and `Get-ADUserWildCardAudit` to incorporate private function `Install-ADModule`
- Changed `Write-AUditLog` variable to `$LogString`. 

### Fixed

- Fixed error output in `Get-NetworkAudit`

## [0.2.0] - 2023-02-21

### Added

- Successfully ran the following PowerShell script to collect and merge audit reports from an Active Directory domain:

    ```powershell
    $workstations = Get-ADHostAudit -HostType WindowsWorkstations -Report -Verbose
    $servers = Get-ADHostAudit -HostType WindowsServers -Report -Verbose
    $nonWindows = Get-ADHostAudit -HostType "Non-Windows" -Report -Verbose
    $activeUsers = Get-ADActiveUserAudit -Report -Verbose
    $privilegedUsers = Get-ADUserPrivilegeAudit -Report -Verbose
    $wildcardUsers = Get-ADUserWildCardAudit -WildCardIdentifier "svc" -Report -Verbose
    Merge-ADAuditZip -FilePaths $workstations, $servers, $nonWindows, $activeUsers, $privilegedUsers, $wildcardUsers -OpenDirectory
    ```

- Added support for splitting large ZIP files into multiple parts in Merge-ADAuditZip
- Added new parameter -OpenDirectory to Merge-ADAuditZip for opening the output directory after merging files
- Added comment blocks to Merge-ADAuditZip

### Changed

- Improved error handling and logging in Merge-ADAuditZip
- Renamed output file for Merge-ADAuditZip to include timestamp and domain name
- Updated examples and usage information in Merge-ADAuditZip documentation

### Fixed

- Fixed issue with Merge-ADAuditZip where blank output files would prevent zipping remaining files


## [0.1.7] - 2023-02-21

### Added

- Added comments and help blocks to various functions
- Added `Submit-FTPUpload` as public function
- Modified `Get-ADHostAudit` to fix multiple string output

### Changed

- Updated documentation to include examples and usage information

### Fixed

- Fixed error handling in `Get-ADHostAudit` for blank output
- Fixed several bugs related to incorrect variable naming and parameter types


## [0.1.6] - 2023-02-20

### Added

- Added comment help block to `Get-ADUserLogonAudit`
## [0.1.5] - 2023-02-20

### Added

- Added function `Merge-ADAuditZip` as a public function.

## [0.1.4] - 2023-02-20

### Fix

- Fixed multiple string output in `Get-ADHostAudit`

## [0.1.3] - 2023-02-13

### Added

- Added option to error handling for blank output for `Get-ADHostAudit`.
- Added line comments to `Get-ADHostAudit`

### Removed
- Removed hash output file for `Get-ADHostAudit`,`Get-ADUserPrivilegeAudit`, and `Get-ADUserWIldCardAudit`

### Removed
- Removed hash output file for `Get-ADHostAudit`,`Get-ADUserPrivilegeAudit`, and `Get-ADUserWIldCardAudit`
## [0.1.2] - 2023-01-06

### Fix

- Fixed documentation

## [0.1.0] - 2023-01-06

### Added

- Added Classes `1.ADAuditTasksUser`
- Added Classes `2.ADAuditTasksComputer`
- Added Public Function `Get-ADActiveUserAudit`
- Added Public Function `Get-ADHostAudit`
- Added Public Function `Get-ADUserLogonAudit`
- Added Public Function `Get-ADUserPrivilegeAudit`
- Added Public Function `Get-ADUserWildCardAudit`
- Added Public Function `Get-HostTag`
- Added Public Function `Get-NetworkAudit`
- Added Public Function `Send-AuditEmail`
- Added Private Function `Build-ReportArchive`
- Added Private Function `Get-ADExtendedRight`
- Added Private Function `Get-ADGroupMemberof`
- Added Private Function `Submit-FTPUpload`
- Added Private Function `Test-IsAdmin`
- Added Private Function `Write-ADAuditLog`

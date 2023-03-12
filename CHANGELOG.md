# Changelog for ADAuditTasks

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2023-03-12

### Changed

- Changed public functions `Get-NetworkAudit` and `Send-AuditEmail` to incorporate private function `Initialize-ModuleEnv`
- Changed public functions `Get-ADActiveUserAudit`, `Get-ADHostAudit`,`Get-ADUserLogonAudit`,`Get-ADUserPrivilegeAudit`,`Get-ADUserPrivilegeAudit`, and `Get-ADUserWildCardAudit` to incorporate private function `Install-ADModule`
- Changed `Write-AUditLog` variable to `$LogString`. 

### Fixed

- Fixed error output in `Get-NetworkAudit`
## [0.2.1] - 2023-03-11

### Added

- Added Private Functions `New-GraphEmailApp` and `Send-GraphAppEmail`. Further work needed.
- Added Private Functions `Initialize-ModuleEnv` and `Install-ADModule` for future use.
- Added test structure and sample tests.
- Added pipe to `Out-Null` for directory creation in order to preserve output.

### Fixed

- Fixed multiple function outputs when output directories are created during the run.
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
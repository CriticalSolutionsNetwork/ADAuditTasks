# Changelog for ADAuditTasks

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
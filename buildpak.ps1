Remove-Module ADAuditTasks
Remove-Item .\output\ADAuditTasks -Recurse
Remove-Item ".\output\ADAuditTasks.*.nupkg"
Remove-Item .\output\ReleaseNotes.md
Remove-Item .\output\CHANGELOG.md
.\build.ps1 -tasks build -CodeCoverageThreshold 0
Remove-Item C:\temp\ADDS* -Recurse

.\build.ps1 -ResolveDependency -tasks noop

.\build.ps1 -tasks build -CodeCoverageThreshold 0



# Update Changelog
# Update Manifest from Previous Module
# git tag -a v1.0.0 -m "v1.0.0 Release"
# git tag -a v0.0.2 -m "v0.0.1 Release"
# Build / Test
# Add Api Variables to session.
# Build / Publish

.\build.ps1 -tasks build,pack,publish -CodeCoverageThreshold 0
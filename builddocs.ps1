Import-Module .\output\module\ADAuditTasks\*\*.psd1
.\ModdedModules\psDoc-master\src\psDoc.ps1 -moduleName ADAuditTasks -outputDir docs -template ".\ModdedModules\psDoc-master\src\out-html-template.ps1"
.\ModdedModules\psDoc-master\src\psDoc.ps1 -moduleName ADAuditTasks -outputDir ".\" -template ".\ModdedModules\psDoc-master\src\out-markdown-template.ps1" -fileName ".\README copy.md"
# SignModule.ib.tasks.ps1
# .build/SignModule/0.0.1/tasks/Sign_Module.build.ps1

task Sign_Module_Files {
    # Retrieve the certificate password from the secret vault
    $certPassword = Get-Secret -Name "CertPass" -Vault ADAuditTasks
    # Import the PFX certificate
    $certPath = ".\ModdedModules\Helpers\Certs\ADAuditTasks.pfx"
    $cert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\My" -Password $certPassword
    # Sign the module files
    $modulePath = "output\module\ADAuditTasks"
    $moduleFiles = Get-ChildItem -Path $modulePath -Recurse -Include "*.ps1", "*.psm1", "*.psd1"
    foreach ($file in $moduleFiles) {
        Set-AuthenticodeSignature -Certificate $cert -FilePath $file.FullName -TimestampServer "http://timestamp.digicert.com"
    }
    # Get the module version dynamically from the psd1 file
    $manifest = Get-ChildItem -Path $modulePath -Recurse -Filter "*.psd1" | Select-Object -First 1
    $manifestContent = Import-PowerShellDataFile -Path $manifest.FullName
    $moduleVersion = $manifestContent.ModuleVersion
    $versionPath = Join-Path -Path $modulePath -ChildPath $moduleVersion
    # Create the catalog file
    $catalogPath = Join-Path -Path $versionPath -ChildPath "ADAuditTasks.cat"
    New-FileCatalog -Path $versionPath -CatalogFilePath $catalogPath -CatalogVersion 2.0 -Verbose
    # Sign the catalog file
    Set-AuthenticodeSignature -Certificate $cert -FilePath $catalogPath -TimestampServer "http://timestamp.digicert.com"
    # Test the catalog file
    Test-FileCatalog -Path $versionPath -CatalogFilePath $catalogPath -Detailed
}

task Sign_Module {
    # Retrieve the certificate password from the secret vault
    $certPassword = Get-Secret -Name "CertPass" -Vault ADAuditTasks
    # Import the PFX certificate
    $certPath = Join-Path $PSScriptRoots "helpers\SignModule\Certs\ADAuditTasks.pfx"
    $cert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\My" -Password $certPassword
    # Sign the module files
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "output\ADAuditTasks"
    $moduleFiles = Get-ChildItem -Path $modulePath -Recurse -Include "*.ps1", "*.psm1", "*.psd1"
    foreach ($file in $moduleFiles) {
        Set-AuthenticodeSignature -Certificate $cert -FilePath $file.FullName -TimestampServer "http://timestamp.digicert.com"
    }
    # Create the catalog file
    $catalogPath = Join-Path -Path $modulePath -ChildPath "ADAuditTasks.cat"
    New-FileCatalog -Path $modulePath -CatalogFilePath $catalogPath -CatalogVersion 2.0 -Verbose
    # Sign the catalog file
    Set-AuthenticodeSignature -Certificate $cert -FilePath $catalogPath -TimestampServer "http://timestamp.digicert.com"
    # Test the catalog file
    Test-FileCatalog -Path $modulePath -CatalogFilePath $catalogPath -Detailed
}

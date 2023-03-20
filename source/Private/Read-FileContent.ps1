function Read-FileContent {
    param(
        [string]$FilePath
    )
    return (Get-Content -Path $FilePath -Raw)
}
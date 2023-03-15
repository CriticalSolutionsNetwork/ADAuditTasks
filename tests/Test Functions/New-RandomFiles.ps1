function New-RandomFiles {
    param(
        [int]$TotalSize = 25MB,
        [int]$MinFileSize = 1MB,
        [int]$MaxFileSize = 5MB,
        [string]$OutputFolder = "C:\temp\RandomFiles"
    )

    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -ItemType Directory $OutputFolder -Force | Out-Null
    }

    if ($MinFileSize -ge $MaxFileSize) {
        Write-Host "Minimum file size cannot be greater than or equal to the maximum file size."
        return
    }

    $remainingSize = $TotalSize
    $fileCounter = 1

    while ($remainingSize -gt 0) {
        $currentFileSize = Get-Random -Minimum $MinFileSize -Maximum ($MaxFileSize + 1)

        if ($currentFileSize -gt $remainingSize) {
            $currentFileSize = $remainingSize
        }

        $fileName = "RandomFile_{0}.txt" -f $fileCounter
        $filePath = Join-Path $OutputFolder $fileName

        $randomData = New-Object byte[] ($currentFileSize)
        $random = New-Object Random
        $random.NextBytes($randomData)

        [System.IO.File]::WriteAllBytes($filePath, $randomData)

        $remainingSize -= $currentFileSize
        $fileCounter++
    }

    Write-Host "Random files created in $OutputFolder"
}

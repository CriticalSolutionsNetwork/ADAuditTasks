function Build-TestFiles {
	[cmdletbinding()]
	param(
		[Parameter(mandatory = $true)]$NumFiles,
		[Parameter(mandatory = $true)][ValidateSet("Media", "Documents", "Binary", "All")]$FileType,
		[Parameter(mandatory = $true)]$Path,
		[Parameter(mandatory = $true)]$TotalSize
	)
	begin {
		Write-Verbose "Generating files..."
		$GeneratedFiles = @()
		function Generate-FileName {
			[CmdletBinding(SupportsShouldProcess = $true)]
			param()
			begin {
				$Extensions = @()
				switch ($FileType) {
					"Media" { $Extensions = ".avi", ".midi", ".mov", ".mp3", ".mp4", ".mpeg", ".mpeg2", ".mpeg3", ".mpg", ".ogg", ".ram", ".rm", ".wma", ".wmv" }
					"Documents" { $Extensions = ".docx", ".doc", ".xls", ".docx", ".doc", ".pdf", ".ppt", ".pptx", ".dot" }
					"Binary" { $Extensions = ".exe", ".msi", ".msu", ".iso" }
					"All" { $Extensions = ".exe", ".msi", ".msu", ".iso", ".avi", ".midi", ".mov", ".mp3", ".mp4", ".mpeg", ".mpeg2", ".mpeg3", ".mpg", ".ogg", ".ram", ".rm", ".wma", ".wmv", ".docx", ".doc", ".xls", ".docx", ".doc", ".pdf", ".ppt", ".pptx", ".dot" }
				}
				$extension = $null
			}
			process {
				Write-Verbose "Generating filename..."
				$extension = $Extensions | Get-Random
				Get-Verb | Select-Object verb | Get-Random -Count 2 | ForEach-Object { $Name += $_.verb }
				$FullName = $name + $extension
				Write-Verbose "Filename : $FullName"
			}
			end {
				return $FullName
			}
		}
	}
	process {
		$FileSize = $TotalSize / $NumFiles
		$FileSize = [Math]::Round($FileSize, 0)
		while ($TotalFileSize -lt $TotalSize) {
			$TotalFileSize = $TotalFileSize + $FileSize
			$FileName = Generate-FileName
			Write-Verbose "Filename: $filename"
			Write-Verbose "Filesize: $filesize"
			$FullPath = Join-Path $path -ChildPath $fileName
			Write-Verbose "Generating file : $FullPath of $Filesize"
			try {
				fsutil.exe file createnew $FullPath $FileSize | Out-Null
			}
			catch {
				$_
			}
			$FileCreated = ""
			$Properties = @{'FullPath' = $FullPath; 'Size' = $FileSize }
			$FileCreated = New-Object -TypeName psobject -Property $properties
			$GeneratedFiles += $FileCreated
			Write-Verbose "$($AllCreatedFilles) created $($FileCreated)"
		}
	}
	end {
		Write-Output $GeneratedFiles
	}

}
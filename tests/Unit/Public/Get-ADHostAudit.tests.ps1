BeforeAll {
    $script:moduleName = '<% $PLASTER_PARAM_ModuleName %>'

    # If the module is not found, run the build task 'noop'.
    if (-not (Get-Module -Name $script:moduleName -ListAvailable))
    {
        # Redirect all streams to $null, except the error stream (stream 2)
        & "$PSScriptRoot/../../build.ps1" -Tasks 'noop' 2>&1 4>&1 5>&1 6>&1 > $null
    }

    # Re-import the module using force to get any code changes between runs.
    Import-Module -Name $script:moduleName -Force -ErrorAction 'Stop'

    $PSDefaultParameterValues['InModuleScope:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Mock:ModuleName'] = $script:moduleName
    $PSDefaultParameterValues['Should:ModuleName'] = $script:moduleName
}

AfterAll {
    $PSDefaultParameterValues.Remove('Mock:ModuleName')
    $PSDefaultParameterValues.Remove('InModuleScope:ModuleName')
    $PSDefaultParameterValues.Remove('Should:ModuleName')

    Remove-Module -Name $script:moduleName
}

Describe 'Get-ADHostAudit' {
    Mock Get-ADComputer {
        return @(
            [PSCustomObject]@{Name = "Computer1"; DNSHostName = "computer1.domain.com"; Enabled = $true; IPv4Address = "10.0.0.1"; IPv6Address = "::1"; OperatingSystem = "Windows 10 Pro"; LastLogon = (Get-Date); LastSeen = (Get-Date); Created = (Get-Date); Modified = (Get-Date); Description = "Test Computer 1"; GroupMemberships = "Group1"; OrgUnit = "OU=Computers,DC=domain,DC=com"; KerberosEncryptionType = "AES256"; SPNs = "HTTP/computer1.domain.com";},
            [PSCustomObject]@{Name = "Computer2"; DNSHostName = "computer2.domain.com"; Enabled = $false; IPv4Address = "10.0.0.2"; IPv6Address = "::2"; OperatingSystem = "Windows Server 2016"; LastLogon = (Get-Date); LastSeen = (Get-Date); Created = (Get-Date); Modified = (Get-Date); Description = "Test Computer 2"; GroupMemberships = "Group2"; OrgUnit = "OU=Computers,DC=domain,DC=com"; KerberosEncryptionType = "AES128"; SPNs = "HTTP/computer2.domain.com";}
        )
    }

    It 'Returns AD computers of type WindowsServers' {
        $result = Get-ADHostAudit -HostType WindowsServers
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain "Computer2"
    }

    It 'Returns AD computers of type WindowsWorkstations' {
        $result = Get-ADHostAudit -HostType WindowsWorkstations
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain "Computer1"
    }

    It 'Returns AD computers of type Non-Windows' {
        $result = Get-ADHostAudit -HostType "Non-Windows"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -BeEmpty
    }

    It 'Returns AD computers with a specific OS type' {
        $result = Get-ADHostAudit -OSType "Windows 10 Pro"
        $result | Should -Not -BeNullOrEmpty
        $result | Should -Contain "Computer1"
    }

    It 'Exports a report to the specified directory' {
        $tempDir = New-Item -ItemType Directory -Path "$env:TEMP\TestDir" -Force
        $result = Get-ADHostAudit -HostType WindowsServers -Report -AttachmentFolderPath "$env:TEMP\TestDir"
        $result | Should -BeNullOrEmpty
        $csvPath = Join-Path -Path "$env:TEMP\TestDir" -ChildPath "*.csv"
        Test-Path $csvPath | Should -Be $true
        Remove-Item -Path "$env:TEMP\TestDir" -Force -Recurse
    }
}



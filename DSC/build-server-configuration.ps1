Configuration BuildServerConfiguration {
    param(
        [string]$AgentDownloadUrl,
        [string]$VSTSPAT,
        [string]$VSTSAccountName,
        [string]$PoolName,
        [string]$AgentNamePrefix,
        [Parameter(Mandatory = $false)]
        [string]$StoragePoolName = "DASstoragePool01",
        [Parameter(Mandatory = $false)]
        [string]$VirtualDiskName = "DASvirtualDisk01",
        [int]$AgentCount = 8
    )

    #$AgentCount = (Get-Disk).Count - 2  # Agent disks = Total disks - osDisk - Temp Disk
    $AgentDownloadPath = "D:/Downloads/Agent.zip"
    $AgentExtractPath = "D:/Downloads/Agent"
    $DriveLetters = 'FGHIJKLMNOPQSRTUVWXYZ'
    $VolumePrefix = "VirtualDisk"
    $VolumeSize = 40GB

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDisk, xPendingReboot, xNetworking, xPSDesiredStateConfiguration

    Node localhost {

        LocalConfigurationManager {
            RebootNodeIfNeeded = $True
            ConfigurationMode  = "ApplyOnly"
        }

        <#
         Feature section
         Start with disabling SMB 1
        #>

        WindowsFeature SMBv1 {
            Name   = "FS-SMB1"
            Ensure = "Absent"
        }

        # --- Use TLS 1.2
        Registry StrongCrypto1 {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework\v4.0.30319"
            ValueName = "SchUseStrongCrypto"
            ValueType = "Dword"
            ValueData = "00000001"
        }

        Registry StrongCrypto2 {
            Ensure    = "Present"
            Key       = "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319"
            ValueName = "SchUseStrongCrypto"
            ValueType = "Dword"
            ValueData = "00000001"
        }

        Script InstallAzureRMModule {
            SetScript  = {
                Install-Module AzureRM -RequiredVersion 6.4.0 -AllowClobber -Force -Scope AllUsers
            }
            TestScript = {
                $AzureRMInstalled = Get-Module AzureRM -ListAvailable
                if ($AzureRMInstalled) {
                    $InstalledMajor = ($AzureRMInstalled | Sort-Object Version)[0].Version.Major
                }
                return $AzureRMInstalled -and ($InstalledMajor -gt 4)
            }
            GetScript  = {
                return @()
            }
        }

        Script StoragePool {
            SetScript  = {
                New-StoragePool -FriendlyName $using:StoragePoolName -StorageSubSystemFriendlyName '*storage*' -PhysicalDisks (Get-PhysicalDisk -CanPool $True)
            }
            TestScript = {
                (Get-StoragePool -ErrorAction SilentlyContinue -FriendlyName $using:StoragePoolName).OperationalStatus -eq 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-StoragePool -FriendlyName $using:StoragePoolName).OperationalStatus -eq 'OK') { 'Present' } else { 'Absent' } }
            }
        }

        Script VirtualDisk {
            SetScript  = {
                $Disks = @(Get-StoragePool -FriendlyName $using:StoragePoolName -IsPrimordial $false | Get-PhysicalDisk)
                $DiskNum = $Disks.Count
                New-VirtualDisk -StoragePoolFriendlyName $using:StoragePoolName -FriendlyName $using:VirtualDiskName -ResiliencySettingName simple -NumberOfColumns $DiskNum -UseMaximumSize
            }
            TestScript = {
                (Get-VirtualDisk -ErrorAction SilentlyContinue -FriendlyName $using:VirtualDiskName).OperationalStatus -eq 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-VirtualDisk -FriendlyName $using:VirtualDiskName).OperationalStatus -eq 'OK') { 'Present' } else { 'Absent' } }
            }
            DependsOn  = "[Script]StoragePool"
        }

        Script FormatDisk {
            SetScript  = {
                $DriveLetters = $using:DriveLetters
                Get-VirtualDisk -FriendlyName $using:VirtualDiskName | Get-Disk | Initialize-Disk -Passthru

                for ($i = 0; $i -lt $using:AgentCount; $i++) {
                    Get-VirtualDisk -FriendlyName $using:VirtualDiskName | Get-Disk | New-Partition -DriveLetter $DriveLetters[$i] -Size $using:VolumeSize | Format-Volume -NewFileSystemLabel $using:VolumePrefix$i -AllocationUnitSize 64KB -FileSystem NTFS
                }

                #Force refresh drive cache
                $null = Get-PSDrive
            }
            TestScript = {
                for ($i = 0; $i -lt $using:AgentCount; $i++) {
                    if (  (Get-Volume -ErrorAction SilentlyContinue -FileSystemLabel $using:VolumePrefix$i).FileSystem -ne 'NTFS' ) {
                        return $false
                    }
                }
                return $true
            }
            GetScript  = {
                @{Ensure = if ((Get-Volume -filesystemlabel $using:VolumePrefix$i).FileSystem -eq 'NTFS') { 'Present' } else { 'Absent' } }
            }
            DependsOn  = "[Script]VirtualDisk"
        }

        xRemoteFile DownloadVSTSAgent {
            DestinationPath = $AgentDownloadPath
            Uri             = $AgentDownloadUrl
            DependsOn       = "[Script]FormatDisk"
        }

        xArchive ExtractVSTSAgent {
            Path        = $AgentDownloadPath
            Destination = $AgentExtractPath
            Ensure      = "Present"
            DependsOn   = "[xRemoteFile]DownloadVSTSAgent"
        }

        # --- Configure an agent on each disk
        $ConfigureAgentSetScript = {
            param(
                $DriveLetters,
                $i,
                $AgentExtractPath,
                $VSTSAccountName,
                $VSTSPAT,
                $PoolName,
                $AgentNamePrefix
            )

            if (!(Test-Path "$($DriveLetters[$i]):\agent")) {
                New-Item "$($DriveLetters[$i]):\agent" -Type Directory
            }

            Copy-Item -Path "$AgentExtractPath\*" -Destination "$($DriveLetters[$i]):\" -Recurse

            $args = @("--unattended", "--url", "https://$($VSTSAccountName).visualstudio.com", "--auth", "pat", "--token", "$($VSTSPAT)", "--pool",
                "$($PoolName)", "--agent", "$($AgentNamePrefix)-agent$($i)", "--acceptTeeEula", "--work", "$($DriveLetters[$i]):\agent", "--runAsService",
                "--noRestart")
            &"$($DriveLetters[$i]):\config.cmd" $args
        }

        for ($i = 0; $i -lt ($AgentCount); $i++) {
            if ($i -eq 0) {
                Script "ConfigureAgent$i" {
                    SetScript  = {
                        $ConfigureAgentSetScript = [Scriptblock]::Create($using:ConfigureAgentSetScript)
                        $Params = @{
                            DriveLetters     = $using:DriveLetters
                            i                = $using:i
                            AgentExtractPath = $using:AgentExtractPath
                            VSTSAccountName  = $using:VSTSAccountName
                            VSTSPAT          = $using:VSTSPAT
                            PoolName         = $using:PoolName
                            AgentNamePrefix  = $using:AgentNamePrefix
                        }
                        & $ConfigureAgentSetScript @Params
                    }
                    TestScript = {
                        $DriveLetters = $using:DriveLetters
                        return Test-Path "$($DriveLetters[$using:i]):\*"  # TODO: Improve
                    }
                    GetScript  = {
                        return @()
                    }
                    DependsOn  = "[xArchive]ExtractVSTSAgent"
                }
            }
            else {
                Script "ConfigureAgent$i" {
                    SetScript  = {
                        $ConfigureAgentSetScript = [Scriptblock]::Create($using:ConfigureAgentSetScript)
                        $Params = @{
                            DriveLetters     = $using:DriveLetters
                            i                = $using:i
                            AgentExtractPath = $using:AgentExtractPath
                            VSTSAccountName  = $using:VSTSAccountName
                            VSTSPAT          = $using:VSTSPAT
                            PoolName         = $using:PoolName
                            AgentNamePrefix  = $using:AgentNamePrefix
                        }
                        & $ConfigureAgentSetScript @Params
                    }
                    TestScript = {
                        $DriveLetters = $using:DriveLetters
                        return Test-Path "$($DriveLetters[$using:i]):\*"  # TODO: Improve
                    }
                    GetScript  = {
                        return @()
                    }
                    DependsOn  = "[Script]ConfigureAgent$($i-1)"
                }
            }
        }
    }
}

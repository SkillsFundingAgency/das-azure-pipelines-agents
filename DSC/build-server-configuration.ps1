Configuration BuildServerConfiguration {
    param(
        [string]$AgentDownloadUrl,
        [string]$VSTSPAT,
        [string]$VSTSAccountName,
        [string]$PoolName,
        [string]$AgentNamePrefix,
        [Parameter(Mandatory = $false)]
        [string]$storagePoolName = "DASstoragePool01",
        [Parameter(Mandatory = $false)]
        [string]$virtualDiskName = "DASvirtualDisk01",
        [int]$AgentCount = 10
    )

    #$AgentCount = (Get-Disk).Count - 2  # Agent disks = Total disks - osDisk - Temp Disk
    $AgentDownloadPath = "D:/Downloads/Agent.zip"
    $AgentExtractPath = "D:/Downloads/Agent"
    $DriveLetters = 'FGHIJKLMNOPQSRTUVWXYZ'
    $volumePrefix = "VirtualDisk"
    $volumeSize = "100GB"

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
                Install-Module AzureRM -AllowClobber -Force -Scope AllUsers
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

        #Script StoragePool
        Script StoragePool {
            SetScript  = {

                New-StoragePool -FriendlyName $using:storagePoolName -StorageSubSystemFriendlyName '*storage*' -PhysicalDisks (Get-PhysicalDisk –CanPool $True)
            }
            TestScript = {
                (Get-StoragePool -ErrorAction SilentlyContinue -FriendlyName $using:storagePoolName).OperationalStatus -eq 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-StoragePool -FriendlyName $using:storagePoolName).OperationalStatus -eq 'OK') {'Present'} Else {'Absent'}}
            }
        }

        #Script VirtualDisk

        Script VirtualDisk {
            SetScript  = {

                $disks = Get-StoragePool –FriendlyName $using:storagePoolName -IsPrimordial $False | Get-PhysicalDisk
                $diskNum = $disks.Count
                New-VirtualDisk –StoragePoolFriendlyName $using:storagePoolName –FriendlyName $using:virtualDiskName –ResiliencySettingName simple -NumberOfColumns $diskNum –UseMaximumSize
            }
            TestScript = {
                (get-virtualdisk -ErrorAction SilentlyContinue -friendlyName $using:virtualDiskName).operationalStatus -EQ 'OK'
            }
            GetScript  = {
                @{Ensure = if ((Get-VirtualDisk -FriendlyName $using:virtualDiskName).OperationalStatus -eq 'OK') {'Present'} Else {'Absent'}}
            }
            DependsOn  = "[Script]StoragePool"
        }

        Script FormatDisk {
            SetScript  = {
                $DriveLetters = $using:DriveLetters
                Get-VirtualDisk –FriendlyName $using:virtualDiskName | Get-Disk | Initialize-Disk –Passthru

                for ($i = 0; $i -lt $using:AgentCount; $i++) {

                    Get-VirtualDisk –FriendlyName $using:virtualDiskName | Get-Disk | New-Partition -DriveLetter $DriveLetters[$i] -Size $using:volumeSize | Format-Volume -NewFileSystemLabel $using:volumePrefix$i –AllocationUnitSize 64KB -FileSystem NTFS

                }

            }
            TestScript = {
                for ($i = 0; $i -lt $using:AgentCount; $i++) {

                    if (  (get-volume -ErrorAction SilentlyContinue -filesystemlabel $using:volumePrefix$i).filesystem -NE 'NTFS' ) {
                        return $false
                    }


                }
                return $true
            }
            GetScript  = {
                @{Ensure = if ((get-volume -filesystemlabel $using:volumePrefix$i).filesystem -EQ 'NTFS') {'Present'} Else {'Absent'}}
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

        xPendingReboot "Reboot" {
            Name      = "Reboot1"
            DependsOn = "[xArchive]ExtractVSTSAgent"
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
                "$($PoolName)", "--agent", "$($AgentNamePrefix)$($i)", "--acceptTeeEula", "--work", "$($DriveLetters[$i]):\agent", "--runAsService",
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
                    DependsOn  = "[xPendingReboot]Reboot"
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

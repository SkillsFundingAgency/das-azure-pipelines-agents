Configuration BuildServerConfiguration {
    param(
        [string]$AgentDownloadUrl,
        [string]$VSTSPAT,
        [string]$VSTSAccountName,
        [string]$PoolName,
        [string]$AgentNamePrefix
    )

    $AgentCount = (Get-Disk).Count - 2  # Agent disks = Total disks - osDisk - Temp Disk
    $AgentDownloadPath = "D:/Downloads/Agent.zip"
    $AgentExtractPath = "D:/Downloads/Agent"
    $DriveLetters = 'FGHIJKLMNOPQSRTUVWXYZ'

    Import-DscResource -ModuleName PSDesiredStateConfiguration, xDisk, xPendingReboot, xNetworking, xPSDesiredStateConfiguration


    Node localhost {

        LocalConfigurationManager {
            RebootNodeIfNeeded = $True
            ConfigurationMode  = "ApplyOnly"

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

        # --- Partition any unpartitioned disks
        $UnpartitionedDisks = @(Get-Disk | Where-Object {$_.NumberOfPartitions -lt 1})
        for ($j=0; $j -lt $UnpartitionedDisks.Length; $j++) {
            if ($j -eq 0) {
                xWaitforDisk "DataDisk$($j)" {
                    DiskNumber       = $UnpartitionedDisks[$j].Number
                    RetryIntervalSec = 30
                    RetryCount       = 20
                }
            }
            else {
                xWaitforDisk "DataDisk$($j)" {
                    DiskNumber       = $UnpartitionedDisks[$j].Number
                    RetryIntervalSec = 30
                    RetryCount       = 20
                    DependsOn        = "[xPendingReboot]Reboot$($j-1)"
                }
            }

            xDisk "AddDataDisk$($j)" {
                DiskNumber  = $UnpartitionedDisks[$j].Number
                DriveLetter = $DriveLetters[$UnpartitionedDisks[$j].Number-2]
                DependsOn   = "[xWaitforDisk]DataDisk$($j)"
            }

            xPendingReboot "Reboot$($j)" {
                Name      = "RebootForDisk$($j)"
                DependsOn = "[xDisk]AddDataDisk$($j)"
            }
        }

        # --- Download and Extract VSTS Agent Files
        if ($UnpartitionedDisks.Length -gt 0) {
            xRemoteFile DownloadVSTSAgent {
                DestinationPath = $AgentDownloadPath
                Uri             = $AgentDownloadUrl
                DependsOn       = "[xPendingReboot]Reboot$($UnpartitionedDisks.Length-1)"
            }
        }
        else {
            xRemoteFile DownloadVSTSAgent {
                DestinationPath = $AgentDownloadPath
                Uri             = $AgentDownloadUrl
            }
        }

        xArchive ExtractVSTSAgent {
            Path        =  $AgentDownloadPath
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
                "$($PoolName)", "--agent", "$($AgentNamePrefix)$($i)", "--acceptTeeEula", "--work", "$($DriveLetters[$i]):\agent", "--runAsService",
                "--noRestart")
            &"$($DriveLetters[$i]):\config.cmd" $args
        }

        for ($i=0; $i -lt ($AgentCount); $i++) {
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

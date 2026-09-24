$ErrorActionPreference = 'Continue'

$probes = [ordered]@{
    'Version'              = '$PSVersionTable | Out-String'
    'PSModulePath'         = '$env:PSModulePath -split [IO.Path]::PathSeparator'
    'Import Archive'       = 'Import-Module Microsoft.PowerShell.Archive -Verbose; Get-Module Microsoft.PowerShell.Archive | Format-List Name, Version, Path'
    'Import PackageMgmt'   = 'Import-Module PackageManagement -Verbose; Get-Module PackageManagement | Format-List Name, Version, Path'
    'Import PowerShellGet' = 'Import-Module PowerShellGet -Verbose; Get-Module PowerShellGet | Format-List Name, Version, Path'
    'Find-Module'          = 'Find-Module Pester -RequiredVersion 4.10.1 | Format-List Name, Version, Repository'
}

foreach ($name in $probes.Keys) {
    Write-Output "===== pwsh probe: $name ====="
    $output = & pwsh -NoProfile -NonInteractive -Command $probes[$name] 2>&1 | Out-String -Width 300
    $exitCode = $LASTEXITCODE
    Write-Output $output
    Write-Output ("exit code: {0} (0x{0:X8})" -f $exitCode)
}

Write-Output "===== pwsh probe: Import PowerShellGet with PSModulePath limited to pwsh folders ====="
$savedPath = $env:PSModulePath
$env:PSModulePath = "$env:ProgramFiles\PowerShell\Modules;$env:ProgramFiles\PowerShell\7\Modules"
$output = & pwsh -NoProfile -NonInteractive -Command 'Import-Module PowerShellGet -Verbose; Get-Module | Format-Table Name, Version, Path -AutoSize' 2>&1 | Out-String -Width 300
$exitCode = $LASTEXITCODE
$env:PSModulePath = $savedPath
Write-Output $output
Write-Output ("exit code: {0} (0x{0:X8})" -f $exitCode)

Write-Output "===== Application event log (errors and warnings) ====="
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; Level = 1, 2, 3 } -MaxEvents 15 -ErrorAction SilentlyContinue |
    Format-List TimeCreated, ProviderName, Id, Message |
    Out-String -Width 300

exit 0

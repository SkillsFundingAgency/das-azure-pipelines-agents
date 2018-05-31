[CmdletBinding()]
param(

    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe",
    [Parameter(Mandatory = $true)]
    [string]$DeploymentStorageAccountName,
    [Parameter(Mandatory = $false)]
    [string]$DeploymentStorageAccountContainer = "buildserverdeploy",
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName


)

try {

    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module xDisk -MinimumVersion 1.0 -Force -Scope CurrentUser
    Install-Module xPendingReboot -MinimumVersion 0.4.0.0 -Force -Scope CurrentUser
    Install-Module xNetworking -MinimumVersion 5.7.0.0 -Force -Scope CurrentUser
    Install-Module xPSDesiredStateConfiguration -MinimumVersion 8.2.0.0 -Force -Scope CurrentUser



     # --- Install Dependencies From PSGallery
     Write-Host "Installing DSC Dependencies"
     $Dependencies = "xDisk", "xPendingReboot", "xNetworking", "xPSDesiredStateConfiguration"
     foreach ($Resource in $Dependencies) {
         Write-Host "    $([char]9788) $Resource" -NoNewline
         if (!(Get-Module -Name $Resource -ListAvailable)) {
             if ($ENV:TF_BUILD) {
                 Install-Module -Name $Resource -Scope AllUsers -Force
             }
             else {
                 Install-Module -Name $Resource -Scope CurrentUser -Force
             }
         }
         Write-Host " -> Complete" -ForegroundColor Green
     }


    # --- Set Template parameters
    $ParametersPath = "$PSScriptRoot\parameters.json"
    $Parameters = Get-Content -Path $ParametersPath -Raw | ConvertFrom-Json

    $Parameters.parameters.templateBaseUrl.value = "https://$DeploymentStorageAccountName.blob.core.windows.net/$DeploymentStorageAccountContainer"

    $null = Set-Content -Path $ParametersPath -Value ([Regex]::Unescape(($Parameters | ConvertTo-Json -Depth 10))) -Force

    $DeploymentParameters = @{
        ResourceGroupName    = $ResourceGroupName
        StorageAccountName   = $DeploymentStorageAccountName
        TemplateLocation     = "$PSScriptRoot"
        StorageContainerName = $DeploymentStorageAccountContainer
        DSCConfigurations    = (Get-ChildItem -Path "$PSScriptRoot\dsc" | Select-Object -ExpandProperty FullName)
    }

    . "$PSScriptRoot\\Invoke-Deployment.ps1" @DeploymentParameters
}
catch {
    throw "$_"
}

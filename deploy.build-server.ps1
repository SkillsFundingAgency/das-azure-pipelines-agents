[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,
    [Parameter(Mandatory = $false)]
    [string]$Location = "West Europe",
    [Parameter(Mandatory = $false)]
    [string]$DeploymentStorageAccountName = "dasarmdeploymentstest",
    [Parameter(Mandatory = $false)]
    [string]$DeploymentStorageAccountContainer = "buildserverdeploy"
)

try {
    $ResourceGroupName = "das-$EnvironmentName-build-rg".ToLower()

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

    . "$PSScriptRoot\..\Invoke-Deployment.ps1" @DeploymentParameters
}
catch {
    throw "$_"
}

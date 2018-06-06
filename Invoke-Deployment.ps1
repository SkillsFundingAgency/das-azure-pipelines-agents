<#
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [String]$ResourceGroupName,
    [Parameter(Mandatory = $false)]
    [String]$Location = "West Europe",
    [Parameter(Mandatory = $true)]
    [String]$StorageAccountName,
    [Parameter(Mandatory = $false)]
    [String]$StorageContainerName = "deploy",
    [Parameter(Mandatory = $true)]
    [String]$TemplateLocation,
    [Parameter(Mandatory = $false)]
    [Switch]$KeepDeploymentFiles,
    [Parameter(Mandatory = $false)]
    [String[]]$DSCConfigurations
)

function Set-AzureStorageBlobContentFromPath {
    Param(
        [Parameter()]
        [String]$Path,
        [Parameter()]
        [PSCustomObject]$Container
    )
    if ($Container) {
        $Files = Get-ChildItem -Path $Path -Recurse -File
        foreach ($File in $Files) {
            $TargetPath = ($File.fullname.Substring($Path.Length + 1)).Replace("\", "/")
            $null = Set-AzureStorageBlobContent -File $File.fullname -Container $Container.Name -Blob $TargetPath -Context $StorageContext -Force
        }
    }
}

try {

    # --- Are We Logged in?
    $IsLoggedIn = (Get-AzureRMContext -ErrorAction SilentlyContinue).Account
    if (!$IsLoggedIn) {
        throw "You are not logged in. Run Add-AzureRmAccount to continue"
    }

    # --- Create Resource Group
    Write-Host "- Creating Resource Group: $ResourceGroupName"
    $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction SilentlyContinue
    if (!$ResourceGroup) {
        $null = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location -Confirm:$false
    }


    # --- Create shared Storage Account
    Write-Host "- Creating Storage Account and retrieving access key: $StorageAccountName"
    #$StorageAccount = Get-AzureRmStorageAccount -ResourceGroup $ResourceGroupName -Name $StorageAccountName -ErrorAction SilentlyContinue
    $StorageAccount = Find-AzureRmResource -ResourceNameEquals $StorageAccountName
    if (!$StorageAccount) {
        $StorageAccountParameters = @{
            ResourceGroup = $ResourceGroupName
            Location      = $Location
            Name          = $StorageAccountName
            SkuName       = "Standard_LRS"
        }
        $StorageAccount = New-AzureRmStorageAccount @StorageAccountParameters
    }
    
    $StorageAccountResourceGroupName = $StorageAccount.ResourceGroupName
    $StorageAccountPrimaryKey = (Get-AzureRmStorageAccountKey -ResourceGroup $StorageAccountResourceGroupName -Name $StorageAccountName)[0].Value

    # --- Create a new Storage Context
    Write-Host "- Generating storage context"
    $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountPrimaryKey

    # --- Create Containers: Templates
    Write-Host "- Uploading deployment templates to Storage Container: $StorageAccountName\$StorageContainerName"
    $StorageContainer = Get-AzureStorageContainer -Context $StorageContext -Name $StorageContainerName -ErrorAction SilentlyContinue
    if (!$StorageContainer) {
        $null = New-AzureStorageContainer -Context $StorageContext -Name $StorageContainerName -Permission Container
    }

    # --- Publish any DSCs
    if ($DSCConfigurations) {
        Write-Host "- Publishing DSC Configurations"
        foreach ($Configuration in $DSCConfigurations) {
            Write-Host "    - $Configuration" -NoNewline
            if (!(Test-Path -Path $Configuration)) {
                throw "Could not find resource at path: $Configuration"
            }

            $PublishParameters = @{
                ResourceGroupName  = $StorageAccountResourceGroupName
                StorageAccountName = $StorageAccountName
                ContainerName      = $StorageContainerName
                ConfigurationPath  = $Configuration
            }
            $null = Publish-AzureRmVMDscConfiguration @PublishParameters -Force
            Write-Host " -> Complete" -ForegroundColor Green
        }
    }

    $Container = Get-AzureStorageContainer -Name $StorageContainerName -Context $StorageContext
    $TemplateLocationFullPath = (Resolve-Path -Path $TemplateLocation -ErrorAction Stop).Path
    Set-AzureStorageBlobContentFromPath -Path $TemplateLocationFullPath -Container $Container

    $DeploymentParameters = @{
        ResourceGroup         = $ResourceGroupName
        TemplateParameterFile = "$TemplateLocationFullPath\parameters.json"
        TemplateFile          = "$TemplateLocationFullPath\template.json"
    }

    # --- Invoke deployment
    if (!$ENV:TF_BUILD) {
        Write-Host "- Deploying to Azure"
        New-AzureRmResourceGroupDeployment @DeploymentParameters -Verbose:$VerbosePreference
    }

}
catch {
    throw "$_"
}
finally {
    # --- Clean up deployment files
    if (!$KeepDeploymentFiles.IsPresent -and $IsLoggedIn -and $StorageContext -and !$ENV:TF_BUILD) {
        Write-Warning "Deployment failed! - Removing deployment Container $StorageContainerName from Storage Account $StorageAccountName"
        $null = Remove-AzureStorageContainer -Context $StorageContext -Name $StorageContainerName -Force -ErrorAction SilentlyContinue
    }
}



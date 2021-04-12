if (-not (Test-Path Env:AZP_URL)) {
	Write-Error "error: missing AZP_URL environment variable"
	exit 1
}

if (-not (Test-Path Env:AZP_TOKEN_FILE)) {
	if (-not (Test-Path Env:AZP_TOKEN)) {
		Write-Error "error: missing AZP_TOKEN environment variable"
		exit 1
	}

	$Env:AZP_TOKEN_FILE = "\azp\.token"
	$Env:AZP_TOKEN | Out-File -FilePath $Env:AZP_TOKEN_FILE
}

#This is to account for a bug with agent capabilites not picking up java for OpenJDK. JAVA_HOME get sets by the chocolatey install so copy it from there.
$Env:Java = $Env:JAVA_HOME

if($Env:AZP_POOL -contains "Integration")
{
	#This environment variable should be set in the build docker file as part of the SDK installation
	if (-not (Test-Path Env:LATEST_DOTNET_VERSION)) {
		Write-Error "error: missing LATEST_DOTNET_VERSION environment variable"
		exit 1
	}
	#Uses the X.X version specified during the install to dynamically fetch the latest X.X.X version so it can be pinned
	$InstalledVersion = (dotnet --list-sdks).Split(' ') | Where-Object { $_ -like "$($Env:LATEST_DOTNET_VERSION)*" } | Sort-Object -Descending | Select-Object -First 1
	if (!$InstalledVersion) {
		Write-Error "DotNet $($Env:LATEST_DOTNET_VERSION) Version not found"
		exit 1
	}
	dotnet new globaljson --sdk-version $InstalledVersion
}


Remove-Item Env:AZP_TOKEN

if ($Env:AZP_WORK -and -not (Test-Path Env:AZP_WORK)) {
	New-Item $Env:AZP_WORK -ItemType directory | Out-Null
}

New-Item "\azp\agent" -ItemType directory | Out-Null

# Let the agent ignore the token env variables
$Env:VSO_AGENT_IGNORE = "AZP_TOKEN,AZP_TOKEN_FILE"

Set-Location agent

Write-Host "1. Determining matching Azure Pipelines agent..." -ForegroundColor Cyan

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$(Get-Content ${Env:AZP_TOKEN_FILE})"))
$package = Invoke-RestMethod -Headers @{Authorization = ("Basic $base64AuthInfo")} "$(${Env:AZP_URL})/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
$packageUrl = $package[0].Value.downloadUrl

Write-Host $packageUrl

Write-Host "2. Downloading and installing Azure Pipelines agent..." -ForegroundColor Cyan

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($packageUrl, "$(Get-Location)\agent.zip")

Expand-Archive -Path "agent.zip" -DestinationPath "\azp\agent"

try {
	Write-Host "3. Configuring Azure Pipelines agent..." -ForegroundColor Cyan

	.\config.cmd --unattended `
		--agent "$(if (Test-Path Env:AZP_AGENT) { ${Env:AZP_AGENT} } else { ${Env:POD_NAME} })" `
		--url "$(${Env:AZP_URL})" `
		--auth PAT `
		--token "$(Get-Content ${Env:AZP_TOKEN_FILE})" `
		--pool "$(if (Test-Path Env:AZP_POOL) { ${Env:AZP_POOL} } else { 'Default' })" `
		--work "$(if (Test-Path Env:AZP_WORK) { ${Env:AZP_WORK} } else { '_work' })" `
		--replace

	Write-Host "4. Running Azure Pipelines agent..." -ForegroundColor Cyan

	.\run.cmd --once
}
finally {
	Write-Host "Cleanup. Removing Azure Pipelines agent..." -ForegroundColor Cyan

	.\config.cmd remove --unattended `
		--auth PAT `
		--token "$(Get-Content ${Env:AZP_TOKEN_FILE})"
}

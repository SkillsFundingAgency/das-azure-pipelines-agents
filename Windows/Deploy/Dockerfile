FROM dasprdpublicacr.azurecr.io/azure-pipelines-base-deploy-agent-win:latest

ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

RUN choco config set cachelocation C:\chococache \
  && choco feature disable -name showDownloadProgress

RUN choco install \
  git  \
  powershell-core \
  dacfx-18 \
  --confirm \
  --limit-output \
  --timeout 216000 \
  && rmdir /S /Q C:\chococache

SHELL ["powershell", "-NoProfile", "-Command"]
RUN  Install-PackageProvider -Name NuGet -Force
RUN  Install-Module Az -Force

SHELL ["pwsh", "-NoProfile", "-Command"]
RUN  Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
RUN  Install-Module Az -Force
RUN  Install-Module SqlServer, AzTable -Force

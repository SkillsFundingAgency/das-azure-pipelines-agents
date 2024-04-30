FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019

WORKDIR /azp

COPY Start.ps1 .

CMD powershell .\start.ps1

ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

RUN choco config set cachelocation C:\chococache \
  && choco feature disable -name showDownloadProgress

RUN choco install \
  git  \
  powershell-core \
  nodejs-lts \
  --confirm \
  --limit-output \
  --timeout 216000 \
  && rmdir /S /Q C:\chococache \
  && setx npm true

RUN choco install mongodb --version 5.0.3  --confirm --limit-output --timeout 216000
RUN setx /M PATH "%PATH%;%ProgramFiles%\MongoDB\Server\5.0\bin"

SHELL ["powershell", "-NoProfile", "-Command"]
RUN Install-PackageProvider -Name NuGet -Force
RUN Install-Module Az -Force
RUN Install-Module PSScriptAnalyzer -Force
RUN Install-Module AWSPowerShell -AllowClobber -Force
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force -SkipPublisherCheck

# Download and install Microsoft Access Database Engine 64-bit
RUN Invoke-WebRequest -Uri "https://download.microsoft.com/download/3/5/C/35C84C36-661A-44E6-9324-8786B8DBE231/accessdatabaseengine_X64.exe" -OutFile "AccessDatabaseEngine_X64.exe" ; \
    Start-Process -FilePath .\AccessDatabaseEngine_X64.exe -ArgumentList '/quiet', '/norestart' -Wait ; \
    Remove-Item -Path .\AccessDatabaseEngine_X64.exe -Force

SHELL ["pwsh", "-NoProfile", "-Command"]
RUN Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
RUN Invoke-WebRequest -Uri https://aka.ms/dacfx-msi -OutFile .\dacfx.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I dacfx.msi /quiet'; rm .\dacfx.msi
RUN Install-Module Az -Force
RUN Install-Module SqlServer, AzTable, AWSPowerShell.NetCore, PSScriptAnalyzer -Force
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force

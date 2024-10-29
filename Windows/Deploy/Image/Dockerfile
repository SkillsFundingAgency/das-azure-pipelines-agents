FROM mcr.microsoft.com/windows/servercore:ltsc2022

WORKDIR /azp

COPY Start.ps1 .

CMD powershell .\start.ps1

ENV chocolateyUseWindowsCompression=false
ENV chocolateyVersion=1.4.0
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

RUN choco install mongodb --version 5.0.3 --confirm --limit-output --timeout 216000
# Add mongodb, sqlpackage and azcopy to the system path
RUN setx /M PATH "%PATH%;%ProgramFiles%\MongoDB\Server\5.0\bin;%ProgramFiles%\sqlpackage;%ProgramFiles%\azcopy"

SHELL ["powershell", "-NoProfile", "-Command"]
RUN Install-PackageProvider -Name NuGet -Force
RUN Install-Module Az -Force
RUN Install-Module PSScriptAnalyzer -Force
RUN Install-Module AWSPowerShell -AllowClobber -Force
# This module is required to run the Test-Configuration.ps1 script, DASD-9583 has been created to improve this, the module can be removed when that is done.
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force -SkipPublisherCheck

SHELL ["pwsh", "-NoProfile", "-Command"]
RUN Invoke-WebRequest -Uri https://aka.ms/sqlpackage-windows -OutFile .\sqlpackage.zip -UseBasicParsing; Expand-Archive -Path .\sqlpackage.zip -DestinationPath 'C:\Program Files\sqlpackage'; rm .\sqlpackage.zip
RUN Invoke-WebRequest -Uri https://aka.ms/downloadazcopy-v10-windows -OutFile .\azcopy.zip -UseBasicParsing; Expand-Archive -Path .\azcopy.zip -DestinationPath 'C:\Program Files\azcopy'; rm .\azcopy.zip; mv 'C:\Program Files\azcopy\azcopy_windows_amd64_*\azcopy.exe' 'C:\Program Files\azcopy\azcopy.exe'; rm -r 'C:\Program Files\azcopy\azcopy_windows_amd64_*'
RUN Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
RUN Invoke-WebRequest -Uri https://aka.ms/dacfx-msi -OutFile .\dacfx.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I dacfx.msi /quiet'; rm .\dacfx.msi
RUN Install-Module Az -Force
RUN Install-Module SqlServer, AzTable, AWSPowerShell.NetCore, PSScriptAnalyzer -Force
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force

# Download and extract the Azure Pipelines agent
# RUN curl -L -o agent.zip https://vstsagentpackage.azureedge.net/agent/3.246.0/vsts-agent-win-x64-3.246.0.zip \
#     && mkdir C:\azp\agent \
#     && powershell -Command "Expand-Archive -Path agent.zip -DestinationPath C:\azp\agent" \
#     && Remove-Item -Force agent.zip

RUN $ProgressPreference = 'SilentlyContinue'; \
    $latestVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/azure-pipelines-agent/releases/latest").tag_name -replace '^v', ''; \
    $downloadUrl = "https://vstsagentpackage.azureedge.net/agent/$latestVersion/vsts-agent-win-x64-$latestVersion.zip"; \
    Write-Host $downloadUrl \
    curl -L -o agent.zip $downloadUrl \
    && mkdir C:\azp\agent \
    && powershell -Command "Expand-Archive -Path agent.zip -DestinationPath C:\azp\agent" \
    && Remove-Item -Force agent.zip
    
#    Invoke-WebRequest -Uri $downloadUrl -OutFile agent.zip -UseBasicParsing; \
#    Expand-Archive -Path agent.zip -DestinationPath C:\azp\agent; \
#    Remove-Item -Force agent.zip

# Verify that the agent files are present in the correct location
RUN dir C:\azp\agent
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

SHELL ["pwsh", "-NoProfile", "-Command"]
RUN $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://aka.ms/sqlpackage-windows' -OutFile '.\sqlpackage.zip' -UseBasicParsing; Expand-Archive -LiteralPath '.\sqlpackage.zip' -DestinationPath 'C:\Program Files\sqlpackage'; Remove-Item '.\sqlpackage.zip'
RUN $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://aka.ms/downloadazcopy-v10-windows' -OutFile '.\azcopy.zip' -UseBasicParsing; Expand-Archive -LiteralPath '.\azcopy.zip' -DestinationPath 'C:\Program Files\azcopy'; Remove-Item '.\azcopy.zip'; Move-Item 'C:\Program Files\azcopy\azcopy_windows_amd64_*\azcopy.exe' 'C:\Program Files\azcopy\azcopy.exe'; Remove-Item 'C:\Program Files\azcopy\azcopy_windows_amd64_*' -Recurse -Force
RUN $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://aka.ms/installazurecliwindowsx64' -OutFile '.\AzureCLI.msi' -UseBasicParsing; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item '.\AzureCLI.msi'
RUN $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri 'https://aka.ms/dacfx-msi' -OutFile '.\dacfx.msi' -UseBasicParsing; Start-Process msiexec.exe -Wait -ArgumentList '/I dacfx.msi /quiet'; Remove-Item '.\dacfx.msi'
RUN Install-Module Az -Force
RUN Install-Module SqlServer, AzTable, AWSPowerShell.NetCore, PSScriptAnalyzer -Force
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force

SHELL ["powershell", "-NoProfile", "-Command"]
RUN Install-PackageProvider -Name NuGet -Force
RUN Install-Module Az -Force
RUN Install-Module PSScriptAnalyzer -Force
RUN Install-Module AWSPowerShell -AllowClobber -Force
# This module is required to run the Test-Configuration.ps1 script, DASD-9583 has been created to improve this, the module can be removed when that is done.
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force -SkipPublisherCheck
FROM mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019

WORKDIR /azp

COPY Start.ps1 .

CMD powershell .\start.ps1

# Restore the default Windows shell for correct batch processing below.
SHELL ["cmd", "/S", "/C"]

ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

RUN choco config set cachelocation C:\chococache \
  && choco feature disable -name showDownloadProgress

RUN choco install \
  git  \
  powershell-core \
  nodejs \
  openjdk11 \
  --confirm \
  --limit-output \
  --timeout 216000 \
  && rmdir /S /Q C:\chococache

RUN  @pwsh -NoProfile -Command "Install-Module Az, PSScriptAnalyzer, powershell-yaml -Force"
RUN  @pwsh -NoProfile -Command "Install-Module Pester -RequiredVersion 4.10.1 -Force"

RUN  @pwsh -NoProfile -Command "Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi"

# Install Build Tools with workloads, excluding components with known issues.
RUN setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE true \
  && curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/16/release/vs_buildtools.exe \
  && "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache \
  --add Microsoft.VisualStudio.Workload.AzureBuildTools \
  --add Microsoft.VisualStudio.Workload.DataBuildTools \
  --add Microsoft.VisualStudio.Workload.NetCoreBuildTools \
  --add Microsoft.VisualStudio.Workload.WebBuildTools \
  --add Microsoft.VisualStudio.Component.TestTools.BuildTools \
  --add Microsoft.VisualStudio.Component.SQL.SSDTBuildSku \
  --add Microsoft.Net.Component.4.6.2.TargetingPack \
  --add Microsoft.Net.Component.4.8.TargetingPack \
  --add Microsoft.VisualStudio.Component.WebDeploy \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
  --remove Microsoft.VisualStudio.Component.Windows81SDK \
  && setx /M PATH "%PATH%;%ProgramFiles(x86)%\Microsoft Visual Studio\2019\BuildTools\MSBuild\Current\Bin" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

ENV DOTNET_VERSION 2.2.207

#Install dotnet sdk
RUN curl -L -o "%TEMP%\dotnet-install.ps1" https://dot.net/v1/dotnet-install.ps1 \
  && powershell "%TEMP%\dotnet-install.ps1" -InstallDir '%ProgramFiles%\dotnet' -Version $env:DOTNET_VERSION \
  && setx /M PATH "%PATH%;%ProgramFiles%\dotnet" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

#Used in Start.ps1 in the base image to dynamically get the latest X.X.X version installed
ENV LATEST_DOTNET_VERSION 3.1

#Install dotnet sdk
RUN curl -L -o "%TEMP%\dotnet-install.ps1" https://dot.net/v1/dotnet-install.ps1 \
  && powershell "%TEMP%\dotnet-install.ps1" -InstallDir '%ProgramFiles%\dotnet' -Channel $env:LATEST_DOTNET_VERSION \
  && setx /M PATH "%PATH%;%ProgramFiles%\dotnet" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

#Warmup required to stop dotnet-install being ran on startup
RUN mkdir C:\warmup \
  && cd C:\warmup \
  && dotnet new \
  && cd .. \
  && rmdir /S /Q C:\warmup

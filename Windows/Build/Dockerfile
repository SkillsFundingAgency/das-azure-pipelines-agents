FROM apprenticeshipsdevops/azure-pipelines-base-agent-win:latest

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
  jdk8 \
  --confirm \
  --limit-output \
  --timeout 216000 \
  && rmdir /S /Q C:\chococache

# Install Build Tools with workloads, excluding components with known issues.
RUN curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/16/release/vs_buildtools.exe \
  && "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache \
  --add Microsoft.VisualStudio.Workload.AzureBuildTools \
  --add Microsoft.VisualStudio.Workload.DataBuildTools \
  --add Microsoft.VisualStudio.Workload.WebBuildTools \
  --add Microsoft.VisualStudio.Component.SQL.SSDTBuildSku \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
  --remove Microsoft.VisualStudio.Component.Windows81SDK \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

#Install dotnet sdk
RUN curl -L -o "%TEMP%\dotnet-install.ps1" https://dot.net/v1/dotnet-install.ps1 \
  && powershell "%TEMP%\dotnet-install.ps1" -InstallDir '%ProgramFiles%\dotnet' -Version '2.2.207' \
  && setx /M PATH "%PATH%;%ProgramFiles%\dotnet" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

#Warmup dotnet sdk
RUN mkdir C:\warmup \
  && cd C:\warmup \
  && dotnet new \
  && cd .. \
  && rmdir /S /Q C:\warmup

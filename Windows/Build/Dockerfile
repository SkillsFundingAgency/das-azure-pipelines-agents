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
  --add Microsoft.VisualStudio.Workload.NetCoreBuildTools \
  --add Microsoft.VisualStudio.Workload.WebBuildTools \
  --add Microsoft.VisualStudio.Component.SQL.SSDTBuildSku \
  --add Microsoft.Net.Component.4.6.2.TargetingPack \
  --add Microsoft.VisualStudio.Component.WebDeploy \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
  --remove Microsoft.VisualStudio.Component.Windows81SDK \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

# Install VS Test Agent
RUN curl -L -o "%TEMP%\vs_TestAgent.exe" https://download.visualstudio.microsoft.com/download/pr/220fe621-dd35-4fc0-a32e-10ff6f4551cd/0baf634f22467a27b6f7b2fe8d9e687dd0876864d5a0b4ee9291110ac4baaa16/vs_TestAgent.exe \
  && start /w %TEMP%\vs_TestAgent.exe --quiet --norestart --nocache --wait \
  && setx /M VSTest "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\TestAgent\Common7\IDE\CommonExtensions\Microsoft\TestWindow" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

ENV DOTNET_VERSION 2.2.207

#Install dotnet sdk
RUN curl -L -o "%TEMP%\dotnet-install.ps1" https://dot.net/v1/dotnet-install.ps1 \
  && powershell "%TEMP%\dotnet-install.ps1" -InstallDir '%ProgramFiles%\dotnet' -Version $env:DOTNET_VERSION \
  && setx /M PATH "%PATH%;%ProgramFiles%\dotnet" \
  && setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE true \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*"

#Pin dotnet version
RUN cd C:\azp \
  && dotnet new globaljson --sdk-version %DOTNET_VERSION%

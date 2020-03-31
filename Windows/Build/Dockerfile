FROM apprenticeshipsdevops/azure-pipelines-base-agent-win:20200331.9

# Restore the default Windows shell for correct batch processing below.
SHELL ["cmd", "/S", "/C"]

ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

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
RUN (mkdir C:\TEMP \
  && curl -L -o C:\TEMP\vs_buildtools.exe https://aka.ms/vs/16/release/vs_buildtools.exe \
  && C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache \
  --installPath C:\BuildTools \
  --add Microsoft.VisualStudio.Workload.AzureBuildTools \
  --add Microsoft.VisualStudio.Workload.DataBuildTools \
  --add Microsoft.VisualStudio.Workload.NetCoreBuildTools \
  --add Microsoft.VisualStudio.Workload.WebBuildTools \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
  --remove Microsoft.VisualStudio.Component.Windows81SDK \
  && rmdir /S /Q C:\TEMP) \
  || IF "%ERRORLEVEL%"=="3010" EXIT 0

FROM apprenticeshipsdevops/azure-pipelines-base-agent-win:20200331.10

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
RUN curl -L -o "%TEMP%\vs_buildtools.exe" https://aka.ms/vs/16/release/vs_buildtools.exe \
  && setx /M DOTNET_SKIP_FIRST_TIME_EXPERIENCE 1 \
  && "%TEMP%\vs_buildtools.exe" --quiet --wait --norestart --nocache \
  --add Microsoft.VisualStudio.Workload.AzureBuildTools \
  --add Microsoft.VisualStudio.Workload.DataBuildTools \
  --add Microsoft.VisualStudio.Workload.NetCoreBuildTools \
  --add Microsoft.VisualStudio.Workload.WebBuildTools \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
  --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
  --remove Microsoft.VisualStudio.Component.Windows81SDK \
  # Cleanup
  && rmdir /S /Q C:\TEMP \
  && rmdir /S /Q "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer" \
  && powershell Remove-Item -Force -Recurse "%TEMP%\*" \
  && rmdir /S /Q "%ProgramData%\Package Cache"


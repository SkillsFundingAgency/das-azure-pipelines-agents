FROM apprenticeshipsdevops/azure-pipelines-base-agent-win:20200331.2

ENV chocolateyUseWindowsCompression=false
RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"

RUN choco config set cachelocation C:\chococache \
  && choco feature disable -name showDownloadProgress

# RUN choco install \
#   git  \
#   powershell-core \
#   nodejs \
#   jdk8 \
#   --confirm \
#   --limit-output \
#   --timeout 216000 \
#   && rmdir /S /Q C:\chococache

RUN choco install \
  visualstudio2019buildtools \
  --package-parameters "--passive --locale en-US --includeOptional" \
  --confirm \
  --limit-output \
  --timeout 216000 \
  && rmdir /S /Q C:\chococache

RUN choco install \
  visualstudio2019-workload-azurebuildtools \
  visualstudio2019-workload-netcorebuildtools \
  visualstudio2019-workload-webbuildtools \
  visualstudio2019-workload-databuildtools \
  --confirm \
  --limit-output \
  --timeout 21600 \
  --package-parameters "--includeOptional" \
  && rmdir /S /Q C:\chococache

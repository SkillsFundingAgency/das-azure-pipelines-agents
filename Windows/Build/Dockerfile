FROM apprenticeshipsdevops/azure-pipelines-base-agent-win:20200331.1

# Based on https://github.com/microsoft/vsts-agent-docker/blob/master/windows/servercore/10.0.14393/standard/VS2017/Dockerfile

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

RUN @powershell -NoProfile -ExecutionPolicy Bypass -Command "choco install visualstudio2019buildtools --package-parameters \"--passive --locale en-US --includeOptional\" --confirm --debug && rmdir /S /Q C:\\chococache || Get-Content 'C:\\ProgramData\\chocolatey\\logs\\chocolatey.log'"

RUN choco install \
  visualstudio2019buildtools \
  --package-parameters "--passive --locale en-US --includeOptional" \
  --confirm \
  --debug \
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

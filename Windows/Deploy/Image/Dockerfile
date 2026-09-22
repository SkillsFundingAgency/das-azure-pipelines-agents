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
RUN Install-Module Az -Scope AllUsers -Force -AllowClobber
RUN Install-Module PSScriptAnalyzer -Force
RUN Install-Module AWSPowerShell -AllowClobber -Force
# This module is required to run the Test-Configuration.ps1 script, DASD-9583 has been created to improve this, the module can be removed when that is done.
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force -SkipPublisherCheck

SHELL ["cmd", "/S", "/C"]
RUN curl -L -f -o "%TEMP%\sqlpackage.zip" https://aka.ms/sqlpackage-windows \
  && if not exist "C:\Program Files\sqlpackage" mkdir "C:\Program Files\sqlpackage" \
  && powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TEMP%\sqlpackage.zip' -DestinationPath 'C:\Program Files\sqlpackage' -Force" \
  && del /Q "%TEMP%\sqlpackage.zip"
RUN curl -L -f -o "%TEMP%\azcopy.zip" https://aka.ms/downloadazcopy-v10-windows \
  && if not exist "C:\Program Files\azcopy" mkdir "C:\Program Files\azcopy" \
  && powershell -NoProfile -Command "Expand-Archive -LiteralPath '%TEMP%\azcopy.zip' -DestinationPath 'C:\Program Files\azcopy' -Force" \
  && del /Q "%TEMP%\azcopy.zip" \
  && powershell -NoProfile -Command "Move-Item -Path 'C:\Program Files\azcopy\azcopy_windows_amd64_*\azcopy.exe' -Destination 'C:\Program Files\azcopy\azcopy.exe'; Remove-Item -Recurse -Force 'C:\Program Files\azcopy\azcopy_windows_amd64_*'"
RUN curl -L -f -o AzureCLI.msi https://aka.ms/installazurecliwindows \
  && msiexec /I AzureCLI.msi /quiet /norestart \
  && del /Q AzureCLI.msi
RUN curl -L -f -o dacfx.msi https://aka.ms/dacfx-msi \
  && msiexec /I dacfx.msi /quiet /norestart \
  && del /Q dacfx.msi

SHELL ["pwsh", "-NoProfile", "-Command"]
RUN Remove-Item -Recurse -Force $env:TEMP\* -ErrorAction SilentlyContinue
RUN Install-Module SqlServer, AzTable, AWSPowerShell.NetCore, PSScriptAnalyzer -Scope AllUsers -Force
RUN Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force
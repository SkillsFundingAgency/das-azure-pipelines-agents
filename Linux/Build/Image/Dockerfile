FROM ubuntu:24.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes

# Add git-core PPA for a modern git (>= 2.36) that supports extensions.worktreeConfig
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl gnupg \
  && curl -fsSL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xE363C90F8F1B6217' | gpg --dearmor -o /etc/apt/trusted.gpg.d/git-core-ppa.gpg \
  && echo "deb [signed-by=/etc/apt/trusted.gpg.d/git-core-ppa.gpg] https://ppa.launchpadcontent.net/git-core/ppa/ubuntu/ noble main" > /etc/apt/sources.list.d/git-core-ppa.list \
  && rm -rf /var/lib/apt/lists/*

# Install basic command-line utilities
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  dnsutils \
  file \
  ftp \
  jq \
  git \
  gnupg \
  iproute2 \
  iputils-ping \
  libcurl4 \
  libicu74 \
  libssl-dev \
  libunwind8 \
  locales \
  openssh-client \
  netcat-openbsd \
  rsync\
  shellcheck \
  sudo \
  telnet \
  time \
  unzip \
  wget \
  zip \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

# Pull in older library versions that are no longer in the 24.04 repos but are
# still required for backwards compatibility, downloaded and installed directly:
#   - libssl1.0.0 / libssl1.1 : Azure Functions ExtensionsMetadataGenerator is
#     not compatible with OpenSSL 3.x (the default on 24.04)
#   - libicu70 : older .NET runtimes (e.g. .NET Core 2.2/3.1) link against ICU 70,
#     while 24.04 ships ICU 74. Both are installed side by side.
RUN curl -sSL -o /tmp/libssl1.0.deb http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb \
  && curl -sSL -o /tmp/libssl1.1.deb http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb \
  && curl -sSL -o /tmp/libicu70.deb http://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu70_70.1-2_amd64.deb \
  && dpkg -i /tmp/libssl1.0.deb /tmp/libssl1.1.deb /tmp/libicu70.deb \
  && rm /tmp/libssl1.0.deb /tmp/libssl1.1.deb /tmp/libicu70.deb

WORKDIR /azp

COPY ./start.sh .
RUN chmod +x start.sh

CMD ["./start.sh"]

# Based on https://github.com/Microsoft/vsts-agent-docker/blob/master/ubuntu/16.04/standard/Dockerfile

# Setup the locale
ENV LANG en_US.UTF-8
ENV LC_ALL $LANG
RUN locale-gen $LANG \
  && update-locale

# Accept EULA - needed for certain Microsoft packages like SQL Server Client Tools
ENV ACCEPT_EULA=Y

# Install essential build tools
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  build-essential \
  && rm -rf /var/lib/apt/lists/*

# Install Java OpenJDK
RUN apt-get update \
  && apt-get install -y --no-install-recommends openjdk-17-jdk \
  && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install MS SQL Server client tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-2017)
RUN curl -sSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && rm /tmp/packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  mssql-tools \
  unixodbc-dev \
  && rm -rf /var/lib/apt/lists/* \
  && find /etc/apt/sources.list.d/ -type f ! -name 'ubuntu.sources' -delete \
  || echo -n
ENV PATH=$PATH:/opt/mssql-tools/bin

# Install .NET SDKs via dotnet-install.sh
#
# Multiple .NET 10 SDK feature bands are installed side by side, mirroring the
# Microsoft hosted ubuntu-24.04 image. Nothing is pinned as the agent default:
# --channel 10.0 stays first so the newest .NET 10 SDK remains the default for
# every repo, and the extra bands are simply available for any repo that needs
# to select one via global.json.
#
#   - --channel 10.0 : latest .NET 10, the default for repos with no global.json
#   - 10.0.109       : 1xx band, available via global.json
#   - 10.0.204       : 2xx band, available via global.json
#
# The 2xx band matters because the 10.0.3xx band has a Razor source generator
# regression that mis-parses HTML tags inside @if blocks, breaking projects with
# Razor views (tracked as dotnet razor issue 13184 - still open, no fix
# released). 10.0.203 is the last version confirmed working by that issue.
# Affected repos pin themselves to 10.0.2xx with a global.json rather than the
# whole agent being held back. Drop the extra bands once the fix ships.
#
# Note SDKs use feature bands (10.0.1xx/2xx/3xx); 10.0.0-10.0.10 are RUNTIME
# versions and are not valid --version arguments here.
RUN curl -sSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh \
  && bash dotnet-install.sh --channel 2.2 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --channel 3.1 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --channel 6.0 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --version 10.0.109 --install-dir /usr/share/dotnet \
  && bash dotnet-install.sh --version 10.0.204 --install-dir /usr/share/dotnet \
  && rm dotnet-install.sh \
  && ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet
RUN dotnet help
ENV dotnet=/usr/bin/dotnet

# TODO: Delete this when no longer referenced by pipelines
ENV LATEST_DOTNET_VERSION=3.1

# List installed SDKs
RUN dotnet --list-sdks

# Install LTS Node.js and related tools
RUN curl -sL https://git.io/n-install | bash -s -- -ny - \
  && ~/n/bin/n lts \
  && npm install -g grunt \
  && npm install -g gulp \
  && npm install -g n \
  && npm install -g webpack webpack-cli --save-dev \
  && npm i -g npm \
  && rm -rf ~/n
ENV grunt=/usr/local/bin/grunt

# Install Powershell Core
RUN curl -sSL https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb -o /tmp/packages-microsoft-prod.deb \
  && dpkg -i /tmp/packages-microsoft-prod.deb \
  && rm /tmp/packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  powershell \
  && rm -rf /var/lib/apt/lists/* \
  && find /etc/apt/sources.list.d/ -type f ! -name 'ubuntu.sources' -delete

# Install Powershell Modules
RUN pwsh -NonInteractive -Command '$null = Install-Module AzTable, PSScriptAnalyzer, powershell-yaml -Scope AllUsers -Force'
RUN pwsh -NonInteractive -Command '$null = Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force'

# Install az cli
RUN apt-get update \
  && apt-get install -y lsb-release \
  && AZ_REPO=$(lsb_release -cs) \
  && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
  && apt-get update \
  && apt-get install -y azure-cli

# Clean system
RUN apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && find /etc/apt/sources.list.d/ -type f ! -name 'ubuntu.sources' -delete
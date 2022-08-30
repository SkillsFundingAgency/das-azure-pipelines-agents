FROM ubuntu:20.04

# To make it easier for build and release pipelines to run apt-get,
# configure apt to not require confirmation (assume the -y argument by default)
ENV DEBIAN_FRONTEND=noninteractive
RUN echo "APT::Get::Assume-Yes \"true\";" > /etc/apt/apt.conf.d/90assumeyes


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
  libicu66 \
  libunwind8 \
  libssl1.0 \
  locales \
  openssh-client \
  netcat \
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
  && apt-get install -y --no-install-recommends openjdk-11-jdk \
  && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# Install MS SQL Server client tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-2017)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  mssql-tools \
  unixodbc-dev \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/* \
  || echo -n
ENV PATH=$PATH:/opt/mssql-tools/bin

# Install .NET Core SDK and initialize package cache
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb > packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && rm packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  dotnet-sdk-3.1 \
  dotnet-sdk-6.0 \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*
RUN dotnet help
ENV dotnet=/usr/bin/dotnet

# TODO: Delete this when no longer referenced by pipelines
ENV LATEST_DOTNET_VERSION=3.1

#Manually install .NET Core 2.2 SDK
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel 2.2 --install-dir /usr/share/dotnet

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
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  powershell \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

# Install Powershell Modules
RUN pwsh -NonInteractive -Command '$null = Install-Module PSScriptAnalyzer, powershell-yaml -Scope AllUsers -Force'
RUN pwsh -NonInteractive -Command '$null = Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force'

# Install az cli
RUN apt-get update \
  && apt-get install -y lsb-release \
  && AZ_REPO=$(lsb_release -cs) \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | tee /etc/apt/sources.list.d/azure-cli.list \
  && apt-get install -y azure-cli

# Clean system
RUN apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

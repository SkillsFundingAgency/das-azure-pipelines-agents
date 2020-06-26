FROM apprenticeshipsdevops/azure-pipelines-base-agent:latest

# Based on https://github.com/Microsoft/vsts-agent-docker/blob/master/ubuntu/16.04/standard/Dockerfile

# Install basic command-line utilities
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  curl \
  dnsutils \
  file \
  ftp \
  iproute2 \
  iputils-ping \
  locales \
  openssh-client \
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
  && apt-get install -y --no-install-recommends openjdk-8-jdk \
  && rm -rf /var/lib/apt/lists/*
RUN update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install MS SQL Server client tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-2017)
RUN [ "xenial" = "xenial" ] \
  && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  mssql-tools \
  unixodbc-dev \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/* \
  || echo -n
ENV PATH=$PATH:/opt/mssql-tools/bin

# Install SqlPackage
RUN curl https://sqlpackage.blob.core.windows.net/preview/sqlpackage-linux-x64-150.4240.1.zip -o sqlpackage-linux-x64.zip \
  && mkdir /usr/share/sqlpackage \
  && unzip -d /usr/share/sqlpackage sqlpackage-linux-x64.zip \
  && chmod a+x /usr/share/sqlpackage/sqlpackage \
  && rm sqlpackage-linux-x64.zip \
  && apt-get install libunwind8 \
  && apt-get install libicu55
ENV PATH=$PATH:/usr/share/sqlpackage

# Install .NET Core SDK and initialize package cache
RUN curl https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb > packages-microsoft-prod.deb \
  && dpkg -i packages-microsoft-prod.deb \
  && rm packages-microsoft-prod.deb \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  dotnet-sdk-2.2=2.2.207-1 \
  dotnet-sdk-3.1 \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*
RUN dotnet help
ENV dotnet=/usr/bin/dotnet

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
  && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  powershell \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

# Install Powershell Modules
RUN pwsh -NonInteractive -Command '$null = Install-Module PSScriptAnalyzer, Az, Az.CosmosDb, AWSPowerShell.NetCore -Scope AllUsers -Force'
RUN pwsh -NonInteractive -Command '$null = Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force'

# Install Docker
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 19.03.8

RUN set -ex \
  && curl -fL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/`uname -m`/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
  && tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin \
  && rm docker.tgz \
  && docker -v

ENV DOCKER_COMPOSE_VERSION 1.25.4

RUN set -x \
  && curl -fSL "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`" -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose \
  && docker-compose -v


# Clean system
RUN apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

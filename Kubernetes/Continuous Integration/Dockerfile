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

# Install Azure CLI (instructions taken from https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/azure-cli.list \
  && curl -L https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  apt-transport-https \
  azure-cli \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/* \
  && az --version

# Install Mono
# RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
#   && echo "deb https://download.mono-project.com/repo/ubuntu stable-xenial main" | tee /etc/apt/sources.list.d/mono-official-stable.list \
#   && apt-get update \
#   && apt-get install -y --no-install-recommends apt-transport-https mono-complete \
#   && rm -rf /var/lib/apt/lists/* \
#   && rm -rf /etc/apt/sources.list.d/*

# Install MS SQL Server client tools (https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?view=sql-server-2017)
RUN [ "xenial" = "xenial" ] \
  && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list | tee /etc/apt/sources.list.d/msprod.list \
  && apt-get update \
  && apt-get install -y mssql-tools unixodbc-dev \
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
  apt-transport-https \
  dotnet-sdk-2.2 \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*
RUN dotnet help
ENV dotnet=/usr/bin/dotnet

# Install AzCopy (depends on .NET Core)
RUN apt-key adv --keyserver packages.microsoft.com --recv-keys EB3E94ADBE1229CF \
  && echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod/ xenial main" | tee /etc/apt/sources.list.d/azure.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends azcopy \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

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
RUN pwsh -NonInteractive -Command '$null = Install-Module PSScriptAnalyzer, Pester, Az -Scope AllUsers -Force'

# # Install Gitversion
# RUN apt-get update \
#   && apt-get install -y --no-install-recommends \
#   libcurl3 \
#   && wget https://www.nuget.org/api/v2/package/GitVersion.CommandLine/4.0.1-beta1-65 -O gitversion.nupkg \
#   && unzip -j -o gitversion.nupkg "tools/*" -d /usr/share/gitversion \
#   && unzip -j -o gitversion.nupkg "tools/lib/**" -d /usr/share/gitversion/lib \
#   && rm -f gitversion.nupkg \
#   && rm -rf /var/lib/apt/lists/*
# ENV PATH=$PATH:/usr/share/gitversion

# Install Docker
ENV DOCKER_CHANNEL stable
ENV DOCKER_VERSION 18.09.5

RUN set -ex \
 && curl -fL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/`uname -m`/docker-${DOCKER_VERSION}.tgz" -o docker.tgz \
 && tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin \
 && rm docker.tgz \
 && docker -v

ENV DOCKER_COMPOSE_VERSION 1.24.0

RUN set -x \
 && curl -fSL "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-`uname -s`-`uname -m`" -o /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose \
 && docker-compose -v


# Clean system
RUN apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

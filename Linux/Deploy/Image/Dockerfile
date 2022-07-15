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

# Install Mongo CLI https://www.mongodb.com/docs/mongocli/stable/install/
# Requires gnupg to install the key so installed after the initial apt-get install block
RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  mongocli

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

ENV grunt=/usr/local/bin/grunt

# Install Powershell Core
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
  && curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/microsoft.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
  powershell \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /etc/apt/sources.list.d/*

# Install SqlPackage
RUN curl https://aka.ms/sqlpackage-linux -4 -sL -o '/tmp/sqlpackage.zip' \
  && unzip /tmp/sqlpackage.zip -d $HOME/sqlpackage \
  && chmod +x $HOME/sqlpackage/sqlpackage \
  && sudo ln -sf $HOME/sqlpackage/sqlpackage /usr/local/bin
ENV SqlPackage=/root/sqlpackage/sqlpackage

# Install Powershell Modules
RUN pwsh -NonInteractive -Command '$null = Install-Module SqlServer, AzTable, AWSPowerShell.NetCore, PSScriptAnalyzer -Scope AllUsers -Force'
RUN pwsh -NonInteractive -Command '$null = Install-Module Pester -RequiredVersion 4.10.1 -Scope AllUsers -Force'
RUN pwsh -NonInteractive -Command '$null = Install-Module Az -Scope AllUsers -Force'

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

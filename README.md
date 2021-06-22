# _DAS Azure Pipelines Agents_


|   | Windows | Linux |
|---|---|---|
| Base | [Dockerfile](https://github.com/SkillsFundingAgency/das-azure-pipelines-agents/blob/master/Windows/Base/Dockerfile) <br> [Docker Hub](https://hub.docker.com/r/apprenticeshipsdevops/azure-pipelines-base-agent-win) <br> [![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/Pipeline%20Agents/das-azure-pipelines-agents%20(Windows%20Base)?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=1989&branchName=master) | [Dockerfile](https://github.com/SkillsFundingAgency/das-azure-pipelines-agents/blob/master/Linux/Base/Dockerfile) <br> [Docker Hub](https://hub.docker.com/r/apprenticeshipsdevops/azure-pipelines-base-agent) <br> [![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/Pipeline%20Agents/das-azure-pipelines-agents%20(Linux%20Base)?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=1987&branchName=master) |
| Build | [Dockerfile](https://github.com/SkillsFundingAgency/das-azure-pipelines-agents/blob/master/Windows/Build/Dockerfile) <br> [Docker Hub](https://hub.docker.com/r/apprenticeshipsdevops/azure-pipelines-build-agent-win) <br> [![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/Pipeline%20Agents/das-azure-pipelines-agents%20(Windows%20Build)?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=2109&branchName=master) | [Dockerfile](https://github.com/SkillsFundingAgency/das-azure-pipelines-agents/blob/master/Linux/Build/Dockerfile) <br> [Docker Hub](https://hub.docker.com/r/apprenticeshipsdevops/azure-pipelines-build-agent) <br> [![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/Pipeline%20Agents/das-azure-pipelines-agents%20(Linux%20CI)?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=1988&branchName=master) |
| Deploy | [Dockerfile](https://github.com/SkillsFundingAgency/das-azure-pipelines-agents/blob/master/Windows/Deploy/Dockerfile) <br> [Docker Hub](https://hub.docker.com/r/apprenticeshipsdevops/azure-pipelines-deploy-agent-win) <br> [![Build Status](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_apis/build/status/Pipeline%20Agents/das-azure-pipelines-agents%20(Windows%20CD)?branchName=master)](https://dev.azure.com/sfa-gov-uk/Apprenticeships%20Service%20Cloud%20Platform/_build/latest?definitionId=2102&branchName=master) |   |


<img src="https://avatars.githubusercontent.com/u/9841374?s=200&v=4" align="right" alt="UK Government logo">

This project contains the docker files and build & release files for Azure DevOps self hosted agents. These agents are based on https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops

## 🚀 Installation

### Pre-Requisites

* A clone of this repository
* Docker Desktop
* Azure DevOps Project

### Config

The container images require environment variables to run

| Environment Variables | Description                                                                                                                              |
|-----------------------|------------------------------------------------------------------------------------------------------------------------------------------|
| AZP_URL               | The URL of the Azure DevOps or Azure DevOps Server instance.                                                                             |
| AZP_TOKEN             | Personal Access Token (PAT) with Agent Pools (read, manage) scope, created by a user who has permission to configure agents, at AZP_URL. |
| AZP_POOL              | Agent pool name                                                                                                                          |
| NUGET_PACKAGES        | Path to Nuget Package Cache on volume mount.                                                                                             |
| POD_NAME              | Pod Name.                                                                                                                                |

More details on this can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#environment-variables)

## Running locally

To test the agents locally a PAT token is required with permissions Agent Pools (Read & Manage). The user who generated the PAT token also needs to be an Administrator on the agent pool.

The environment variables needed to run the agents locally can be seen in the manifest.yml files for each deployment. Below is an example of the docker run command for a linux build agent.

>docker run -e AZP_URL=<AzureDevOps_URL> -e AZP_TOKEN=<AzureDevOps_Token> -e AZP_POOL=<AzureDevOps_PoolName> -e NUGET_PACKAGES="/mnt/nugetcache/packages" --rm -it <Image_Name>

More details on this can be found [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#start-the-image-1)

## 🔗 External Dependencies

* Azure DevOps

## 🐛 Known Issues



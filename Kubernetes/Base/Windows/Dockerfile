FROM mcr.microsoft.com/windows/servercore@sha256:5d6ed58d7f27598db7a61b7a38cd755fa8165ae726aff39f14aa52468f0248dd
ENV WINDOWS_IMAGE_VERSION=ltsc2019

RUN mkdir C:\BuildAgent
WORKDIR C:/BuildAgent
COPY ./Start.* ./

CMD ["Start.cmd"]

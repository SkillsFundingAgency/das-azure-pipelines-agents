FROM mcr.microsoft.com/windows/servercore:ltsc2019
ENV WINDOWS_IMAGE_VERSION=ltsc2019

RUN mkdir C:\BuildAgent
WORKDIR C:/BuildAgent
COPY ./Start.* ./

CMD ["Start.cmd"]

FROM microsoft/windowsservercore@sha256:05de0a0ac13d3652bd1f2281b8589459ebb611092e3fe4d8f1be91f1f6984266
ENV WINDOWS_IMAGE_VERSION=ltsc2019

RUN mkdir C:\BuildAgent
WORKDIR C:/BuildAgent
COPY ./Start.* ./

CMD ["Start.cmd"]

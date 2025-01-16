FROM golang:1.23@sha256:70031844b8c225351d0bb63e2c383f80db85d92ba894e3da7e13bcf80efa9a37

ENV DOCKER_VERSION 24.0.2

RUN wget -O docker.tgz "https://download.docker.com/linux/static/stable/x86_64/docker-27.4.1.tgz" && \
    tar --extract --file docker.tgz --strip-components 1 --directory /usr/local/bin/ && \
    rm docker.tgz

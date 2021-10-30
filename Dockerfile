# To build image run `docker build --tag graalvm-dev:<version> .`

# Multi-stage image ... creates intermediate layer(s) for doing the graalvm native
# build (this is discarded by docker post-build)
FROM ubuntu:20.04 AS build

ARG GRAALVM_VERSION=21.3.0
ARG JAVA_VERSION=17
ARG GRAALVM_WORKDIR=/graalvm/src/project

ARG SCALA_VERSION=2.13.6
ARG GRADLE_VERSION=7.2

# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y wget unzip build-essential zlib1g-dev \
 && wget https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-ce-java${JAVA_VERSION}-linux-amd64-${GRAALVM_VERSION}.tar.gz -P /tmp \
 && tar zxvf /tmp/graalvm-ce-java${JAVA_VERSION}-linux-amd64-${GRAALVM_VERSION}.tar.gz -C /opt \
 && wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
 && unzip -d /opt /tmp/gradle-${GRADLE_VERSION}-bin.zip \
 && wget https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -P /tmp \
 && tar zxvf /tmp/scala-${SCALA_VERSION}.tgz -C /opt \
 && apt-get autoremove --purge -y \
 && rm /tmp/*

ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV SCALA_HOME=/opt/scala-${SCALA_VERSION}
ENV GRAALVM_HOME=/opt/graalvm-ce-java${JAVA_VERSION}-${GRAALVM_VERSION}
ENV JAVA_HOME=${GRAALVM_HOME}
ENV PATH=${GRAALVM_HOME}/bin:${GRADLE_HOME}/bin:${SCALA_HOME}/bin:${PATH}

RUN gu install native-image

WORKDIR /git/

CMD [ "/bin/bash" ]

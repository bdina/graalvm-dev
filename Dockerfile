# To build image run `docker build --tag graalvm-dev:<version> .`

# Multi-stage image ... creates intermediate layer(s) for doing the graalvm native
# build (this is discarded by docker post-build)
FROM ubuntu:24.04 AS build

ARG JAVA_VERSION=24
ARG GRAALVM_WORKDIR=/git/

ARG SCALA_VERSION=2.13.16
ARG GRADLE_VERSION=8.14.3

ARG SCALA_CLI_VERSION=1.8.3

# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y wget unzip build-essential zlib1g-dev \
 && apt-get autoremove --purge -y \
 && wget https://download.oracle.com/graalvm/${JAVA_VERSION}/latest/graalvm-jdk-${JAVA_VERSION}_linux-x64_bin.tar.gz -P /tmp \
 && mkdir -p /opt/graalvm-jdk-${JAVA_VERSION} \
 && tar zxvf /tmp/graalvm-jdk-${JAVA_VERSION}_linux-x64_bin.tar.gz -C /opt/graalvm-jdk-${JAVA_VERSION} --strip-components 1 \
 && wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
 && unzip -d /opt /tmp/gradle-${GRADLE_VERSION}-bin.zip \
 && wget https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -P /tmp \
 && tar zxvf /tmp/scala-${SCALA_VERSION}.tgz -C /opt \
 && wget https://github.com/Virtuslab/scala-cli/releases/download/v${SCALA_CLI_VERSION}/scala-cli-x86_64-pc-linux.gz -P /tmp \
 && gunzip -c /tmp/scala-cli-x86_64-pc-linux.gz > /usr/local/bin/scala-cli \
 && chmod +x /usr/local/bin/scala-cli


ARG MUSL_VERSION=10
ARG ZLIB_VERSION=1.3.1

RUN wget http://more.musl.cc/${MUSL_VERSION}/x86_64-linux-musl/x86_64-linux-musl-native.tgz -P /tmp \
 && mkdir /opt/musl-${MUSL_VERSION} \
 && tar -zxvf /tmp/x86_64-linux-musl-native.tgz -C /opt/musl-${MUSL_VERSION}/ \
 && wget https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz -P /tmp \
 && tar -zxvf /tmp/zlib-${ZLIB_VERSION}.tar.gz -C /tmp

# Build MUSL to static link into application
ENV TOOLCHAIN_DIR=/opt/musl-${MUSL_VERSION}/x86_64-linux-musl-native

ENV PATH=$PATH:${TOOLCHAIN_DIR}/bin
ENV CC=$TOOLCHAIN_DIR/bin/gcc

WORKDIR /tmp/zlib-${ZLIB_VERSION}
RUN ./configure --prefix=${TOOLCHAIN_DIR} --static \
 && make \
 && make install

ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV SCALA_HOME=/opt/scala-${SCALA_VERSION}
ENV JAVA_HOME=/opt/graalvm-jdk-${JAVA_VERSION}
ENV GRAALVM_HOME=/opt/graalvm-jdk-${JAVA_VERSION}
ENV PATH=${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${SCALA_HOME}/bin:${PATH}

RUN rm -rf /tmp/*

WORKDIR ${GRAALVM_WORKDIR}

CMD [ "/bin/bash" ]

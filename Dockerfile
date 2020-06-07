# To build image run `docker build --tag graalvm-dev:<version> .`

ARG GRAALVM_VERSION=20.0.0
ARG JAVA_VERSION=11
ARG GRAALVM_WORKDIR=/graalvm/src/project

# Multi-stage image ... creates intermediate layer(s) for doing the graalvm native
# build (this is discarded by docker post-build)
FROM oracle/graalvm-ce:${GRAALVM_VERSION}-java${JAVA_VERSION} AS build

ARG SCALA_VERSION=2.13.2
ARG GRADLE_VERSION=6.3

# Install tools required for project
# Run `docker build --no-cache .` to update dependencies
RUN gu install native-image \
 && yum install -y wget unzip libstdc++-static \
 && rm -rf /var/cache/yum \
 && wget https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -P /tmp \
 && unzip -d /opt /tmp/gradle-${GRADLE_VERSION}-bin.zip \
 && wget https://downloads.lightbend.com/scala/${SCALA_VERSION}/scala-${SCALA_VERSION}.tgz -P /tmp \
 && tar zxvf /tmp/scala-${SCALA_VERSION}.tgz -C /opt \
 && rm /tmp/*

ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV SCALA_HOME=/opt/scala-${SCALA_VERSION}
ENV PATH=${GRADLE_HOME}/bin:${SCALA_HOME}/bin:${PATH}

WORKDIR /git/

CMD [ "/bin/bash" ]

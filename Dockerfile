# Build with: docker build --tag graalvm-dev:latest .
# Rebuild without cache to refresh OS packages: docker build --no-cache --tag graalvm-dev:latest .
FROM ubuntu:26.04

RUN DEBIAN_FRONTEND=noninteractive apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      unzip \
      wget \
      zlib1g-dev \
 && DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y \
 && rm -rf /var/lib/apt/lists/*

ARG MUSL_VERSION=11.2.1
ARG ZLIB_VERSION=1.4
ENV TOOLCHAIN_DIR=/opt/musl-${MUSL_VERSION}/x86_64-linux-musl-native

RUN wget -q "https://more.musl.cc/${MUSL_VERSION}/x86_64-linux-musl/x86_64-linux-musl-native.tgz" -P /tmp \
 && wget -q "https://more.musl.cc/${MUSL_VERSION}/x86_64-linux-musl/SHA512SUMS" -P /tmp \
 && (cd /tmp && grep -E '  x86_64-linux-musl-native\.tgz$' SHA512SUMS | sha512sum -c -) \
 && mkdir -p "/opt/musl-${MUSL_VERSION}" \
 && tar -zxf /tmp/x86_64-linux-musl-native.tgz -C "/opt/musl-${MUSL_VERSION}/" \
 && wget -q "https://zlib.net/zlib-${ZLIB_VERSION}.tar.gz" -P /tmp \
 && tar -zxf "/tmp/zlib-${ZLIB_VERSION}.tar.gz" -C /tmp \
 && (cd "/tmp/zlib-${ZLIB_VERSION}" \
      && PATH="${TOOLCHAIN_DIR}/bin:${PATH}" CC="${TOOLCHAIN_DIR}/bin/gcc" ./configure --prefix="${TOOLCHAIN_DIR}" --static \
      && PATH="${TOOLCHAIN_DIR}/bin:${PATH}" make -j"$(nproc)" \
      && PATH="${TOOLCHAIN_DIR}/bin:${PATH}" make install) \
 && rm -rf /tmp/*

ARG GRAAL_VERSION=25i6
ARG JAVA_VERSION=25

RUN wget -q "https://gds.oracle.com/download/graal/${GRAAL_VERSION}/latest/graalvm-jdk-${GRAAL_VERSION}-${JAVA_VERSION}_linux-x64_bin.tar.gz" -P /tmp \
 && mkdir -p "/opt/graalvm-jdk-${JAVA_VERSION}" \
 && tar -zxf "/tmp/graalvm-jdk-${GRAAL_VERSION}-${JAVA_VERSION}_linux-x64_bin.tar.gz" -C "/opt/graalvm-jdk-${JAVA_VERSION}" --strip-components 1 \
 && rm -rf /tmp/*

ARG GRADLE_VERSION=9.9.2

RUN wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -P /tmp \
 && wget -q "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip.sha256" -P /tmp \
 && (cd /tmp && printf '%s  %s\n' "$(cat "gradle-${GRADLE_VERSION}-bin.zip.sha256")" "gradle-${GRADLE_VERSION}-bin.zip" | sha256sum -c -) \
 && unzip -q -d /opt "/tmp/gradle-${GRADLE_VERSION}-bin.zip" \
 && rm -rf /tmp/*

ARG SCALA_VERSION=3.9.0

RUN wget -q "https://github.com/scala/scala3/releases/download/${SCALA_VERSION}/scala3-${SCALA_VERSION}.tar.gz" -P /tmp \
 && wget -q "https://github.com/scala/scala3/releases/download/${SCALA_VERSION}/scala3-${SCALA_VERSION}.tar.gz.sha256" -P /tmp \
 && (cd /tmp && sha256sum -c "scala3-${SCALA_VERSION}.tar.gz.sha256") \
 && tar -zxf "/tmp/scala3-${SCALA_VERSION}.tar.gz" -C /opt \
 && rm -rf /tmp/*

ARG SCALA_CLI_VERSION=1.19.0

RUN wget -q "https://github.com/VirtusLab/scala-cli/releases/download/v${SCALA_CLI_VERSION}/scala-cli-x86_64-pc-linux.gz" -P /tmp \
 && gunzip -c /tmp/scala-cli-x86_64-pc-linux.gz > /usr/local/bin/scala-cli \
 && chmod +x /usr/local/bin/scala-cli \
 && rm -rf /tmp/*

ARG GRAALVM_WORKDIR=/git/

ENV GRADLE_HOME=/opt/gradle-${GRADLE_VERSION}
ENV SCALA_HOME=/opt/scala3-${SCALA_VERSION}
ENV JAVA_HOME=/opt/graalvm-jdk-${JAVA_VERSION}
ENV GRAALVM_HOME=/opt/graalvm-jdk-${JAVA_VERSION}
ENV PATH=${JAVA_HOME}/bin:${GRADLE_HOME}/bin:${SCALA_HOME}/bin:${PATH}:${TOOLCHAIN_DIR}/bin

WORKDIR ${GRAALVM_WORKDIR}

CMD [ "/bin/bash" ]

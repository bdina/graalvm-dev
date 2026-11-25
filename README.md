# graalvm-dev

Docker development environment for Java, Scala 3, Gradle, and GraalVM Native Image builds (including fully static `musl` executables).

## Installed Toolchain

| Tool | Version | Notes |
| --- | --- | --- |
| Ubuntu | `26.04` (LTS) | Base OS (`build-essential`, `zlib1g-dev`, `ca-certificates`) |
| Oracle GraalVM | `25i6` (JDK `25`) | `JAVA_HOME`, `GRAALVM_HOME`, `native-image` |
| Scala | `3.9.0` (LTS) | `SCALA_HOME` (`scala`, `scalac`, `scaladoc`) |
| Gradle | `9.9.2` | `GRADLE_HOME` |
| Scala CLI | `1.19.0` | `/usr/local/bin/scala-cli` |
| musl Toolchain | `11.2.1` | `TOOLCHAIN_DIR`, paired with static `zlib` `1.4` |

## Building the Image

```bash
docker build --tag graalvm-dev:latest .
```

To refresh OS packages without using cached layers:

```bash
docker build --no-cache --tag graalvm-dev:latest .
```

Any version `ARG` in [Dockerfile](Dockerfile) can be overridden at build time with `--build-arg`:

```bash
docker build --build-arg GRADLE_VERSION=9.9.2 --tag graalvm-dev:latest .
```

## Running a Development Container

Run [docker-build](docker-build) from inside any project directory to mount it at `/git/<project>` and open an interactive shell:

```bash
/path/to/graalvm-dev/docker-build
```

You can also run a one-off command or override defaults via environment variables:

```bash
TAG=latest MEMORY=12g /path/to/graalvm-dev/docker-build gradle test
```

Supported environment variables:

- `TAG` — Image tag to run (default: `latest`)
- `MEMORY` — Container memory limit (default: `8g`)
- `DOCKER` — Override Docker command (defaults to `docker`, falling back to `sudo docker`)

## Static Native Images (`musl`)

The container includes the `x86_64-linux-musl` toolchain on `PATH` with static `zlib` installed in `$TOOLCHAIN_DIR`. Build a fully static Linux binary with:

```bash
native-image --static --libc=musl -jar app.jar -o app
```

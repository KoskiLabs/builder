builder
=======

<a href="https://raw.githubusercontent.com/KoskiLabs/builder/master/LICENSE">
    <img src="https://img.shields.io/hexpm/l/plug.svg"
         alt="License: Apache 2">
</a>
<a href="https://travis-ci.org/KoskiLabs/builder/">
    <img src="https://travis-ci.org/KoskiLabs/builder.png"
         alt="Travis Build">
</a>
<a href="https://github.com/KoskiLabs/builder/releases">
    <img src="https://img.shields.io/github/release/KoskiLabs/builder.svg"
         alt="Releases">
</a>
<a href="https://github.com/KoskiLabs/builder/releases">
    <img src="https://img.shields.io/github/downloads/KoskiLabs/builder/total.svg"
         alt="Downloads">
</a>

Provides build isolation through Docker with automatic detection for common build tools (e.g. Maven, Gradle, NPM, Go).

Quick Start
-----------

1) Download `build` script from the [latest release](https://github.com/Koskilabs/builder/releases/latest) script into your project in the directory where you execute your build from (typically the project root directory).

2) Make the `build` script executable (e.g. `chmod +x build`).

3) Create a `.build` file in the same directory as the `build` script.

4) Populate the `.build` with at least the contents from the table below for your build tool.

5) Execute your build by invoking `build` and passing it your usual build tool arguments for your build tool.

Build Tool   | `.build` Contents                | Build Command
------------ | -------------------------------- | -------------
Maven        | BUILD_DOCKER_IMAGE=centos:latest | `./build clean verify`
Gradle       | BUILD_DOCKER_IMAGE=centos:latest | `./build clean build`
SBT          | BUILD_DOCKER_IMAGE=centos:latest | `./build clean package`
NPM          | BUILD_DOCKER_IMAGE=node:latest   | `./build build`
Go           | BUILD_DOCKER_IMAGE=golang:latest | `./build build`

If your build tool is not listed above then it will not be auto detected. Feel free to file an issue against the
project. However, in the meantime you can specify your build tool manually; specifically, the command to run by
adding the `BUILD_TOOL` property into your `.build` file (e.g. `BUILD_TOOL="make"`).

For Maven, Gradle and SBT projects wishing to use a smaller Alpine based build image check out
[koskilabs/builder-alpine](https://hub.docker.com/r/koskilabs/builder-alpine/) image.

In general, you control your project's build execution environment via `BUILD_DOCKER_IMAGE` to provide the required
dependencies for your project's build. You may also specify the Docker registry via `BUILD_DOCKER_REGISTRY`.

More information on customizing the build can be found in the next section.

Usage
-----

The builder may be configured by any combination of these four forms of configuration is permissible. The
order of precedence for configuration from highest to lowest is:

1) Command Line
2) .build (working directory)
3) ~/.build (home directory)
4) Environment

The only required configuration setting is `BUILD_DOCKER_IMAGE` which must be set the Docker image name and
optional tag separated by a colon (e.g. `NAME[:TAG]`).

By default the build script attempts to auto-detect the build tool based on the contents of the project. The
auto detection will set the command to execute (`BUILD_TOOL`), any arguments always passed to it (`BUILD_ARGUMENTS`)
and any values present in the environment (`BUILD_ENVIRONMENT`).

You can then invoke `./build` and pass it any additional arguments you wish to supply to your build tool.

The default auto-detection behavior is disabled if you specify `BUILD_TOOL`.

If you wish to only augment the arguments or environment that are always passed and set, you should not
disable auto detection but instead use `BUILD_ADDITIONAL_ARGUMENTS` and `BUILD_ADDITIONAL_ENVIRONMENT`.

### Configuration

* BUILD_DOCKER_IMAGE : The name and tag separated by a colon of the Docker image to build in. Required.
* BUILD_DOCKER_REGISTRY : The address of the registry to use. Optional.
* BUILD_ADDITIONAL_ARGUMENTS : Any arguments to always pass to the build tool in addition to auto-detected ones. Optional.
* BUILD_ADDITIONAL_ENVIRONMENT : Any values to always set in the environment in addition to auto-detected ones. Optional.
* BUILD_TOOL : The command to execute for the build. Auto detected. Optional.
* BUILD_ARGUMENTS : The arguments to always pass to the build tool. Auto detected. Optional.
* BUILD_ENVIRONMENT : The values to always set in the environment. Auto detected. Optional.
* BUILD_EXPOSED_PORTS : Any port mappings for Docker (e.g. `8080:80`). Optional.
* BUILD_DOCKER_ARGS : Any additional arguments for Docker. Optional.
* BUILD_RELEASE : Version of Build (e.g. `0.1.0` or `latest`). Optional.
* BUILD_TARGET : Directory to store build scripts (e.g. '/var/tmp'). Optional.
* BUILD_FORCE_NATIVE : Force the build to run in the current environment and not wrapped in a Docker invocation. Optional.
* BUILD_CONTAINER_NAME : Name given to the docker container. Optional.
* BUILD_LOCAL_HOST_IP : The IP address of the host running the Docker daemon. Auto detected. Optional.
* BUILD_LOCAL_DIRECTORY : The path of the project on the host running the Docker daemon. Auto detected. Optional.
* BUILD_CACHE_ROOT : The path to the builder cache root. Optional.
* BUILD_CACHE_PROJECT : The path to the project specific cache. Optional.
* BUILD_CACHE_JDK : The [JDK Wrapper](https://github.com/KoskiLabs/jdk-wrapper) cache path. Optional.
* BUILD_CACHE_MAVEN : The path to the project specific Maven cache. Optional.
* BUILD_CACHE_IVY : The path to the project specific Ivy cache. Optional.
* BUILD_CACHE_SBT : The path to the project specific SBT cache. Optional.
* BUILD_CACHE_GRADLE : The path to the project specific Gradle cache. Optional.
* BUILD_DISABLE_GO : Whether to not attempt Go project auto-detection. Optional.
* BUILD_DISABLE_JDK_WRAPPER : Whether to not attempt [JDK Wrapper](https://github.com/KoskiLabs/jdk-wrapper) auto-detection. Optional.
* BUILDER_VERBOSE : Log build actions to standard out. Optional.

By default the Docker registry is [Docker Hub](https://hub.docker.com)<br/>
By default the release is `latest`.<br/>
By default target directory is `~/.builder`.<br/>
By default builds are executed in Docker.<br/>
By default docker container is named is a sanitized version of the working path.<br/>
By default Go project auto-detection is enabled; for large non-Go projects this may be slow.<br/>
By default [JDK Wrapper](https://github.com/KoskiLabs/jdk-wrapper) auto-detection is enabled.<br/>
By default the build script does not log.

Prerequisites
-------------

The builder script may work with other versions or with suitable replacements but has been tested with these:

* docker (17.12.0-ce-mac55)
* posix shell: bash (4.4.12), BusyBox (1.25.1)
* awk (4.1.4)
* curl (7.51.0)
* grep (3.0)
* sed (4.4)
* sha1sum (8.27) or shasum (5.84) or md5
* ip  -- preferred
* ifconfig -- fallback

Releasing
---------

* Determine the next release version `X.Y.Z` using [semantic versioning](https://semver.org/) based on changes since the last release.
* Create a tag to mark the release:
```
$ git tag -a "X.Y.Z" -m "X.Y.Z"
```
* Push the tag to the origin to trigger the release:
```
$ git push origin --tags
```
* Verify the release was created in [Github](https://github.com/KoskiLabs/builder/releases)

License
-------

Published under Apache Software License 2.0, see LICENSE

&copy; Ville Koskela, 2018

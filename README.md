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
    <img src="https://img.shields.io/github/release/KoskiLabs/jdk-wrapper.svg"
         alt="Releases">
</a>
<a href="https://github.com/KoskiLabs/builder/releases">
    <img src="https://img.shields.io/github/downloads/KoskiLabs/builder/total.svg"
         alt="Downloads">
</a>

Provides build isolation through Docker with automatic detection for common build tools (e.g. Maven, Gradle, NPM, Go).

Quick Start
-----------

Usage
-----

Finally, any combination of these four forms of configuration is permissible. The order of precedence for configuration from highest to lowest is:

1) Command Line
2) .build (working directory)
3) ~/.build (home directory)
4) Environment

### Configuration

* BUILD_DOCKER_IMAGE :
* BUILD_DOCKER_REGISTRY :
* BUILD_ADDITIONAL_ARGUMENTS :
* BUILD_ADDITIONAL_ENVIRONMENT
* BUILD_TOOL :
* BUILD_ARGUMENTS :
* BUILD_ENVIRONMENT :
* BUILD_EXPOSED_PORTS :
* BUILD_DOCKER_ARGS :
* BUILD_RELEASE : Version of Build (e.g. 0.1.0 or latest). Optional.
* BUILD_TARGET : Directory to store build scripts (e.g. '/var/tmp'). Optional.
* BUILD_FORCE_NATIVE : Force the build to run in the current environment. Optional.
* BUILD_CONTAINER_NAME : Name given to the docker container. Optional.
* BUILD_LOCAL_HOST_IP :
* BUILD_LOCAL_DIRECTORY :
* BUILD_CACHE_ROOT :
* BUILD_SOURCE_CACHE_ROOT :
* BUILD_CACHE_PROJECT :
* BUILD_CACHE_MAVEN :
* BUILD_CACHE_IVY :
* BUILD_CACHE_SBT :
* BUILD_CACHE_GRADLE :
* BUILD_DISABLE_GO :
* BUILD_DISABLE_JDK_WRAPPER :
* BUILDER_VERBOSE : Log build actions to standard out. Optional.

By default the release is `latest`.<br/>
By default target directory is `~/.builder`.<br/>
By default builds are executed in docker.<br/>
By default docker container is named is a sanitized version of the working path.<br/>
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

#!/bin/sh

# Copyright 2018 Ville Koskela
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# For documentation please refer to:
# https://github.com/KoskiLabs/builder/blob/master/README.md

log_err() {
  l_prefix=$(date  +'%H:%M:%S')
  printf "[%s] %s\n" "${l_prefix}" "$@" 1>&2;
}

log_out() {
  if [ -n "${BUILD_VERBOSE}" ]; then
    l_prefix=$(date  +'%H:%M:%S')
    printf "[%s] %s\n" "${l_prefix}" "$@"
  fi
}

safe_command() {
  l_command=$1
  log_out "${l_command}";
  eval $1
  l_result=$?
  if [ "${l_result}" -ne "0" ]; then
    log_err "ERROR: ${l_command} failed with ${l_result}"
    exit 1
  fi
}

save () {
 # See: http://www.etalabs.net/sh_tricks.html
 for i do printf %s\\n "$i" | sed "s/'/'\\\\''/g;1s/^/'/;\$s/\$/' \\\\/" ; done
 printf " "
}

rand() {
 awk 'BEGIN {srand();printf "%d\n", (rand() * 10^8);}'
}

import_file() {
  l_file="${1}"
  if [ -f "${l_file}" ]; then
    . "${l_file}"
  fi
}

# Import user configuration: from environment
l_fifo="${TMPDIR:-/tmp}/$$.$(rand)"
safe_command "mkfifo \"${l_fifo}\""
env > "${l_fifo}" &
while IFS='=' read -r name value
do
  build_arg=$(echo "${name}" | grep 'BUILD_.*')
  if [ -n "${build_arg}" ]; then
    eval "${name}=\"${value}\""
  fi
done < "${l_fifo}"
safe_command "rm \"${l_fifo}\""

# Import user configuration: from .build file in home directory
import_file "${HOME}/.build"

# Import user configuration: from .build file in current directory
import_file "./.build"

# Import user configuration: from command line arguments
in_command=
command_args=""
for arg in "$@"; do
  if [ -z "${in_command}" ]; then
    build_arg=$(echo "${arg}" | grep 'BUILD_.*')
    if [ -n "${build_arg}" ]; then
      eval "${build_arg}"
    else
      in_command="true"
    fi
  fi
  if [ -n "${in_command}" ]; then
    command_args="${command_args} \"${arg}\""
  fi
done
eval "set -- ${command_args}"

# Fallback to default configuration
if [ -z "${BUILD_CONTAINER_NAME}" ]; then
  # Create a unique and valid docker name
  # See: https://github.com/docker/docker/issues/3138
  name="$(pwd | sed -E 's/^\/?(.*)$/\1/' | tr -d '\n')"
  BUILD_CONTAINER_NAME="$(printf '%s' "${name}" | sed 's/[^a-zA-Z0-9_-]/_/g')"
  log_out "Defaulted to docker name ${BUILD_CONTAINER_NAME}"
fi
if [ -z "${BUILD_LOCAL_HOST_IP}" ]; then
  if command -v ip > /dev/null 2>&1; then
    BUILD_LOCAL_HOST_IP=$(ip route get 1 | awk '{print $NF;exit}')
  elif command -v ifconfig > /dev/null 2>&1; then
    BUILD_LOCAL_HOST_IP=$(ifconfig | awk '/inet / && $2 != "127.0.0.1"{print $2}' | head -n 1)
  else
    log_err "ERROR: Unable to determine local ip address; please configure BUILD_LOCAL_HOST_IP"
    exit 1
  fi
  log_out "Defaulted local host ip to ${BUILD_LOCAL_HOST_IP}"
fi
if [ -z "${BUILD_LOCAL_DIRECTORY}" ]; then
  BUILD_LOCAL_DIRECTORY=$(pwd)
  log_out "Defaulted local directory to ${BUILD_LOCAL_DIRECTORY}"
fi
if [ -z "${BUILD_CACHE_ROOT}" ]; then
  BUILD_CACHE_ROOT="${HOME}/.builder"
  log_out "Defaulted to cache root ${BUILD_CACHE_ROOT}"
fi
if [ -z "${BUILD_CACHE_JDK}" ]; then
  # IMPORTANT: This should match the default in KoskiLabs/jdk-wrapper
  BUILD_CACHE_JDK="${HOME}/.jdk"
  log_out "Defaulted to jdk cache ${BUILD_CACHE_JDK}"
fi
if [ -z "${BUILD_CACHE_PROJECT}" ]; then
  BUILD_CACHE_PROJECT="${BUILD_CACHE_ROOT}/${BUILD_CONTAINER_NAME}"
  log_out "Defaulted to project cache ${BUILD_CACHE_PROJECT}"
fi
if [ -z "${BUILD_CACHE_MAVEN}" ]; then
  BUILD_CACHE_MAVEN="${BUILD_CACHE_PROJECT}/m2"
  log_out "Defaulted to maven cache ${BUILD_CACHE_MAVEN}"
fi
if [ -z "${BUILD_CACHE_IVY}" ]; then
  BUILD_CACHE_IVY="${BUILD_CACHE_PROJECT}/ivy"
  log_out "Defaulted to ivy cache ${BUILD_CACHE_IVY}"
fi
if [ -z "${BUILD_CACHE_SBT}" ]; then
  BUILD_CACHE_SBT="${BUILD_CACHE_PROJECT}/sbt"
  log_out "Defaulted to sbt cache ${BUILD_CACHE_SBT}"
fi
if [ -z "${BUILD_CACHE_GRADLE}" ]; then
  BUILD_CACHE_GRADLE="${BUILD_CACHE_PROJECT}/gradle"
  log_out "Defaulted to gradle cache ${BUILD_CACHE_GRADLE}"
fi
if [ -z "${BUILD_CACHE_GO}" ]; then
  BUILD_CACHE_GO="${BUILD_CACHE_PROJECT}/go"
  log_out "Defaulted to go cache ${BUILD_CACHE_GO}"
fi

# Build tool auto detection
# NOTE: This happens after loading configuration and defaults to allow those
# values to be used by auto-detection; however, auto-detected values are only
# used if configuration did not specify a value for BUILD_TOOL. In this case
# the auto-detection only sets BUILD_TOOL, BUILD_ARGUMENTS and BUILD_ENVIRONMENT.
if [ -z "${BUILD_TOOL}" ]; then
  auto_build_tool=
  auto_build_arguments=
  auto_build_environment=
  if [ -f "pom.xml" ]; then
    # Maven Support
    log_out "Detected project using Maven build tool"
    auto_build_tool="mvn"
    auto_build_environment="\"MAVEN_OPTS=-XX:+TieredCompilation -XX:TieredStopAtLevel=1\""
    if [ -f "mvnw" ]; then
      auto_build_tool="./mvnw"
      auto_build_environment="${auto_build_environment} \"MAVEN_USER_HOME=${BUILD_CACHE_MAVEN}\""
    fi
    common_arguments="-Dmaven.repo.local=${BUILD_CACHE_MAVEN} -DdockerHostIp=${BUILD_LOCAL_HOST_IP} -DdockerHostPath=${BUILD_LOCAL_DIRECTORY}"
    if [ -f "settings.xml" ]; then
      common_arguments="${common_arguments} --settings settings.xml"
    fi
    pass_through_arguments="${common_arguments}"
    for arg in "$@"; do
      if [ -n "${past_build_args}" ]; then
        if case "${arg}" in "-D"*) true;; "-P"*) true;; *) false;; esac; then
          pass_through_arguments="${pass_through_arguments} ${arg}"
        fi
      fi
    done
    auto_build_arguments="-U ${common_arguments} \"-Darguments=${pass_through_arguments}\""
  elif [ -f "build.sbt" ]; then
    # SBT Support
    log_out "Detected project using SBT build tool"
    sbt_boot="${BUILD_CACHE_SBT}/boot"
    ivy_home="${BUILD_CACHE_IVY}"
    auto_build_tool="sbt"
    auto_build_arguments="-Dsbt.global.base=${BUILD_CACHE_SBT}/1.0 -Dsbt.boot.directory=${sbt_boot} -Dsbt.ivy.home=${ivy_home}"
    if [ -f "repositories" ]; then
     auto_build_arguments="${auto_build_arguments} -Dsbt.override.build.repos=true -Dsbt.repository.config=repositories"
    fi
    if [ -f "sbt" ]; then
      auto_build_tool="./sbt"
      auto_build_arguments="${auto_build_arguments} -sbt-launch-dir ${BUILD_CACHE_SBT}/launcher -sbt-boot ${sbt_boot} -ivy ${ivy_home}"
    fi
  elif [ -f "build.gradle" ]; then
    # Gradle Support
    log_out "Detected project using Gradle build tool"
    auto_build_tool="gradle"
    auto_build_environment="\"GRADLE_USER_HOME=${BUILD_CACHE_GRADLE}\""
    if [ -f "gradlew" ]; then
      auto_build_tool="./gradlew"
    fi
  elif [ -f "package.json" ]; then
    # NodeJS Support
    log_out "Detected project using NPM build tool"
    auto_build_tool="npm"
  elif [ -z "${BUILD_DISABLE_GO}" ]; then
    if [ "$(find . -type f -name '*.go' | head -n 1 | wc -l)" -gt 0 ]; then
      # Go Support
      log_out "Detected project using Go build tool"
      auto_build_tool="go"
      auto_build_environment="\"GOPATH=$(pwd)\" \"GOCACHE=${BUILD_CACHE_GO}\""
    fi
  fi

  BUILD_TOOL="${auto_build_tool}"
  BUILD_ARGUMENTS="${auto_build_arguments}"
  BUILD_ENVIRONMENT="${auto_build_environment}"
fi

# JDK Wrapper Support
if [ -z "${BUILD_DISABLE_JDK_WRAPPER}" ]; then
  if [ -f "jdk-wrapper.sh" ]; then
   BUILD_TOOL="./jdk-wrapper.sh ${BUILD_TOOL}"
   BUILD_ENVIRONMENT="${BUILD_ENVIRONMENT} \"JDKW_TARGET=${BUILD_CACHE_JDK}\""
  fi
fi

# Check required configuration
if [ -z "${BUILD_TOOL}" ]; then
  log_err "ERROR: No value specified or discovered for BUILD_TOOL"
  exit 1
fi
if [ -z "${BUILD_DOCKER_IMAGE}" ]; then
  log_err "ERROR: No value specified for BUILD_DOCKER_IMAGE"
  exit 1
fi

# Check for docker daemon unless forcing native build
if [ -z "${BUILD_FORCE_NATIVE}" ]; then
 if command -v docker > /dev/null 2>&1; then
   if ! docker ps > /dev/null 2>&1; then
     log_err "ERROR: Docker daemon not responding."
     exit 1
   fi
 else
   log_err "ERROR: Required docker command not found."
   exit 1
 fi
fi

# Merge additional
BUILD_ARGUMENTS="${BUILD_ARGUMENTS} ${BUILD_ADDITIONAL_ARGUMENTS}"
BUILD_ENVIRONMENT="${BUILD_ENVIRONMENT} ${BUILD_ADDITIONAL_ENVIRONMENT}"

# Ensure registry if set ends in a slash
if [ ! "X${BUILD_DOCKER_REGISTRY}" = "X" ]; then
 if [ "${BUILD_DOCKER_REGISTRY%/}" = "${BUILD_DOCKER_REGISTRY}" ]; then
   BUILD_DOCKER_REGISTRY="${BUILD_DOCKER_REGISTRY}/"
 fi
fi

# Initialize Cache Directories
safe_command "mkdir -p \"${BUILD_CACHE_ROOT}\""
safe_command "mkdir -p \"${BUILD_CACHE_JDK}\""
safe_command "mkdir -p \"${BUILD_CACHE_MAVEN}\""
safe_command "mkdir -p \"${BUILD_CACHE_IVY}\""
safe_command "mkdir -p \"${BUILD_CACHE_SBT}\""
safe_command "mkdir -p \"${BUILD_CACHE_GRADLE}\""
safe_command "mkdir -p \"${BUILD_CACHE_GO}\""
safe_command "mkdir -p \"${BUILD_CACHE_PROJECT}\""

build_command=
if [ -z "${BUILD_FORCE_NATIVE}" ]; then
  # Stop any previous running instances of this build container
  running_containers=$(docker ps | grep "${BUILD_CONTAINER_NAME}")
  if [ -n "${running_containers}" ]; then
    printf "Stopping docker container...\\n"
    docker kill "${BUILD_CONTAINER_NAME}"
  fi

  # Cleanup any previously run instances of this build container
  all_containers=$(docker ps -a | grep "${BUILD_CONTAINER_NAME}")
  if [ -n "${all_containers}" ]; then
    printf "Removing docker container...\\n"
    docker rm -f "${BUILD_CONTAINER_NAME}"
  fi

  # Map the build environment
  args_array=$(save "$@")
  eval "set -- ${BUILD_ENVIRONMENT}"
  docker_environment=""
  for e do docker_environment="${docker_environment} -e '${e}'"; done
  eval "set -- ${args_array}"

  # Map the ports to expose
  args_array=$(save "$@")
  eval "set -- ${BUILD_EXPOSED_PORTS}"
  docker_port_map=""
  for p do docker_port_map="${docker_port_map} -p '${p}'"; done
  eval "set -- ${args_array}"

  # Map the user
  if [ -n "${USER}" ]; then
    docker_user="${USER}"
    docker_user_id=$(id -u "${USER}")
  else
    printf "WARNING: \$USER not defined locally!\\n"
    docker_user="dockeruser"
    docker_user_id="1000"
  fi

  # Volume mount the ssh agent socket
  volume_ssh_auth_sock=""
  if [ -n "${SSH_AUTH_SOCK}" ]; then
    docker_environment="${docker_environment} -e 'SSH_AUTH_SOCK=/ssh-agent'"
    volume_ssh_auth_sock="-v '$SSH_AUTH_SOCK:/ssh-agent'"
  fi

  # Mark terminals interactive
  interactive=""
  if tty -s; then
    interactive="-it"
  fi

  # Assemble the build command
  build_command="docker run --name '${DOCKER_NAME}' \
    ${interactive} \
    ${docker_environment} \
    -e DOCKER_HOST_IP=${BUILD_LOCAL_HOST_IP} \
    -e USER=${docker_user} \
    ${docker_port_map} \
    -u ${docker_user_id} \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v '${HOME}/.gitconfig:/home/${docker_user}/.gitconfig' \
    -v '${HOME}/.ssh:/home/${docker_user}/.ssh' \
    -v '$(pwd):/$(pwd)' \
    -v '${BUILD_CACHE_ROOT}:${BUILD_CACHE_ROOT}' \
    -v '${BUILD_CACHE_JDK}:${BUILD_CACHE_JDK}' \
    ${volume_ssh_auth_sock} \
    -w '/$(pwd)' \
    ${BUILD_DOCKER_ARGS} \
    '${BUILD_DOCKER_REGISTRY}${BUILD_DOCKER_IMAGE}' \
    ${BUILD_TOOL} ${BUILD_ARGUMENTS} $*"
else
  # Assemble the build environment variable exports
  args_array=$(save "$@")
  eval "set -- ${BUILD_ENVIRONMENT}"
  eval_environment=""
  for e do eval_environment="${eval_environment} export '${e}';"; done
  eval "set -- ${args_array}"

  # Assemble the build command
  build_command="${eval_environment} ${BUILD_TOOL} ${BUILD_ARGUMENTS} $*"
fi

log_out "Building..."
log_out "${build_command}"
eval "${build_command}"
exit $?

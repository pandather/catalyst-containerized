#!/bin/bash

# Used to create Gentoo seed and portage containers simply by specifying a
# SEED env variable.
# Example usage: SEED=./stage3-amd64-latest.tar.xz ./build.sh

if [[ -z "$SEED" ]]; then
	echo "No seed specified"
	exit 1
fi

if [[ -z "$CONTAINER_NAME" ]]; then
	CONTAINER_NAME=catalyst
fi

# Split the TARGET variable into three elements separated by hyphens
#IFS=- read -r NAME ARCH SUFFIX <<< "${TARGET}"

VERSION=${VERSION:-$(date -u +%Y%m%d)}
if [[ "${NAME}" == "portage" ]]; then
	VERSION_SUFFIX=":${VERSION}"
else
	VERSION_SUFFIX="-${VERSION}"
fi

ORG=${ORG:-gentoo}

case $ARCH in
	"amd64" | "arm64")
		DOCKER_ARCH="${ARCH}"
		MICROARCH="${ARCH}"
		;;
	"armv"*)
		# armv6j_hardfp -> arm/v6
		# armv7a_hardfp -> arm/v7
		DOCKER_ARCH=$(echo "$ARCH" | sed -e 's#arm\(v.\).*#arm/\1#g')
		MICROARCH="${ARCH}"
		ARCH="arm"
		;;
	"ppc64le")
		DOCKER_ARCH="${ARCH}"
		MICROARCH="${ARCH}"
		ARCH="ppc"
		;;
	"s390x")
		DOCKER_ARCH="${ARCH}"
		MICROARCH="${ARCH}"
		ARCH="s390"
		;;
	"x86")
		DOCKER_ARCH="386"
		MICROARCH="i686"
		;;
	*)  # portage
		DOCKER_ARCH="amd64"
		;;
esac

# Handle targets with special characters in the suffix
if [[ "${TARGET}" == "stage3-${ARCH}-hardened-nomultilib" ]]; then
	SUFFIX="hardened+nomultilib"
fi

# Prefix the suffix with a hyphen to make sure the URL works
if [[ -n "${SUFFIX}" ]]; then
	SUFFIX="-${SUFFIX}"
fi

docker buildx build \
	--file "catalyst.Dockerfile" \
	--build-arg ARCH="${ARCH}" \
	--build-arg MICROARCH="${MICROARCH}" \
	--build-arg SUFFIX="${SUFFIX}" \
	--build-arg SEED="${SEED}" \
	--tag "${ORG}/${CONTAINER_NAME}:${ARCH}" \
	--platform "linux/${DOCKER_ARCH}" \
	--progress plain \
	--load \
	.

#!/bin/sh

CONTAINER_BUILD_DIR=${CONTAINER_BUILD_DIR:=$PWD}

if [[ -z "$TARGET" ]]; then
        echo "TARGET environment variable must be set e.g. TARGET=stage3-amd64-openrc."
        exit 1
fi

# Split the TARGET variable into three elements separated by hyphens
IFS=- read -r NAME ARCH SUFFIX <<< "${TARGET}"

# Handle targets with special characters in the suffix
if [[ "${TARGET}" == "${NAME}-${ARCH}-hardened-nomultilib" ]]; then
        SUFFIX="hardened+nomultilib"
fi

ORG=${ORG:-gentoo}
VERSION=${VERSION:-$(date -u +%Y%m%d)}
VERSION_SUFFIX="-${VERSION}"
export ORG VERSION TARGET

${CONTAINER_BUILD_DIR}/build.sh

ret=$?
if [[ ret -ne 0 ]]; then
	echo "container build failed"
	exit 1
fi

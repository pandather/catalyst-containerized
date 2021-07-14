#!/bin/sh

CATALYST_CACHE_DIR=${CATALYST_CACHE_DIR:=/var/tmp/catalyst}
CATALYST_REPO_DIR=${CATALYST_REPO_DIR:=$CATALYST_CACHE_DIR/repos/gentoo}
CATALYST_BUILDS_DIR=${CATALYST_BUILDS_DIR:=$CATALYST_CACHE_DIR/builds}
CATALYST_SNAPSHOTS_DIR=${CATALYST_SNAPSHOTS_DIR:=$CATALYST_CACHE_DIR/snapshots}
CATALYST_PACKAGES_DIR=${CATALYST_PACKAGES_DIR:=$CATALYST_CACHE_DIR/packages}

if [[ -z "$TARGET" ]]; then
        echo "TARGET environment variable must be set e.g. TARGET=stage3-amd64-openrc."
        exit 1
fi

CONTAINER_BUILD_DIR=${CONTAINER_BUILD_DIR:=$PWD}

# Split the TARGET variable into three elements separated by hyphens
IFS=- read -r NAME ARCH SUFFIX <<< "${TARGET}"

# Handle targets with special characters in the suffix
if [[ "${TARGET}" == "${NAME}-${ARCH}-hardened-nomultilib" ]]; then
        SUFFIX="hardened+nomultilib"
fi

ORG=${ORG:-gentoo}
VERSION=${VERSION:-$(date -u +%Y%m%d)}
VERSION_SUFFIX="-${VERSION}"
CONTAINER_NAME=${CONTAINER_NAME:=$TARGET$VERSION_SUFFIX}
export ORG VERSION TARGET

if [[ ! -f "${SPEC}" ]]; then
        echo "No spec specified, or passed relative path, absolute path required."
        exit 1
fi

mkdir -p $CATALYST_REPO_DIR $CATALYST_BUILDS_DIR $CATALYST_SNAPSHOTS_DIR $CATALYST_PACKAGES_DIR

docker rm -f ${CONTAINER_NAME}
docker run -it --privileged --name ${CONTAINER_NAME} \
				 --mount type=bind,source=${CATALYST_BUILDS_DIR},target=/var/tmp/catalyst/builds \
				 --mount type=bind,source=${CATALYST_SNAPSHOTS_DIR},target=/var/tmp/catalyst/snapshots \
				 --mount type=bind,source=${CATALYST_PACKAGES_DIR},target=/var/tmp/catalyst/packages \
				 --mount type=bind,source=${CATALYST_REPO_DIR},target=/var/db/repos/gentoo \
				 --mount type=bind,source=${SPEC},target=/mnt/catalyst/toExec.spec,readonly \
				 --mount type=bind,source=${CONTAINER_BUILD_DIR}/container-script.sh,target=/mnt/catalyst/container-script.sh,readonly \
				 ${ORG}/catalyst:${TARGET}${VERSION_SUFFIX}
docker rm -f ${CONTAINER_NAME}

#!/bin/sh

CATALYST_CACHE_DIR=${CATALYST_CACHE_DIR:=/var/tmp/catalyst}
CATALYST_REPO_DIR=${CATALYST_REPO_DIR:=/var/db/repos/gentoo}
#CATALYST_BUILDS_DIR=${CATALYST_BUILDS_DIR:=$CATALYST_CACHE_DIR/builds}
#CATALYST_SNAPSHOTS_DIR=${CATALYST_SNAPSHOTS_DIR:=$CATALYST_CACHE_DIR/snapshots}
CATALYST_PACKAGES_DIR=${CATALYST_PACKAGES_DIR:=$CATALYST_CACHE_DIR/packages}

if [[ ! -f "paths.sh" ]]; then
    echo "paths.sh should be defined"
    exit 1
fi
if [[ -z "$TARGET" ]]; then
        echo "TARGET environment variable must be set e.g. TARGET=stage3-amd64-openrc."
        exit 1
fi
if [[ -z "$SPECS" ]]; then
        echo "Specs environment variable must be set e.g. specs=$PWD/specs."
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

#if [[ ! -f "${BUILD}" ]]; then
#   echo "no build specified, or passed relative path absolute path required."
#   exit 1
#fi
#if [[ ! -f "${SPEC}" ]]; then
#        echo "No spec specified, or passed relative path, absolute path required."
#        exit 1
#fi

mkdir -p $CATALYST_REPO_DIR $CATALYST_PACKAGES_DIR /var/cache/distfiles /var/cache/binpkgs

docker rm -f ${CONTAINER_NAME}
docker run -it --privileged --name ${CONTAINER_NAME} \
       `cat paths.sh` \
				 --mount type=bind,source=${SPECS},target=/mnt/catalyst/specs,readonly \
				 --mount type=bind,source=${CONTAINER_BUILD_DIR}/container-script.sh,target=/mnt/catalyst/container-script.sh,readonly \
				 ${ORG}/catalyst:${TARGET}${VERSION_SUFFIX}
docker rm -f ${CONTAINER_NAME}

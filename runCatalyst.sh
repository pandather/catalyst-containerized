#!/bin/sh

CATALYST_CONTAINER_CACHE_DIR=${CATALYST_CONTAINER_CACHE_DIR:=/var/tmp/catalyst-container/cache}
CATALYST_CONTAINER_DISTFILES_CACHE_DIR=${CATALYST_CONTAINER_DISTFILES_CACHE_DIR:=$CATALYST_CONTAINER_CACHE_DIR/distfiles}
CATALYST_CONTAINER_BINPKGS_CACHE_DIR=${CATALYST_CONTAINER_DISTFILES_CACHE_DIR:=$CATALYST_CONTAINER_CACHE_DIR/binpkgs}
CATALYST_CONTAINER_PORTDIR=${CATALYST_CONTAINER_PORTDIR:=/var/tmp/catalyst-container/repos/gentoo}
CATALYST_CACHE_DIR=${CATALYST_CACHE_DIR:=/var/tmp/catalyst}
CATALYST_BUILDS_DIR=${CATALYST_BUILDS_DIR:=$CATALYST_CACHE_DIR/builds}
CATALYST_SNAPSHOTS_DIR=${CATALYST_SNAPSHOTS_DIR:=$CATALYST_CACHE_DIR/snapshots}
CATALYST_PACKAGES_DIR=${CATALYST_PACKAGES_DIR:=$CATALYST_CACHE_DIR/packages}

ARCH=${ARCH:=amd64}
CONTAINER_NAME=${CONTAINER_NAME:=catalyst}
CONTAINER_BUILD_DIR=${CONTAINER_BUILD_DIR:=$PWD}

if [[ -z "${SPEC}" ]]; then
        echo "No spec specified"
        exit 1
fi

mkdir -p ${CATALYST_CONTAINER_DISTFILES_CACHE_DIR} ${CATALYST_CONTAINER_BINPKGS_CACHE_DIR} ${CATALYST_BUILDS_DIR}/default ${CATALYST_PACKAGES_DIR} ${CATALYST_SNAPSHOTS_DIR} ${BUILDSH_SCRIPT_DIR} ${PORTDIR}

cp ${SEED} ${CONTAINER_BUILD_DIR}/stage.tar.xz
cp ${SPEC} ${CONTAINER_BUILD_DIR}/toExec.spec

docker rm -f ${CONTAINER_NAME}
export CONTAINER_NAME ARCH
${PWD}/build.sh \
 && docker run -it --privileged --name ${CONTAINER_NAME} \
				 --mount type=bind,source=${CATALYST_CONTAINER_DISTFILES_CACHE_DIR}/,target=/var/cache/distfiles/ \
				 --mount type=bind,source=${CATALYST_CONTAINER_BINPKGS_CACHE_DIR}/,target=/var/cache/binpkgs/ \
				 --mount type=bind,source=${CATALYST_BUILDS_DIR}/,target=/var/tmp/catalyst/builds/ \
				 --mount type=bind,source=${CATALYST_SNAPSHOTS_DIR}/,target=/var/tmp/catalyst/snapshots/ \
				 --mount type=bind,source=${CATALYST_PACKAGES_DIR}/,target=/var/tmp/catalyst/packages/ \
				 --mount type=bind,source=${CATALYST_CONTAINER_PORTDIR}/,target=/var/db/repos/gentoo/ \
				 gentoo/${CONTAINER_NAME}:${ARCH}

rm ${CONTAINER_BUILD_DIR}/stage.tar.xz
rm ${CONTAINER_BUILD_DIR}/toExec.spec

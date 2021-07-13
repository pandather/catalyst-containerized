#!/bin/bash
if [[ ! -d ${HOME}/.docker/cli-plugins/docker-buildx ]]; then
	../installDockerBuildxPluginBinary.sh
fi

if [[ ! -f ./stage3-amd64-openrc-latest.tar.xz ]]; then
	wget https://gentoo.osuosl.org/releases/amd64/autobuilds/current-stage3-amd64-openrc/stage3-amd64-openrc-20210711T170538Z.tar.xz -O stage3-amd64-openrc-latest.tar.xz
fi
cd ..
export CATALYST_CONTAINER_CACHE_DIR=~/catalyst-container-tmp CATALYST_CACHE_DIR=~/catalyst-tmp SEED=./example/stage3-amd64-openrc-latest.tar.xz SPEC=./example/stage1.spec
./runCatalyst.sh


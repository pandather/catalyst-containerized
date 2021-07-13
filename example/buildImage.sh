#!/bin/bash
cd ..
if [[ ! -d ${HOME}/.docker/cli-plugins/docker-buildx ]]; then
	./installDockerBuildxPluginBinary.sh
fi
source ./example/env.sh
export TARGET
./buildCatalyst.sh


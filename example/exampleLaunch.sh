#!/bin/bash
if [[ ! -f "$1" ]]; then
    "Please specify a spec like 'exampleLaunch.sh ${PWD}/stage1.spec'"
fi
cd ..
source ./example/env.sh
export CATALYST_CONTAINER_CACHE_DIR CATALYST_CACHE_DIR TARGET
SPEC="$1" ./runCatalyst.sh

#!/bin/bash
if [[ ! -f "$1" ]]; then
    "Please specify a .build file like 'exampleLaunch.sh ${PWD}/amd64.build' and ensure an absolute path"
fi

cd ..
./build-to-spec.py "$1"
SPECS=$PWD/specs
source ./example/env.sh
export CATALYST_CACHE_DIR CATALYST_REPO_DIR CATALYST_BUILDS_DIR CATALYST_SNAPSHOTS_DIR CATALYST_PACKAGES_DIR TARGET SPECS
./runCatalyst.sh

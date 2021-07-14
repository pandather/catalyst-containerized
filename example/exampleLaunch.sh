#!/bin/bash
if [[ ! -f "$1" ]]; then
    "Please specify a spec like 'exampleLaunch.sh ${PWD}/stage1.spec', ensure an absolute path."
fi
SPEC=$1
cd ..
source ./example/env.sh
export CATALYST_CACHE_DIR CATALYST_REPO_DIR CATALYST_BUILDS_DIR CATALYST_SNAPSHOTS_DIR CATALYST_PACKAGES_DIR TARGET SPEC
./runCatalyst.sh

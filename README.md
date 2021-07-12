# catalyst-containerized
First you need to install the docker buildx plugin (the provided script does this)

Then you need to execute runCatalyst.sh with $SEED set to the path of the seed stage to bootstrap to the docker container, and $SPEC set to the path of the specfile you wish to execute. runCatalyst.conf has descriptions of other configuration setable through environment variables.

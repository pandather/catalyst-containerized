# This Dockerfile creates a gentoo stage3 container image. By default it
# creates a stage3-amd64 image. It utilizes a multi-stage build and requires
# docker-17.05.0 or later. It fetches a daily snapshot from the official
# sources and verifies its checksum as well as its gpg signature.

ARG BOOTSTRAP
FROM --platform=$BUILDPLATFORM ${BOOTSTRAP:-alpine:3.11} as builder

ARG SEED
COPY /stage.tar.xz /gentoo/stage.tar.xz

WORKDIR /gentoo


ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX=-openrc


RUN echo "Building Catalyst Gentoo Container image for ${ARCH}" \
 && apk --no-cache add ca-certificates gnupg tar wget xz \
 && STAGEPATH="/stage.tar.xz" \
 && STAGE="$(basename ${STAGEPATH})" \
 && echo Extracting the seed stage. \
 && tar xpf "${STAGE}" --xattrs-include='*.*' --numeric-owner \
 && echo Extraction complete, preparing for bootstrap. \
 && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
 && echo 'UTC' > etc/timezone \
 && mkdir -p var/db/repos/gentoo/ \
 && rm ${STAGE}
# && rm ${STAGE}.DIGESTS ${STAGE}.CONTENTS.gz ${STAGE}

FROM scratch

WORKDIR /
COPY --from=builder /gentoo/ /
COPY /container-script.sh /root/container-script.sh
COPY /toExec.spec /root/toExec.spec
WORKDIR /root
CMD ["/bin/bash", "/root/container-script.sh"]

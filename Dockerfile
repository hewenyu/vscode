ARG RISK=edge
ARG UBUNTU=xenial

FROM ubuntu:$UBUNTU as builder
ARG RISK
ARG UBUNTU
RUN echo "Building snapcraft:$RISK in ubuntu:$UBUNTU"

# Grab dependencies
RUN apt-get update
RUN apt-get dist-upgrade --yes
RUN apt-get install --yes \
      curl \
      jq \
      squashfs-tools

# Grab the core snap (for backwards compatibility) from the stable channel and
# unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core' | jq '.download_url' -r) --output core.snap
RUN mkdir -p /snap/core
RUN unsquashfs -d /snap/core/current core.snap

# Grab the core18 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core18' | jq '.download_url' -r) --output core18.snap
RUN mkdir -p /snap/core18
RUN unsquashfs -d /snap/core18/current core18.snap

# Grab the core20 snap (which snapcraft uses as a base) from the stable channel
# and unpack it in the proper place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/core20' | jq '.download_url' -r) --output core20.snap
RUN mkdir -p /snap/core20
RUN unsquashfs -d /snap/core20/current core20.snap

# Grab the snapcraft snap from the $RISK channel and unpack it in the proper
# place.
RUN curl -L $(curl -H 'X-Ubuntu-Series: 16' 'https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel='$RISK | jq '.download_url' -r) --output snapcraft.snap
RUN mkdir -p /snap/snapcraft
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# Fix Python3 installation: Make sure we use the interpreter from
# the snapcraft snap:
RUN unlink /snap/snapcraft/current/usr/bin/python3
RUN ln -s /snap/snapcraft/current/usr/bin/python3.* /snap/snapcraft/current/usr/bin/python3
RUN echo /snap/snapcraft/current/lib/python3.*/site-packages >> /snap/snapcraft/current/usr/lib/python3/dist-packages/site-packages.pth

# Create a snapcraft runner (TODO: move version detection to the core of
# snapcraft).
RUN mkdir -p /snap/bin
RUN echo "#!/bin/sh" > /snap/bin/snapcraft
RUN snap_version="$(awk '/^version:/{print $2}' /snap/snapcraft/current/meta/snap.yaml | tr -d \')" && echo "export SNAP_VERSION=\"$snap_version\"" >> /snap/bin/snapcraft
RUN echo 'exec "$SNAP/usr/bin/python3" "$SNAP/bin/snapcraft" "$@"' >> /snap/bin/snapcraft
RUN chmod +x /snap/bin/snapcraft


# [Choice] Ubuntu version (use jammy or bionic on local arm64/Apple Silicon): jammy, focal, bionic
ARG VARIANT="focal"
FROM buildpack-deps:${VARIANT}-curl

COPY --from=builder /snap/core /snap/core
COPY --from=builder /snap/core18 /snap/core18
COPY --from=builder /snap/core20 /snap/core20
COPY --from=builder /snap/snapcraft /snap/snapcraft
COPY --from=builder /snap/bin/snapcraft /snap/bin/snapcraft

# Generate locale and install dependencies.
RUN apt-get update && apt-get dist-upgrade --yes && apt-get install --yes snapd sudo locales && locale-gen en_US.UTF-8


# Set the proper environment.
ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"
ENV PATH="/snap/bin:/snap/snapcraft/current/usr/bin:$PATH"
ENV SNAP="/snap/snapcraft/current"
ENV SNAP_NAME="snapcraft"
ENV SNAP_ARCH=$BUILDARCH


# Options for setup script
ARG INSTALL_ZSH="true"
ARG UPGRADE_PACKAGES="true"
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
COPY library-scripts/*.sh library-scripts/*.env /tmp/library-scripts/
RUN yes | unminimize 2>&1 \ 
    && bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts







# arch() {
#   uname_m=$(uname -m)
#   case $uname_m in
#     aarch64) echo arm64 ;;
#     x86_64) echo amd64 ;;
#     *) echo "$uname_m" ;;
#   esac
# }
# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>
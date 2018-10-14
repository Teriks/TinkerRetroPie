#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

"$SCRIPTPATH/../build_installer.sh" BUILD_ARMBIAN=yes \
                                    KERNEL_CONFIGURE=no \
                                    KERNELBRANCH=tag:v4.14.76 \
                                    LIB_TAG=6f0b32a \
                                    BUILD_CONTAINER=docker \
                                    TINKER_RETROPIE_CONFIG="$SCRIPTPATH/installer.cfg"

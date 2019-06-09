#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

"$SCRIPTPATH/../build_installer.sh" BUILD_ARMBIAN=yes \
                                    KERNEL_CONFIGURE=no \
                                    KERNELBRANCH=tag:v5.1.5 \
                                    LIB_TAG=1c3fde7 \
                                    BUILD_CONTAINER=docker \
                                    TINKER_RETROPIE_CONFIG="$SCRIPTPATH/installer.cfg"

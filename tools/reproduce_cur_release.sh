#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

"$SCRIPTPATH/../build_installer.sh" BUILD_ARMBIAN=yes \
                                    KERNEL_CONFIGURE=no \
                                    KERNELBRANCH=tag:v4.14.71 \
                                    LIB_TAG=c1530db \
                                    TINKER_RETROPIE_CONFIG="$SCRIPTPATH/cur_installer.cfg"
                                   

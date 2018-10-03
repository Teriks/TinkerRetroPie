#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/installer_src"
CACHE_FILE="$SCRIPTPATH/build_installer.cache"

if [ -f "$CACHE_FILE" ]; then
    source "$CACHE_FILE"
fi

if [[ "$@" =~ -h || "$@" =~ --help ]]; then

    echo "\
TinkerRetroPie install package generator.

 Use --force-build-armbian to force an update
 of Armbian sources and a full rebuild.

 Parameters: 

  ARMBIAN_BUILD_PATH=(scriptpath)/armbian_build
  BUILD_ARMBIAN=(yes/no)
  KERNEL_CONFIGURE=(yes/no)
  KERNELBRANCH=(branch:linux-4.14.y / tag:v4.14.71)
  LIB_TAG=(master / sunxi-4.14)

 e.g:

  ./build_installer.sh BUILD_ARMBIAN=yes \\ 
                       KERNEL_CONFIGURE=no \\
                       KERNELBRANCH=branch:linux-4.14.y \\
                       LIB_TAG=master
"
    exit 0
fi

FORCE_BUILD_ARMBIAN=0
if [[ $@ == --force-build-armbian ]]; then
    FORCE_BUILD_ARMBIAN=1
fi

for i in "$@"; do
    if [[ $i == *=* ]]; then
        parameter=${i%%=*}
        value=${i##*=}
        echo "Command line: setting $parameter to" "${value:-(empty)}"
        eval $parameter=$value
    fi
done


OUTPUT_DIR=${OUTPUT_DIR:-"$SCRIPTPATH/output"}

DEFAULT_ARMBIAN_BUILD_DIR_NAME='armbian_build'
ARMBIAN_OUTPUT_DIR_NAME='output'
ARMBIAN_OUTPUT_IMAGES_DIR_NAME='images'
ARMBIAN_OUTPUT_DEBS_DIR_NAME='debs'

ARMBIAN_BUILD_PATH=${ARMBIAN_BUILD_PATH:-"$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"}
ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

pushd() {
    command pushd "$@" >/dev/null
}

popd() {
    command popd "$@" >/dev/null
}

# 1 parameter, the default if no input
ask_yes_no() {
    while [[ "$ANSWER" != y* && "$ANSWER" != n* ]]; do
        read -e -p "(y)es / (n)o: " -i "${1,,}" ANSWER
        ANSWER=${ANSWER:-$1}
        ANSWER="${ANSWER,,}"
    done
 
    if [[ $ANSWER == y* ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

check_val_yes_no() {
    ARG=${1,,}
    if [[ $ARG -eq 1 || "$ARG" == y* ]]; then
        echo $2
        return 0
    elif [[ $ARG -eq 0 || "$ARG" == n* ]]; then
        echo $3
        return 0
    else
        return 1
    fi
}

# Return 1 if images exist in $ARMBIAN_OUTPUT_IMAGES_DIR else 0
armbian_images_exist() {
    if [ -d "$ARMBIAN_OUTPUT_IMAGES_DIR" ]; then
        find "$ARMBIAN_OUTPUT_IMAGES_DIR" -maxdepth 1 -name "*.img" -exec false {} +
        echo $?
    else
        echo 0
    fi
}

compile_armbian() {
    if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo "You do not have docker installed, install docker and try again. Exiting."
        echo "See: https://docs.docker.com/install/"
        exit 1
    fi
 
    if [ -z "$LIB_TAG" ]; then
        echo "===================="
        echo "What Armbian build branch do you want to use?"
        echo "Enter a branch \"master\" or a tag, e.g. \"sunxi-4.14\""
        echo "Enter nothing to default to \"master\"."
        echo "===================="
        read -e -p "Armbian Build Branch: " -i "master" LIB_TAG
        echo ""
        LIB_TAG=${LIB_TAG:-master}
    fi

    if [ -z "$KERNELBRANCH" ]; then
        echo "===================="
        echo "What kernel branch do you want to compile?"
        echo "Enter a branch \"branch:linux-4.14.y\" or a tag \"tag:v4.14.71\""
        echo "Enter nothing to default to \"branch:linux-4.14.y\", using the latest tag."
        echo "===================="
        read -e -p "Kernel Branch: " -i "branch:linux-4.14.y" KERNELBRANCH
        echo ""
        KERNELBRANCH=${KERNELBRANCH:-"branch:linux-4.14.y"}
    fi

    if [ -z "$KERNEL_CONFIGURE" ]; then
        echo "===================="
        echo "Do you want to open the kernel config menu before the build starts?"
        echo "===================="

        KERNEL_CONFIGURE=$(ask_yes_no "no")
        echo ""
    else
        KERNEL_CONFIGURE=$(check_val_yes_no "$KERNEL_CONFIGURE" "yes" "no")
        if [ $? -ne 0 ]; then
            echo "Value of KERNEL_CONFIGURE must be 1/0, y/n, or yes/no."
            exit 1
        fi
    fi

    if [ -d "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME" ]; then
        pushd "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"
        git pull
        popd
    else
        git clone https://github.com/Armbian/build "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"
        if [ $? -ne 0 ]; then exit 1; fi

    fi

    pushd "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"

    mkdir -p userpatches

    # Pick kernel branch

    echo "KERNELBRANCH='$KERNELBRANCH'" >./userpatches/lib.config

    # Enable MALI devfreq support
    sed 's/# CONFIG_MALI_DEVFREQ is not set/CONFIG_MALI_DEVFREQ=y/
         s/CONFIG_JOYSTICK_XPAD=y/# CONFIG_JOYSTICK_XPAD is not set/
         s/CONFIG_JOYSTICK_XPAD_FF=y/# CONFIG_JOYSTICK_XPAD_FF is not set/
         s/CONFIG_JOYSTICK_XPAD_LEDS=y/# CONFIG_JOYSTICK_XPAD_LEDS is not set/
         s/CONFIG_INPUT_JOYDEV=y/CONFIG_INPUT_JOYDEV=m/
         s/CONFIG_INPUT_EVDEV=y/CONFIG_INPUT_EVDEV=m/' \
        ./config/kernel/linux-rockchip-next.config >./userpatches/linux-rockchip-next.config

    ./compile.sh docker KERNEL_CONFIGURE=$KERNEL_CONFIGURE KERNEL_ONLY=no \
        BUILD_DESKTOP=no BOARD=tinkerboard \
        RELEASE=stretch BRANCH=next LIB_TAG=$LIB_TAG
    COMPILE_STATUS=$?

    popd

    if [[ $(armbian_images_exist) -eq 0 || $COMPILE_STATUS -ne 0 ]]; then
        exit 1
    fi
}

main() {

    if [[ $(armbian_images_exist) -eq 0 || $FORCE_BUILD_ARMBIAN -eq 1 ]]; then

        CLONE_OR_UPDATE="clone"
        if [ -d "$ARMBIAN_BUILD_PATH" ]; then
            CLONE_OR_UPDATE="update"
        fi

        if [ -z "$BUILD_ARMBIAN" ]; then

            echo "===================="
            echo "Would you like to $CLONE_OR_UPDATE the Armbian-build repo and build Armbian?"
            echo "This script will automaticly enable Mali Midgard devfreq kernel support."
            echo "The build requires docker be installed."
            echo "===================="

            BUILD_ARMBIAN=$(ask_yes_no "yes")
            echo ""
        else
            BUILD_ARMBIAN=$(check_val_yes_no "$BUILD_ARMBIAN" "yes" "no")
            if [ $? -ne 0 ]; then
                echo "Value of BUILD_ARMBIAN must be 1/0, y/n, or yes/no."
                exit 1
            fi
        fi

        if [[ $BUILD_ARMBIAN == y* ]]; then
            if ! (compile_armbian); then
                echo "================================="
                echo "Failed to Build Armbian, exiting."
                exit 1
            fi
        else
            echo "===================="
            echo "Please specify the full path to your completed Armbian build."
            echo "===================="

            FOUND_VALID_ARMBIAN_BUILD=0

            while [ $FOUND_VALID_ARMBIAN_BUILD -eq 0 ]; do

                read -e -p 'Armbian build repo path: ' -i "$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME" USER_BUILD_PATH
                echo ""
                USER_BUILD_PATH=${USER_BUILD_PATH:-"$SCRIPTPATH/$DEFAULT_ARMBIAN_BUILD_DIR_NAME"}

                IMAGES_DIR_STRUCT="$ARMBIAN_OUTPUT_DIR_NAME/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
                DEBS_DIR_STRUCT="$ARMBIAN_OUTPUT_DIR_NAME/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

                USER_IMAGES_DIR="$USER_BUILD_PATH/$IMAGES_DIR_STRUCT"
                USER_DEBS_DIR="$USER_BUILD_PATH/$DEBS_DIR_STRUCT"

                if ! [ -d "$USER_IMAGES_DIR" ]; then
                    echo "===================="
                    echo "\"$USER_BUILD_PATH\" does not contain an \"$IMAGES_DIR_STRUCT\" folder."
                    echo "Build Armbian first or try another path."
                    echo "===================="
                elif ! [ -d "$USER_DEBS_DIR" ]; then
                    echo "===================="
                    echo "\"$USER_BUILD_PATH\" does not contain an \"$DEBS_DIR_STRUCT\" folder."
                    echo "Build Armbian first or try another path."
                    echo "===================="
                else
                    ARMBIAN_BUILD_PATH=$(realpath "$USER_BUILD_PATH")
                    ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
                    ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
                    ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

                    if [ $(armbian_images_exist) -eq 0 ]; then
                        echo "===================="
                        echo "\"$USER_BUILD_PATH/$IMAGES_DIR_STRUCT\" does not contain any built Armbian images."
                        echo "Build Armbian first or try another path."
                        echo "===================="
                    else
                        FOUND_VALID_ARMBIAN_BUILD=1
                        echo "===================="
                        echo "Found Armbian build at: \"$ARMBIAN_BUILD_PATH\""
                        echo "===================="
                    fi

                fi
            done
        fi
    else
        ARMBIAN_BUILD_PATH=$(realpath "$ARMBIAN_BUILD_PATH")
        ARMBIAN_OUTPUT_PATH="$ARMBIAN_BUILD_PATH/$ARMBIAN_OUTPUT_DIR_NAME"
        ARMBIAN_OUTPUT_IMAGES_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_IMAGES_DIR_NAME"
        ARMBIAN_OUTPUT_DEBS_DIR="$ARMBIAN_OUTPUT_PATH/$ARMBIAN_OUTPUT_DEBS_DIR_NAME"

        echo "===================="
        echo "Found Armbian build at: \"$ARMBIAN_BUILD_PATH\""
        echo "===================="
    fi

    echo "ARMBIAN_BUILD_PATH=\"$ARMBIAN_BUILD_PATH\"" >"$CACHE_FILE"

    echo "========================"
    echo "Configuring installer..."
    echo "========================"

    set -x

    pushd "$INSTALLER_DIR"
    rm -f packages/linux-headers-next-rockchip_*_armhf.deb
    rm -f packages/armbian-config_*_all.deb
    rm -f packages/armbian-firmware-full_*_all.deb
    rm -f packages/armbian-tools-stretch_*_armhf.deb
    popd

    pushd "$ARMBIAN_OUTPUT_DEBS_DIR"
    cp linux-headers-next-rockchip_*_armhf.deb "$INSTALLER_DIR/packages"
    cp armbian-config_*_all.deb "$INSTALLER_DIR/packages"
    cp armbian-firmware-full_*_all.deb "$INSTALLER_DIR/packages"
    cp armbian-tools-stretch_*_armhf.deb "$INSTALLER_DIR/packages"
    popd

    pushd "$ARMBIAN_OUTPUT_IMAGES_DIR"
    RECENT_ARMBIAN_IMG=$(ls -t *.img | head -1)
    popd

    set +x

    echo "======================"
    echo "Packaging installer..."
    echo "======================"

    mkdir -p "$OUTPUT_DIR"
    pushd "$OUTPUT_DIR"

    set -x

    INSTALLER_DIR_NAME=$(basename $INSTALLER_DIR)
    tar -czvf TinkerRetroPieInstaller.tar.gz \
        --transform "s/^$INSTALLER_DIR_NAME/TinkerRetroPieInstaller/" \
        -C "$SCRIPTPATH/" $INSTALLER_DIR_NAME

    set +x

    echo "============================================"
    echo "Copying Armbian image to output directory..."
    echo "============================================"

    rm -f $RECENT_ARMBIAN_IMG
    rsync -ah --progress "$ARMBIAN_OUTPUT_IMAGES_DIR/$RECENT_ARMBIAN_IMG" .

    echo "====="
    echo "Done."
    echo "====="

    SHORT_OUTPUT_DIR_PATH=$(basename "$OUTPUT_DIR")

    echo "Flash: \"$SHORT_OUTPUT_DIR_PATH/$RECENT_ARMBIAN_IMG\""
    echo "Transfer \"$SHORT_OUTPUT_DIR_PATH/TinkerRetroPieInstaller.tar.gz\" to your Tinker Board."
    echo "Extract the archive and run: TinkerRetroPieInstaller/install.sh"

    popd

}

main

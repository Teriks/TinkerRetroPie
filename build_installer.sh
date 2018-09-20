#!/bin/bash

SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"

INSTALLER_DIR="$SCRIPTPATH/installer_src"
CACHE_FILE="$SCRIPTPATH/build_installer.cache"

if [ -f "$CACHE_FILE" ]; then
    source "$CACHE_FILE"
fi

if [[ $@ == -h || $@ == --help ]]; then
    echo "TinkerRetroPie install package generator."
    echo ""
    echo " Use --force-build-armbian to force an update"
    echo " of Armbian sources and a full rebuild."
    echo ""
    exit 0
fi

FORCE_BUILD_ARMBIAN=0
if [[ $@ == --force-build-armbian ]]; then
    FORCE_BUILD_ARMBIAN=1
fi

ARMBIAN_OUTPUT_PATH=${ARMBIAN_OUTPUT_PATH:-"$SCRIPTPATH/armbian_build/output"}
ARMBIAN_IMG_PATH=${ARMBIAN_IMG_PATH:-"$ARMBIAN_OUTPUT_PATH/images"}
ARMBIAN_DEBS_PATH=${ARMBIAN_DEBS_PATH:-"$ARMBIAN_OUTPUT_PATH/debs"}


pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}


compile_armbian ()
{
    if [ $(dpkg-query -W -f='${Status}' docker-ce 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        echo "You do not have docker installed, install docker and try again. Exiting."
        exit 1 
    fi

    if [ -d "$SCRIPTPATH/armbian_build" ]; then
        pushd "$SCRIPTPATH/armbian_build";
        git pull
        popd
    else
        git clone https://github.com/Armbian/build "$SCRIPTPATH/armbian_build"
        if [ $? -ne 0 ]; then exit 1; fi
       
    fi

    pushd "$SCRIPTPATH/armbian_build"

    # Enable MALI devfreq support
    sed 's/# CONFIG_MALI_DEVFREQ is not set/CONFIG_MALI_DEVFREQ=y/' \
        config/kernel/linux-rockchip-next.config > \
        userpatches/linux-rockchip-next.config

    ./compile.sh docker KERNEL_CONFIGURE=$ARMBIAN_CONFIGURE_KERNEL KERNEL_ONLY=no \
                        BUILD_DESKTOP=no BOARD=tinkerboard \
                        RELEASE=stretch BRANCH=next
    COMPILE_STATUS=$?

    popd

    if [ $COMPILE_STATUS -ne 0 ]; then 
        exit 1
    elif ! [ -d "$ARMBIAN_IMG_PATH" ]; then
        exit 1
    fi
}

echo "$ARMBIAN_IMG_PATH"
if ! [ -d "$ARMBIAN_IMG_PATH" ] || [ $FORCE_BUILD_ARMBIAN -eq 1 ]; then

    if [ $FORCE_BUILD_ARMBIAN -eq 0 ]; then
        echo "Could not find an Armbian build in the script directory."
    fi

    echo "===================="
    echo "Would you like to clone/update the Armbian/build repo and build Armbian?"
    echo "This script will automaticly enable Mali Midgard devfreq kernel support."
    echo "The build requires docker be installed."
    echo "===================="

    BUILD_ARMBIAN=""
    while ! [[ "$BUILD_ARMBIAN" == y* || "$BUILD_ARMBIAN" == n* ]]; do
        read -p "[(y)es / (n)o]:" BUILD_ARMBIAN
        BUILD_ARMBIAN="${BUILD_ARMBIAN,,}"
    done

    if [[ $BUILD_ARMBIAN == y* ]]; then
        ARMBIAN_CONFIGURE_KERNEL=""
        export SCRIPT_PATH
        export ARMBIAN_IMG_PATH

        echo "===================="
        echo "Do you want to open the kernel config menu before the build starts?"
        echo "===================="

        while ! [[ "$ARMBIAN_CONFIGURE_KERNEL" == y* || "$ARMBIAN_CONFIGURE_KERNEL" == n* ]]; do
            read -p "[(y)es / (n)o]:" ARMBIAN_CONFIGURE_KERNEL
            ARMBIAN_CONFIGURE_KERNEL="${ARMBIAN_CONFIGURE_KERNEL,,}"
        done
        
        if [[ $ARMBIAN_CONFIGURE_KERNEL == y* ]]; then
            ARMBIAN_CONFIGURE_KERNEL=yes
        else
            ARMBIAN_CONFIGURE_KERNEL=no
        fi

        export ARMBIAN_CONFIGURE_KERNEL
        
        if ! (compile_armbian); then
            echo "================================="
            echo "Failed to Build Armbian, exiting."
            exit 1
        fi
    else
        echo "===================="
        echo "Please specify the full path to your Armbian build."
        echo "===================="
    
        while ! [ -d "$ARMBIAN_IMG_PATH" ]; do
            read -p "Armbian build repo path [./armbian_build]:" USER_BUILD_PATH
            if ! [ -d "$USER_BUILD_PATH/output/images" ]; then
                echo "===================="
                echo "\"$USER_BUILD_PATH\" does not contain an output/images folder."
                echo "build Armbian first or try another path."
                echo "===================="
            else
                ARMBIAN_OUTPUT_PATH=$(realpath "$USER_BUILD_PATH/output")
                ARMBIAN_IMG_PATH="$ARMBIAN_OUTPUT_PATH/images"
                ARMBIAN_DEBS_PATH="$ARMBIAN_OUTPUT_PATH/debs"
                echo "===================="
                echo "Found Armbian build output at: \"$ARMBIAN_OUTPUT_PATH\""
                echo "===================="
            fi
        done
    fi
else
    ARMBIAN_OUTPUT_PATH=$(realpath "$ARMBIAN_OUTPUT_PATH")
    ARMBIAN_IMG_PATH="$ARMBIAN_OUTPUT_PATH/images"
    ARMBIAN_DEBS_PATH="$ARMBIAN_OUTPUT_PATH/debs"
    echo "===================="
    echo "Found Armbian build output at: \"$ARMBIAN_OUTPUT_PATH\""
    echo "===================="
fi

> "$CACHE_FILE"
echo "ARMBIAN_OUTPUT_PATH=\"$ARMBIAN_OUTPUT_PATH\"" >> "$CACHE_FILE"
echo "ARMBIAN_IMG_PATH=\"$ARMBIAN_IMG_PATH\"" >> "$CACHE_FILE"
echo "ARMBIAN_DEBS_PATH=\"$ARMBIAN_DEBS_PATH\"" >> "$CACHE_FILE"

echo "========================"
echo "Configuring installer..."
echo "========================"

set -x

pushd "$INSTALLER_DIR"
rm packages/linux-headers-next-rockchip_*_armhf.deb
rm packages/armbian-config_*_all.deb
rm packages/armbian-firmware-full_*_all.deb 
rm packages/armbian-tools-stretch_*_armhf.deb
popd

pushd "$ARMBIAN_DEBS_PATH"
cp linux-headers-next-rockchip_*_armhf.deb "$INSTALLER_DIR/packages"
cp armbian-config_*_all.deb "$INSTALLER_DIR/packages"
cp armbian-firmware-full_*_all.deb "$INSTALLER_DIR/packages"
cp armbian-tools-stretch_*_armhf.deb "$INSTALLER_DIR/packages"
popd

pushd "$ARMBIAN_IMG_PATH"
RECENT_ARMBIAN_IMG=$(ls -t *.img | head -1)
popd

set +x

echo "======================"
echo "Packaging installer..."
echo "======================"

mkdir -p "$SCRIPTPATH/output"
pushd "$SCRIPTPATH/output"

set -x
INSTALLER_DIR_NAME=$(basename $INSTALLER_DIR)
tar -czvf TinkerRetroPieInstaller.tar.gz --transform "s/^$INSTALLER_DIR_NAME/TinkerRetroPieInstaller/" -C "$SCRIPTPATH/" $INSTALLER_DIR_NAME
set +x

echo "============================================"
echo "Copying Armbian image to output directory..."
echo "============================================"

rm -f $RECENT_ARMBIAN_IMG
rsync -ah --progress "$ARMBIAN_IMG_PATH/$RECENT_ARMBIAN_IMG" .

echo "====="
echo "Done."
echo "====="

echo "Flash: \"output/$RECENT_ARMBIAN_IMG\""
echo "Transfer \"output/TinkerRetroPieInstaller.tar.gz\" to your Tinker Board."
echo "Extract the archive and run: TinkerRetroPieInstaller/install.sh"

popd



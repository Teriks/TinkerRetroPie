#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

TIMESTAMP=$(date "+%Y%m%d_%H%M")
LOG_FILE="$SCRIPTPATH/install_$TIMESTAMP.log"

PACKAGES_DIR="$SCRIPTPATH/packages"
ETC_DIR="$SCRIPTPATH/etc"

RETROPIE_SETUP_DIR=$(realpath "$SCRIPTPATH/../RetroPie-Setup")


if [[ $@ == -h || $@ == --help ]]; then
    echo "TinkerRetroPie installer."
    echo ""
    echo " Parameters: "
    echo ""
    echo " RETROPIE_BRANCH=(RetroPie-Setup git branch)"
    echo ""
    echo " e.g:"
    echo ""
    echo " ./installer.sh RETROPIE_BRANCH=master"
    echo ""
    echo " ./installer.sh RETROPIE_BRANCH=4.4"
    echo ""
    echo " ./installer.sh RETROPIE_BRANCH=ee8af99"
    exit 0
fi

for i in "$@"; do
    if [[ $i == *=* ]]; then
        parameter=${i%%=*}
        value=${i##*=}
        echo "Command line: setting $parameter to" "${value:-(empty)}"
        eval $parameter=$value
    fi
done

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

RETROPIE_BRANCH=${RETROPIE_BRANCH:-"master"}

pushd() {
    command pushd "$@" >/dev/null
}

popd() {
    command popd "$@" >/dev/null
}

(

    echo "==========================="
    echo "Installing prebuilt debs..."
    echo "==========================="

    pushd "$PACKAGES_DIR"

    dpkg -i linux-headers-next-rockchip_*_armhf.deb \
        armbian-config_*_all.deb \
        armbian-firmware-full_*_all.deb \
        armbian-tools-stretch_*_armhf.deb \
        libmali-rk-midgard-t76x-r14p0-r0p0_1.6-1_armhf.deb \
        libmali-rk-dev_1.6-1_armhf.deb \
        librockchip-mpp1_20171218-2_armhf.deb \
        librockchip-mpp-dev_20171218-2_armhf.deb \
        librockchip-vpu0_20171218-2_armhf.deb

    popd

    echo "======================================="
    echo "Installing prebuilt deb dependencies..."
    echo "======================================="

    if ! apt-get install -y -f; then
        exit 1
    fi

    echo "=========================="
    echo "Installing dev packages..."
    echo "=========================="

    apt-get install -y libavdevice-dev libxkbcommon-dev libsm-dev libffi-dev libexpat1-dev libxml2-dev zlib1g-dev
    if [ $? -ne 0 ]; then exit 1; fi

    # The packages below are required specifically to build SDL2-2.0.8

    apt-get install -y libgl1-mesa-dev libx11-dev libxcursor-dev libxext-dev libxi-dev \
        libxinerama-dev libxrandr-dev libxss-dev libxxf86vm-dev
    if [ $? -ne 0 ]; then exit 1; fi

    echo "========================="
    echo "Installing build tools..."
    echo "========================="

    apt-get install -y libtool pkg-config
    if [ $? -ne 0 ]; then exit 1; fi

    echo "========================"
    echo "Installing pulseaudio..."
    echo "========================"

    apt-get install -y pulseaudio pulseaudio-utils
    if [ $? -ne 0 ]; then exit 1; fi

    echo "======================================"
    echo "Creating GLESv1 shared object symlinks"
    echo "======================================"

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1_CM.so.1.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv1.so.1.0.0

    echo "======================================"
    echo "Creating GLESv2 shared object symlinks"
    echo "======================================"

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so.2
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2_CM.so.2.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libGLESv2.so.2.0.0

    echo "==================================="
    echo "Creating EGL shared object symlinks"
    echo "==================================="

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libEGL.so.1.0.0

    echo "==================================="
    echo "Creating gbm shared object symlinks"
    echo "==================================="

    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.1
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.1.0.0
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.9
    ln -s /usr/lib/arm-linux-gnueabihf/libMali.so /usr/lib/arm-linux-gnueabihf/libgbm.so.9.0.0

    echo "========================================================"
    echo "Cloning, building, and installing wayland from source..."
    echo "========================================================"

    git clone git://anongit.freedesktop.org/wayland/wayland "$SCRIPTPATH/wayland"

    pushd "$SCRIPTPATH/wayland"

    ln -s /usr/share/libtool/build-aux/ltmain.sh .

    if ! (./autogen.sh --disable-documentation && make -j4 && make install); then
        exit 1
    fi

    popd

    echo "========================="
    echo "Configuring udev rules..."
    echo "========================="

    cp -v "$ETC_DIR/udev/rules.d/99-evdev.rules" /etc/udev/rules.d/

    echo "=================================="
    echo "Configuring pulseaudio defaults..."
    echo "=================================="

    cp -v "$ETC_DIR/pulse/default.pa" /etc/pulse/

    echo "====================================="
    echo "Configuring GPU clockspeed service..."
    echo "====================================="

    cp -v "$ETC_DIR/init.d/gpu-freqboost-tinker" /etc/init.d

    chmod 755 /etc/init.d/gpu-freqboost-tinker

    systemctl enable gpu-freqboost-tinker
    if [ $? -ne 0 ]; then exit 1; fi

    systemctl start gpu-freqboost-tinker
    if [ $? -ne 0 ]; then exit 1; fi

    echo "========================================="
    echo "Configuring retropie group and sudoers..."
    echo "========================================="

    if ! getent group retropie; then
        echo "Creating group: retropie"
        groupadd retropie
    fi

    if ! id -nG $SUDO_USER | grep -qw retropie; then
        echo "Adding user $SUDO_USER to group retropie."
        usermod -a -G retropie $SUDO_USER
    fi

    echo "Adding passwordless sudo for important retropie commands..."

    set -x

    echo "%retropie ALL=(ALL:ALL) NOPASSWD: $RETROPIE_SETUP_DIR/retropie_setup.sh" >/etc/sudoers.d/retropie
    echo "%retropie ALL=(ALL:ALL) NOPASSWD: $RETROPIE_SETUP_DIR/retropie_packages.sh" >>/etc/sudoers.d/retropie
    echo "%retropie ALL=(ALL:ALL) NOPASSWD: /bin/systemctl restart keyboard-setup" >>/etc/sudoers.d/retropie
    echo "%retropie ALL=(ALL:ALL) NOPASSWD: /usr/sbin/service keyboard-setup restart" >>/etc/sudoers.d/retropie
    echo "%retropie ALL=(ALL:ALL) NOPASSWD: /opt/retropie/emulators/retroarch/bin/retroarch" >>/etc/sudoers.d/retropie

    set +x

    echo "============================="
    echo "Cloning RetroPie-Setup to ../"
    echo "============================="

    if [ -d "$RETROPIE_SETUP_DIR" ]; then
        pushd "$RETROPIE_SETUP_DIR"
        if ! git pull; then exit 1; fi
        if ! git checkout "$RETROPIE_BRANCH"; then exit 1; fi
        popd
    else
        git clone https://github.com/RetroPie/RetroPie-Setup "$RETROPIE_SETUP_DIR"
        if [ $? -ne 0 ]; then exit 1; fi

        pushd "$RETROPIE_SETUP_DIR"
            if ! git checkout "$RETROPIE_BRANCH"; then exit 1; fi
        popd
    fi

) 2>&1 | tee "$LOG_FILE"

INSTALL_STATUS=${PIPESTATUS[0]}

if [ $INSTALL_STATUS -ne 0 ]; then
    echo "Pre install setup failed, see: \"$LOG_FILE\" for details."
    exit $INSTALL_STATUS
fi

echo "=========================="
echo "Starting RetroPie-Setup..."
echo "=========================="

pushd "$RETROPIE_SETUP_DIR"
./retropie_setup.sh
popd

#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

BRANCH=master
MODULE_DEST="$1/scriptmodules/emulators/reicast-latest-tinker.sh"
MODULE_DATA_DIR="$1/scriptmodules/emulators/reicast-latest-tinker"


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

if [ -f "$SCRIPTPATH/../installer.cfg" ]; then
    source "$SCRIPTPATH/../installer.cfg"
fi

if ! [ -z "${REICAST_LASTEST_TINKER_BRANCH+x}" ]; then
    BRANCH="$REICAST_LASTEST_TINKER_BRANCH"
fi

source "$SCRIPTPATH/../lib/read_params.sh"

echo "========="
echo "Applying latest_reicast_patch"
echo "========="

set -e
set -x

mkdir -p "$MODULE_DATA_DIR"

cp "$SCRIPTPATH/data/reicast-latest-tinker.sh" "$MODULE_DEST"

sed -i "s|TINKER_RETRO_PIE_OPTIONAL_NEW_REICAST_BRANCH|$BRANCH|" "$MODULE_DEST"

cp "$SCRIPTPATH/data/tinker-kms-makefile.patch" "$MODULE_DATA_DIR"
cp "$SCRIPTPATH/data/start-reicast-tinker.patch" "$MODULE_DATA_DIR"

set +x
set +e

echo "=========="
echo "Patch Applied."

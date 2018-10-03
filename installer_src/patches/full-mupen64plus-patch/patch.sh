#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

MODULE_DIR="$1/scriptmodules/emulators"
MODULE_DEST="$MODULE_DIR/mupen64plus-tinker.sh"
MODULE_DATA_DIR="$MODULE_DIR/mupen64plus/tinker"

if [ -f "$SCRIPTPATH/../installer.cfg" ]; then
    source "$SCRIPTPATH/../installer.cfg"
fi

source "$SCRIPTPATH/../lib/read_params.sh"

if grep 'rp_module_flags\s*=\s*".*!kms.*"' "$MODULE_DIR/mupen64plus.sh"; then
    # Only use this patch if the existing script module does not support kms

    echo "========="
    echo "Applying full-mupen64plus-patch"
    echo "========="

    set -e
    set -x

    mkdir -p "$MODULE_DATA_DIR"

    cp "$SCRIPTPATH/data/mupen64plus-tinker.sh" $MODULE_DEST
    cp "$SCRIPTPATH/data/start-mupen64plus-tinker.patch" "$MODULE_DATA_DIR"

    set +x
    set +e

    echo "=========="
    echo "Patch Applied."
    echo "=========="

else
    echo "=========="
    echo "full-mupen64plus-patch not required."
    echo "=========="
fi

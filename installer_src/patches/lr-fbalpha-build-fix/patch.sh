#!/bin/bash

# Temporary Fix for lr-fbalpha build failure

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

INSTALLER_DIR="$SCRIPTPATH/../.."
LIB_DIR="$INSTALLER_DIR/lib"


MODULE_DEST="$1/scriptmodules/libretrocores/lr-fbalpha.sh"

if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

if [ -f "$INSTALLER_DIR/installer.cfg" ]; then
    source "$INSTALLER_DIR/installer.cfg"
fi

source "$LIB_DIR/read_params.sh"

echo "======================"
echo "Patching in lr-fbalpha"
echo "======================"

set -e
set -x

if ! grep -q 'make -f makefile.libretro HAVE_NEON=1' "$MODULE_DEST"; then
    mv "$MODULE_DEST" "$SCRIPT_PATH/lr-fbalpha.sh.bak"
    sed 's|make -f makefile\.libretro$|make -f makefile\.libretro HAVE_NEON=1|' "$SCRIPT_PATH/lr-fbalpha.sh.bak" > "$MODULE_DEST"
else
    echo "============================="
    echo "lr-fbalpha patch not required"
    echo "============================="
fi

set +x
set +e

echo "=============="
echo "Patch Applied."
echo "=============="

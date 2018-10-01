#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

MODULE_DEST="$1/scriptmodules/emulators/mupen64plus-tinker.sh"
MODULE_DATA_DIR="$1/scriptmodules/emulators/mupen64plus/tinker"

for i in "$@"; do
    if [[ $i == *=* ]]; then
        parameter=${i%%=*}
        value=${i##*=}
        echo "Command line: setting $parameter to" "${value:-(empty)}"
        eval $parameter=$value
    fi
done


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

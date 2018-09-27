#!/bin/bash

SCRIPTPATH="$(
    cd "$(dirname "$0")"
    pwd -P
)"

BRANCH=master


if [ -z "${1+x}" ]; then
    echo "Must provide RetroPie-Setup path".
    exit 1
fi

for i in "$@"; do
    if [[ $i == *=* ]]; then
        parameter=${i%%=*}
        value=${i##*=}
        echo "Command line: setting $parameter to" "${value:-(empty)}"
        eval $parameter=$value
    fi
done

OG_SCRIPT="$1/scriptmodules/emulators/reicast.sh"


if ! [ -f "$OG_SCRIPT.tinkerretropie.bak" ]; then
    cp "$OG_SCRIPT" "$OG_SCRIPT.tinkerretropie.bak"
else
    cp "$OG_SCRIPT.tinkerretropie.bak" "$OG_SCRIPT"
fi

pushd "$1" > /dev/null
if git apply "$SCRIPTPATH/reicast.sh.patch"; then
    sed -i "s|TINKER_RETRO_PIE_OPTIONAL_NEW_REICAST_BRANCH|$BRANCH|
            s|TINKER_RETRO_PIE_OPTIONAL_NEW_REICAST|$(realpath $SCRIPTPATH)|" "$OG_SCRIPT"

    echo "=========="
    echo "Patch Applied."
else
    echo "=========="
    echo "Could not patch $OG_SCRIPT"
    exit 1
fi
popd > /dev/null

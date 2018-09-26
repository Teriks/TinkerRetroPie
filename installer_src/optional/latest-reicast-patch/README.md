# About

This patch will cause the reicast installer to pull from the actual reicast repo instead of installing from the outdated RetroPie fork.

This patch is designed for, and only works for the tinkerboard platform.

# Directions

Install RetroPie main/core

Run: 

```bash

./patch_retropie_setup.sh ~/RetroPie-Setup

```

(Must give it the setup directory)

When installing reicast on tinkerboard it will now clone and build from https://github.com/reicast/reicast-emulator.git
instead of using RetroPie's outdated fork.

to force building a specific commit/tag/branch use:

```bash

./patch_retropie_setup.sh ~/RetroPie-Setup BRANCH=(branch/commit/tag)


```

The default is master.


# Reverting

Do this:

```bash

# Uninstall reicast

sudo mv ~/RetroPie-Setup/scriptmodules/emulators/reicast.sh.bak ~/RetroPie-Setup/scriptmodules/emulators/reicast.sh

# Reinstall reicast

```

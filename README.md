# TinkerRetroPie

TinkerRetroPie is an Armbian OS build wrapper and install script generator for installing RetroPie on TinkerBoards.

This repository will feature pre-built images with RetroPie installed once I have achieved a stable configuration, this is a WIP.

The TinkerRetroPie install builder currently is tested and developed on Ubuntu 18.04.1 LTS.

## Features

TinkerRetroPie takes advantage of the Mali Midgard (GPU) devfreq support in newer linux kernels
to set the GPU to its max clock (600 MHz) on system boot. (Normally left at 100 MHz)

The `build_installer.sh` script can configure and build Armbian from source for you with 
Mali Midgard (GPU) devfreq support (Userland device frequency manipulation). This kernel option
is not enabled by default.

It will also automatically modularize the 'joypad' and 'evdev' module (mostly for debugging reasons), and remove
'xpad' all together so you may install RetroPie's or another version without issues.

It will produce a tarball containing an installer script and its supporting files that you can
run on your newly built image to install RetroPie.

You can also use an Armbian build that you have previously built by specifying its location when prompted.
But the build must have had Mali Midgard devfreq support enabled from kernel config menu.  It is recommended
to also manually modularize 'joypad' and 'evdev' from the kernel config menu, and remove 'xpad' completely.

TinkerRetroPie requires the "next" branch of the kernel (4.14.*), and is only tested on images based on Debian Stretch.

Install is only supported on the minimal server distribution. 
Adding a desktop environment is untested/unsupported due to the finickiness of the userland Mali GPU drivers and X11.

I have tested these emulators so far with good success:

 * reicast (the provided one)
 * reicast-latest-tinker (TinkerRetroPie patch, installs the latest version)
 * lr-mupen64plus
 * mupen64plus (TinkerRetroPie patch, builds the full version for tinker)
 

# Performance

The `install.sh` script from the generated installer tarball will install an init.d
script that sets the GPU clock to its max frequency (600 MHz) and the GPU governor to "userspace".

The script that does this is `etc/init.d/gpu-freqboost-tinker`, which is installed to `/etc/init.d/gpu-freqboost-tinker`
and enabled by the install script.

Make sure you have heaksinks installed and are using some kind of fan to keep the device cool.

In the case that you do not have adequate cooling, you can disable the frequency boost with: 
`sudo systemctl disable gpu-freqboost-tinker` (performance will suffer a lot)

Make sure to restart after running the above command.


## Tested games

With this boot configuration, reicast (dreamcast emulator) and mupen64plus run surprisingly well.

Note: lr-mupen64plus runs a little bit faster at the moment than the full version of Mupen built for tinker.

Games I have tested on reicast running pretty much full or playable speed: 

 * Dead Or Alive 2
 * Crazy Taxi 
 * Sonic Adventures 2
 * Rayman 2: The Great Escape

Games I have tested on N64 with similar result:

 * Star Fox 64
 * Mario 64
 * Hydro Thunder
 * Wave Race 64
 * Perfect Dark
 * Golden Eye

PS1: TODO. 

I imagine it works great given it already works pretty well on Raspberry Pi 3, and Tinker has around twice the horsepower.

# Starting emulationstation

To start emulation station, just call the **emulationstation** command.
It is on your path after installing RetroPie.

```bash

emulationstation

```

# Update RetroPie / Install more software


You can CD into `~/RetroPie-Setup` and run: `git pull` to fetch the latest setup script changes.

Then run: `sudo ./retropie_setup.sh` to start the setup script, which will allow you to update
or install additional RetroPie packages by building them from source.


# Build from source / install yourself

Run `build_installer.sh` on your build machine.

On the first run you will be prompted if you want to build Armbian from source, if you say "no" you will
be asked for a path to an existing source tree where a build has been previously completed.

You will also be asked if you want access to the linux kernel configuration menu, for the kernel branch (linux kernel version), 
and for the Armbian OS LIB_TAG (this is a tag/branch/commit-hash from the Armbian/build repository).

If you are not sure about the prompts mentioned above, just hit enter to accept the default values.

Building Armbian from source with `build_installer.sh` will **require that you have docker installed** for simplicity.

When the script finishes running, **TinkerRetroPieInstaller.tar.gz** and the OS image will be left in the `output` directory, which
by default is in the same directory that `build_installer.sh` resides in.

After you have run `build_installer.sh` successfully, Flash the Armbian OS image and setup a non root user named to your liking.

Log into that user and transfer **TinkerRetroPieInstaller.tar.gz** to their home directory.

If your not sure how to do that with `rsync` you can just power down your device, put the 
SDCard back in your computer and place it there manually.

Untar: `tar -xvf TinkerRetroPieInstaller.tar.gz`

Run: `sudo ./TinkerRetroPieInstaller/install.sh`

The script will install/build a bunch of requirements for RetroPie, including userland GPU drivers and boot config.

Once the script is done installing RetroPie requirements it will clone and launch the RetroPie setup script.

This will bring up a blue menu where you can select "Basic Install".

"Basic Install" will build and install all the core packages of RetroPie onto your system.

You can restart the RetroPie config script to install additional packages later or update software by running `sudo ~/RetroPie-Setup/retropie_setup.sh`

Once installed, you can launch emulationstation, see the **Starting emulationstation** section above for recommendations on how to start it.

## Install xpad / xboxdrv

I recommend using xpad for Xbox / XInput controllers, install it from the `~/RetroPie-Setup/retropie_setup.sh` script.

It is under the Drivers section.

Once you have installed it do:

```bash

sudo modprobe xpad

```

To load the newly installed kernel module.

You will need to do some research on configuring controllers with RetroPie, it is generally a pain.


## Forcing source update + rebuild

Running `build_installer.sh --force-armbian-rebuild` will prompt you if you want to clone/update Armbian sources
again even they are already present in the build tree.

Saying 'yes' will cause the script to update the Armbian build script sources to their lastest version, and then
run the build over again.

An installer package will be generated overwriting the old one, and the most recently produced 
Armbian image will be put into the output folder of the **TinkerRetroPie** build tree possibly 
overwriting the last one that was produced.


# Build without prompts / reproduce previous build

Using `--force-armbian-rebuild` with any of the following command examples will force a complete
rebuild of Armbian OS, which would normally not happen unless no images are found in the builds
`output/images` directory.

```bash

# Example 1, This will:

# 1) Clone/update the Armbian/build repo at (scriptpath)/armbian_build
# 2) Skip the kernel configuration menu
# 3) Build with linux kernel at tag v4.14.71
# 4) Checkout Armbian/build repo at commit c1530db (Armbian 5.60)

./build_installer.sh BUILD_ARMBIAN=yes KERNEL_CONFIGURE=no KERNELBRANCH=tag:v4.14.71 LIB_TAG=c1530db

# Example 2, This Will:

# 1) Clone/update the Armbian/build repo to/at ARMBIAN_BUILD_PATH (./my_custom_build)
# 2) Give access to the kernel configuration menu
# 3) Build the kernel from the latest tag in the linux-4.14.y branch
# 4) Checkout Armbian/build repo at the latest commit (master)

./build_installer.sh ARMBIAN_BUILD_PATH=./my_custom_build \
                     BUILD_ARMBIAN=yes \
                     KERNEL_CONFIGURE=yes \
                     KERNELBRANCH=branch:linux-4.14.y \
                     LIB_TAG=master


# Example 3, This Will:

# 1.) Clone/update the Armbian/build repo at (scriptpath)/armbian_build
# 2.) Skip the kernel configuration menu
# 3.) Build the kernel from the latest tag in the linux-4.14.y branch
# 4.) Checkout Armbian/build repo at the latest commit (master)
#
# 5.) Place the output image and installer tarball in ./my_custom_output_dir
#     Creating the directory if it does not exist

./build_installer.sh BUILD_ARMBIAN=yes \
                     KERNEL_CONFIGURE=yes \
                     KERNELBRANCH=branch:linux-4.14.y \
                     LIB_TAG=master \
                     OUTPUT_DIR=./my_custom_output_dir

```

# Create your own distributable image

The `squash_sd_img.sh` can be used to shrink the filesystem on you SDCard to its minimal size,
clone it to an image and then return the filesystem on your device back to normal.

Note that this is probably not a great thing to do repeatedly to your SDCard, but it works.

If you are doing this for the Armbian image you just built and logged into, you should run
this command first and then shutdown (dont restart before making an image):

`sudo systemctl enable armbian-resize-filesystem`

This command will enable Armbian's onshot systemd service that expands the filesystem back
to its maximum size upon boot.  After the filesystem is expanded again the service disables itself.


```bash

# Shrink /dev/mmcblk0p1
# mmcblk0 is typicaly the name of your built in SDCard reader
# but you really should verify its the correct device first...

# Note that the partition is specified not the root device itself (p1)

# Generally Armbian OS images will have one primary partition, as with most SBC
# images.  You want to pick the primary partition, and it must be the last
# partition on the device.

./squash_sd_img.sh /dev/mmcblk0p1 my_customized_image.img

# Your bootable minified image will be written to my_customized_image.img


```








# TinkerRetroPie

TinkerRetroPie is a setup script generator for installing RetroPie on Tinker Boards (Armbian OS).

This repository also features Pre-Built images with RetroPie installed already, see the releases page.

TinkerRetroPie takes advantage of Mali Midgard (GPU) devfreq support in the newer kernels,
in order to set the GPU to its max clock on system boot. (Normally locked to a low value)

The ``build_installer.sh`` script can configure and build Armbian from source for you with 
Mali Midgard (GPU) devfreq support (Userland device frequency manipulation).

It will produce a tarball containing an installer script and its supporting files that you can
run on your newly built image in order to install RetroPie.

You can also use a build that you have previously built by specifying its location when prompted,
but you must enable Mali Midgard devfreq support in the kernel config menu.

TinkerRetroPie uses the "next" branch of the kernel (4.14.*), and is based on Debian Stretch.

TinkerRetroPie uses the minimal server distribution as it's base, adding a desktop environment is untested/unsupported due
to the finickiness of the userland Mali GPU drivers and X11.

I have built these optional RetroPie packages in my prebuilt images:

 * reicast (dreamcast)
 * xboxdrv (works best for xbox controllers in my setup)


# Starting emulationstation

If your using my prebuilt images, login: tinker, 1234

In my prebuilt images, **emulationstation** is not setup to be booted into directly.

Though this should not be too hard to setup yourself.

I recommend starting **emulationstation** like this:

```bash

emulationstation && sudo service keyboard-setup restart

```

This is because some emulators (reicast...) will mess up your keyboard input
in a way I have not figured out, rendering keyboards unusable when **emulationstation**
exits. Not even unpluging/repluging the keyboard will fix it but this work around will, 
you must reboot otherwise.

In my images the tinker user has passwordless sudo rights, which is required
for this workaround to work. If your setting up your own image just give your
user the right to use sudo without a password, there is a few other quirks
with **emulationstation** that this fixes as well.


# Update RetroPie / Install more software


I have left the **RetroPie-Setup** and **TinkerRetroPie** repositorys in my prebuilt images
in the home directory of the tinker user.

You can CD into ``~/RetroPie-Setup`` and run: ``git pull`` to fetch the latest setup script changes.

Then run: ``sudo ./retropie_setup.sh`` to start the setup script, which will allow you to update
or install additional RetroPie packages by building them from source.


# Performance

The ``install.sh`` script from the generated installer tarball will install a boot time
configuration that enables a CPU frequency boost up to 2.06GH (on_demand governor).

Inside this same boot script, the devfreq support for Mali built into the kernel is taken advantage of 
to pin the GPU to a 600MHz (its max clock).

The script that does this is ``etc/cpufrequtils``, which is copied to ``/etc/default/cpufrequtils``
by the install script.

Make sure you have everything heatsinked and/or a fan going.

With this boot configuration, reicast (dreamcast emulator) and mupen64plus run suprisingly well.

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

PS1: Todo, I imagine it works great given it works pretty well on PI and Tinker has at least twice the horsepower.


# Build from source / install yourself

Run ``build_installer.sh`` on your build machine.

On the first run you will be prompted if you want to build Armbian from source, if you say no you will
be asked for a path to an existing source tree where a build has been previously completed.

If you choose to let my script build Armbian for you, it will configure it automaticaly for tinkerboard
with Mali Midgard devfreq support enabled.

If you are going to point it at your own source tree, you need to build Armbian using the "next" kernel,
and enable Mali Midgard devfreq support from the kernel config menu before you build it.

The script expects to be pointed at the root directory of a built https://github.com/Armbian/build repository.

Building Armbian from source with my script will **require that you have docker installed** for simplicity.

When the script finishes running, **TinkerRetroPieInstaller.tar.gz** and the OS image will be left in the output directory.

Flash the OS image and setup a non root user named to your liking.

It is recommended that you set your user up to have passwordless sudo.

Log into that user and transfer **TinkerRetroPieInstaller.tar.gz** to their home directory.

If your not sure how to do that with ``rsync`` you can just power down your device, put the 
SDCard back in your computer and place it there manually.

Untar: ``tar -xvf TinkerRetroPieInstaller.tar.gz``

Run: ``sudo ./TinkerRetroPieInstaller/install.sh``

The script will install/build a bunch of requirements for RetroPie including userland GPU drivers.

It will also enable a CPU boost to 2.06 GHz on boot, and a 600MHz clock speed for the Mali T760-MP4 GPU.

Once the script is done installing RetroPie requirements it will clone and launch the RetroPie setup script.

This will bring up a blue menu where you can select "Basic Install".

"Basic Install" will build and install all the core packages of RetroPie onto your system.

You can restart the RetroPie config script to install additional packages later or update software by running ``sudo ~/RetroPie-Setup/retropie_setup.sh``

Once installed, you can launch emulationstation, see the **Starting emulationstation** section above for recommendations on how to start it.


## Forcing source update + rebuild

Running ``build_installer.sh --force-armbian-rebuild`` will prompt you if you want to clone/update Armbian sources
again even they are already present in the build tree. It also works if you have already told the script an 
explicit build folder location other than the default one it clones for you.

Saying 'yes' will cause the script to update the Armbian build script sources to their lastest version, and then
run the build over again.  If you have pointed this script at a build directory you cloned yourself, it will update it.

An installer package will be generated overwriting the old one, and the most recently produced 
Armbian image will be put into the output folder of the **TinkerRetroPie** build tree possibly 
overwriting the last one that was produced.

# Create your own distributable image

The ``squash_sd_img.sh`` can be used to shrink the filesystem on you SDCard to its minimal size,
clone it to an image and then return the filesystem on your device back to normal.

Note that this is probably not a great thing to do repeatedly to your SDCard, but it works.

If you are doing this for the Armbian image you just built and logged into, you should run
this command first and then shutdown (dont restart before making an image):

``sudo systemctl enable armbian-resize-filesystem``

This command will enable Armbian's onshot systemd service that expands the filesystem back
to its maximum size upon boot.  After the filesystem is expanded again the service disables itself.


``bash

# Shrink /dev/mmcblk0p1
# mmcblk0 is typicaly the name of your built in SDCard reader
# but you really should verify its the correct device first...

# Note that the partition is specified not the root device itself (p1)

# Generally Armbian OS images will have one primary partition, as with most SBC
# images.  You want to pick the primary partition, and it must be the last
# partition on the device.

./squash_sd_img.sh /dev/mmcblk0p1 my_customized_image.img

# Your bootable minified image will be written to my_customized_image.img


``








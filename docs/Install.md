# Manual install

These are installation instructions for Pie-Galaxy onto RetroPie.  Standard GNU/Linux is not supported at this time, but is planned.

Installation is currently performed at the command line.  It is suggested that you use SSH so that you can copy and paste commands.

## Connecting to RetroPie via SSH

Default RetroPie username: pi
Default RetroPie password: raspberry

(These are from the Raspbian project, which RetroPie uses as the base OS on Pi systems)

### Get the IP Address

- The IP address can be found by selecting "SHOW IP" from the RetroPie menu in EmulationStation.

- The computer you're using to setup Pie-Galaxy on the RetroPie with needs to have SSH access to the RetroPie system.

- While you can do these steps over the console of the RetroPie system in a shell, its not suggested as there's a bit of copy and paste activity.


### Linux, Mac, BSD, etc.:

open a terminal and type:

   ssh pi@\<IP-Address\>

### Windows

Use putty, follow the [official raspberrypi.org documentation :D](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md)


## Installation

You need to make sure you have a recent retropie-setup version.

- The install script requires commit 872e2ae or newer, from February 27th, 2019.  retropie_package.sh should be version 4.4.9 or greater.

- If you have an older version, update the retropie-setup script before running Pie-Galaxy... or just do that anyways, its a good idea.


### Installation steps

1. Update the retropie_setup script

- run the command:

```
sudo Retropie-Setup/retropie_setup.sh
```

- then select "Update" from the menu, and follow the prompts

- If you update the underlying OS packages as well, be sure to reboot before expecting things to work

2. Download the packagefile

```
wget -O "${HOME}/RetroPie-Setup/scriptmodules/ports/piegalaxy.sh" https://raw.githubusercontent.com/sigboe/pie-galaxy/master/scriptmodule.sh
```

3. Run the package installer

```
sudo "${HOME}/RetroPie-Setup/retropie_packages.sh" piegalaxy
```

### Logging in with a keyboard

1. connect a keyboard to your Raspbery Pi and open Retro Pie from emulation station

### Loggin in via SSH

1. Open Pie Galaxy by running the following command

```
~/RetroPie/roms/ports/Pie\ Galaxy.sh
```
2. login using email and password or via code.

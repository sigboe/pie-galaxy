# Manual install

These are installation instructions for RetroPie.  Standard GNU/Linux is not supported at this time, but is planned.

Installation is currently performed at the command line.  It is suggested that you use SSH so that you can copy and paste commands.

## Connecting to RetroPie via SSH

### Linux and Mac

open a terminal and type:

   ssh pi@<IP-Address>

The default password is raspberry, the IP address can be found in the RetroPie menu on the main menu.

### Windows

Use putty, follow the [official raspberrypi.org documentation :D](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md)


## Installation

You need to make sure you have a recent retropie-setup version.

- The install script requires commit 872e2ae or newer, from February 27th, 2019.

- If you have an older version, update the retropie-setup script before running Pie-Galaxy... or just do that anyways, its a good idea.


### Installation steps

1. Download the packagefile

    wget -O "${HOME}/RetroPie-Setup/scriptmodules/ports/piegalaxy.sh" https://raw.githubusercontent.com/sigboe/pie-galaxy/master/scriptmodule.sh

2. Run the package installer

    sudo "${HOME}/RetroPie-Setup/retropie_packages.sh" piegalaxy

3. Follow the configuration steps (below) before you disconnect from SSH


## Configuration

Currently we need to log in by opening a URL in any webbrowser, then copying and pasting a token that is returned into an ssh session into RetroPie running Pie Galaxy.


### Configuration steps

1. Generate the url

while ssh'd into RetroPie, run:
/opt/retropie/ports/piegalaxy/wyvern ls

2. Visit the url in a browser

3. After log in, there should be a blank site.  

Notice that the url changed.   The token is in the new URL!  Copy everything after "code=" and paste it back into the SSH client.

4. There should be a list of all of your GOG games.  

If not, revisit the Configuration steps 1-3, or troubleshoot basics (is there Internet connectivity in order to reach GOG?  Can the Pi reach the Internet? etc.)

5. Once you see the list, restart

Restart EmulationStation, or Reboot the RetroPie system

6. The program will show up in EmulationStation under the Ports menu


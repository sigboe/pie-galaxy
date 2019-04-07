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

   ssh pi@<IP-Address>

### Windows

Use putty, follow the [official raspberrypi.org documentation :D](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md)


## Installation

You need to make sure you have a recent retropie-setup version.

- The install script requires commit 872e2ae or newer, from February 27th, 2019.  retropie_package.sh should be version 4.4.9 or greater.

- If you have an older version, update the retropie-setup script before running Pie-Galaxy... or just do that anyways, its a good idea.


### Installation steps

1. Update the retropie_setup script

- run the command:
sudo 

- then select "Update" from the menu, and follow the prompts

- If you update the underlying OS packages as well, be sure to reboot before expecting things to work




2. Download the packagefile

    wget -O "${HOME}/RetroPie-Setup/scriptmodules/ports/piegalaxy.sh" https://raw.githubusercontent.com/sigboe/pie-galaxy/master/scriptmodule.sh

3. Run the package installer

    sudo "${HOME}/RetroPie-Setup/retropie_packages.sh" piegalaxy

4. Follow the configuration steps (below) before you disconnect from SSH


## Configuration

Open a URL in any webbrowser, then copy and paste a token from a url into an ssh session into RetroPie running Pie Galaxy.


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


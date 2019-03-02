# Manual install

These are installation instructions for RetroPie, standard GNU/Linux is not supported yet.

Before this application is comepletely finished, installation will have to be done via SSH. You only need to copy and paste commands.

## Connecting to RetroPie via SSH

### Linux and Mac

Of course you know this already, just open a terminal and type:

   ssh pi@[IP-Address]

The default password is raspberry, the IP address can be found in the RetroPie menu on the main menu.

### Windows

Follow the [official documentation :D](https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md)

## Installing

You need to make sure you have a recent retropie-setup version.
The install script requires commit 872e2ae or newer, from february 27, 2019.
If you have an older version update the retropie-setup script first.

Download the packagefile

    wget -O "${HOME}/RetroPie-Setup/scriptmodules/ports/piegalaxy.sh" https://raw.githubusercontent.com/sigboe/pie-galaxy/master/scriptmodule.sh

Run the package installer

    sudo "${HOME}/RetroPie-Setup/retropie_packages.sh" piegalaxy

Follow the configuration steps before you disconnect from SSH

## Configuring

Currently we need to logg in by going to an URL in your webbrowser, then copy pasting a token back.

    /opt/retropie/ports/piegalaxy/wyvern ls

Copy the URL to your webbrowser, and log in. After you logg in you will get to a blank site
The token is in the URL of the webbrowser, copy everything after code= and paste it back into the SSH client.

If you managed to do it correctly, you should see a list of all your games.

Restart EmulationStation, or Reboot, and the program will show up in EmulationStation under Ports.
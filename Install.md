# Manual install

These are installation instructions for RetroPie, standard GNU/Linux is not supported yet.

Before this application is comepletely finished, installation will have to be done via SSH. You mostly need to copy and paste commands.

## Connecting to RetroPie via SSH

### Linux and Mac

Of course you know this already, just open a terminal and type:

   ssh pi@<IP-Address> 

The default password is raspberry, the IP address can be found in the RetroPie menu on the main menu.

### Windows

Just read the official documentation :D

https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md

## Installing dependencies

    sudo apt install jq html2text unar

## Installing

First we get the files

    cd /opt
    sudo git clone https://github.com/sigboe/pie-galaxy.git piegalaxy && cd piegalaxy

Then we need wyvern

    wget -O wyvern https://demenses.net/wyvern-1.3.0-armv7
    wget http://constexpr.org/innoextract/files/snapshots/innoextract-1.8-dev-2019-01-13/innoextract-1.8-dev-2019-01-13-linux.tar.xz

Also we need a recent version of innoextract

    tar xf innoextract-1.8-dev-2019-01-13-linux.tar.xz innoextract-1.8-dev-2019-01-13-linux/bin/armv6j-hardfloat/innoextract
    cp innoextract-1.8-dev-2019-01-13-linux/bin/armv6j-hardfloat/innoextract" .
    rm -rf innoextract-1.8-dev-2019-01-13-linux innoextract-1.8-dev-2019-01-13-linux.tar.xz

Lastly we make a shortcut in EmulationStation

    ln -s /opt/piegalaxy/pie-galaxy.sh "/home/pi/RetroPie/roms/ports/Pie Galaxy.sh"

## Configuring

We need to run a command before it will work.

    /opt/piegalaxy/wyvern ls

and follow the instructions to log in.
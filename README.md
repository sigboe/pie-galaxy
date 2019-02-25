# Pie Galaxy

A GOG client for RetroPie and other GNU/Linux distributions. It uses [Wyvern](https://github.com/nicohman/wyvern/) to download and [Innoextract](https://github.com/dscharrer/innoextract) to extract games. Pie Galaxy also provides a user interface navigatable by game controllers and will install games in such a way that it will use native runtimes. It also uses Wyvern to let you claim games available from [GOG Connect](https://gog.com/connect).

Pie Galaxy does not support every game yet, and is not feature complete. And is provided without warranty.

## Installing

Hopefully you will be able to install this program from the RetroPie setup menu soon.
[Untill then read here](Install.md)

## Features

* Claim games available fro GOG connect
* List all the games you own, and read their description
* Download any game you own
* Install games ([See compatibility list](#compatiblity))

## Compatiblity

* DOSBox games
  * Every game I have tested thus far has worked
  * Teenagent will install as a ScummVM game
* ScummVM games
  * Every game I have tested thus far has worked
* ResidualVM games
  * Escape from Monkey Island (Works!)
  * Myst 3 (Not added support yet)
  * Grim Fandango (Only remastered is on GOG, can't use it.)
* Native games
  * Ultimate DOOM, The

## Todo

### Soon

* Amiga games
* NEO-GEO games
* More Native games

### Furture

* Sync savegames
* Gamepad for more games
* Automatic notification when Connect games are available

### Research

* Native game: Jedi Outcast/Academy
* Native game: Heroes 3 (HOMM3)
* Basic friend support
  * List friends online status
  * Maybe more
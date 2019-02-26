# Frequently Asked Questions

## I can't I select a file to install

Its the ncurses filemanager that expects you to move the cursor to a file and press `Space`.

To do this ona a game pad I found it most convenient to press up a few times until you get to the file, and press the `Back` button on the gamepad (defaults to `X` on PS, or `B` on Nintendo)

## I can't see the games I installed in EmulationStation

`Start` > `Quit` > `Restart EmulationStation`

## I cant start the ScummVM game I just installed

Open up the ScummVM GUI and add the game. The shortcut in EmulationStation should work now.

## Gamepad in ScummVM games is erratic

Yes, if you get the lr-scummvm instead, it you get improvements like better gamepad support, and you don't need to add games in the GUI after you install them.

## why are there symbols displayed like ~D in my game list?

ncurses in Raspbian doesn't like UTF-8 symbols, it renders ™ like ~D. This doesn't happen on other Linux systems, but there may be a way to fix it.

## There is no progress bar while downloading

This bug is only on RetroPie, looking into it.
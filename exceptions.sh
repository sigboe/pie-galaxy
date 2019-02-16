#!/usr/bin/env bash
exceptionList=(
1440164514 #Ultimate DOOM, The
#1207658753 #TEST Teenagent
)

1440164514_exception() {
    dialog --backtitle "${title}" --msgbox "you are inside exception function for ${gameName}" 22 77
}

1207658753_exception() {
    dialog --backtitle "${title}" --msgbox "you are inside exception function for ${gameName}" 22 77
}
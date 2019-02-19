#!/usr/bin/env bash
# didnt have a use for this but keeping it in the repo for future non RetroPie use

dosboxromdir="${HOME}/RetroPie/roms/pc"
game=$(basename -s .sh "${0}")

if [[ -x "/opt/retropie/emulators/dosbox/bin/dosbox" ]]; then
	emu="/opt/retropie/emulators/dosbox/bin/dosbox"
fi

if ! [[ -x "$(command -v ${emu})" ]]; then
	echo "DOSBox not installed."
	exit 1
fi

echo "Launching ${game}"
cd "${dosboxromdir}/${game}/DOSBOX" || exit 1
mapfile -t dosboxargs < <(jq --raw-output '.playTasks[] | select(.isPrimary==true) | .arguments' ../goggame-*.info | sed 's:\\:/:g;s:\"::g')
echo "Found arugments: ${dosboxargs[*]}"

"${emu:-dosbox}" ${dosboxargs[*]}

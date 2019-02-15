#!/usr/bin/env bash

emu="dosbox"
game=$(basename "${0%.sh}")

if [[ -x emu="/opt/retropie/emulators/dosbox/bin/dosbox" ]]; then
	emu="/opt/retropie/emulators/dosbox/bin/dosbox"
fi

if ! [[ -x "$(command -v ${emu})" ]]; then
	echo "DOSBox not installed."
	exit 1
fi

echo "Launching ${game}"
cd "${game}/DOSBOX" || exit 1
mapfile -t dosboxargs < <(jq --raw-output '.playTasks[] | select(.isPrimary==true) | .arguments' ../goggame-*.info | sed 's:\\:/:g;s:\"::g')
echo "Found arugments: ${dosboxargs[*]}"

"${emu}" ${dosboxargs[*]} 
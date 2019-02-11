#!/usr/bin/env bash

basename=$(basename "${0}")
game="${basename%.sh}"

if ! [[ -x "$(command -v dosbox)" ]]; then
	echo "DOSBox not installed."
	exit 1
fi

echo "Launching ${game}"
cd "${game}/DOSBOX" || exit 1
mapfile -t dosboxargs < <(jq --raw-output '.playTasks[] | select(.isPrimary==true) | .arguments' ../goggame-*.info | sed 's:\\:/:g;s:\"::g')
echo "Found arugments: ${dosboxargs[*]}"

dosbox ${dosboxargs[*]} 
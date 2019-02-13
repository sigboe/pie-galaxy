#!/usr/bin/env bash

title="Pie Galaxy"
tmpdir="${HOME}/wyvern_tmp/"
romdir="${HOME}/RetroPie/roms"
wyvernls=$(wyvern ls --json)
basename=$(basename "${0}")
#version="0.1" #set a version when the core function work


_depends() {
	#wyvern needs cargo and libssl-dev
	#wyvern needs $HOME/.cargo/bin in path
	if ! [[ -x "$(command -v wyvern)" ]]; then
		echo "Wyvern not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v innoextract)" ]]; then
		echo "innoextract not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v jq)" ]]; then
		echo "jq not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v dialog)" ]]; then
		echo "dialog not installed."
		exit 1
	fi
	#need to also check for dosbox
}

_menu() {
	menuOptions=("connect" "Operations associated with GOG Connect." "down" "Download specific game." "install" "Install a GOG game from an installer." "ls" "List all games you own." "sync" "Sync a game's saves to a specific location for backup." "about" "About this program.")

	selected=$(dialog --title "${title}" --cancel-label "Exit" --menu "Chose one" 22 77 16 "${menuOptions[@]}" 3>&2 2>&1 1>&3)

	"_${selected:-exit}"
	#echo -e "\n${selected}"
	#printf '%s\n' "${menuOptions[@]}"
}

_ls() {
	mapfile -t myLibrary < <(echo "${wyvernls}" | jq --raw-output '.games[] | .ProductInfo | .id, .title')

	selectedGame=$(dialog --title "${title}" --menu "Chose one" 22 77 16 "${myLibrary[@]}" 3>&2 2>&1 1>&3)

	gameName=$(echo "${wyvernls}" | jq --raw-output --argjson var "${selectedGame}" '.games[] | .ProductInfo | select(.id==$var) | .title')
	gameDescription=$(curl -s "http://api.gog.com/products/${selectedGame}?expand=description" | jq --raw-output '.description | .full' | sed s:\<br\>:\\n:g)

	dialog --title "${gameName}" --ok-label "Select" --msgbox "${gameDescription}" 22 77

	_menu
}

_connect() {
	availableGames=$(wyvern connect ls 2>&1)
	dialog --title "${title}" --yesno "Available games:\n\n${availableGames##*wyvern:\ } \n\nDo you want to claim the games?" 22 77
	response="${?}"

	if [[ $response ]]; then
		wyvern connect claim
	fi

	_menu
}

_down() {
	if [[ -z ${selectedGame} ]]; then
		dialog --title "${title}" --msgbox "No game selected, please use ls to list all games you own." 22 77
		_menu
	else
		mkdir -p "${tmpdir}/${gameName}"
		cd "${tmpdir}/${gameName}" || exit 1
		wyvern down --id "${selectedGame}" --force-windows
		dialog --title "${title}" --msgbox "${gameName} finished downloading." 22 77
	fi

	_menu
}

_checklogin(){
	if ! [[ -f "${HOME}/.config/wyvern/wyvern.toml" ]]; then

		#This here check doesnt work, need to check the file for the token too.

		echo "Right now its easier if you ssh into the RaspberryPie and run \`wyvern ls\` and follow the instructions to login."

		# url=$(timeout 1 wyvern ls | head -2 | tail -1)

		# curl --cookie-jar cjar --output /dev/null "${url}"

		# curl --cookie cjar --cookie-jar cjar \
		# 	--data "login[username]=${goguser}" \
		# 	--data "login[password]=${gogpass}" \
		# 	--data "form_id=login" \
		# 	--location \
		# 	--output login-result.html \
		# 	"${url}/login_check"


		#wyvern ls

		#try something fancy here, want to open a terminal based webbrowser, and fetch the token from the URL name and pass it back to wyvern

	fi
}

_about(){
	dialog --title "${title}" --msgbox "This graphical user interface is made possible by Nico Hickman's Wyvern which is a terminal based GOG client. ${title} was developed to make make it useful on RetroPie." 22 77
	#this about screen can get a bit more detailed
	_menu
}

_sync(){
	dialog --title "${title}" --msgbox "This feature is not written yet for RetroPie." 22 77
	#need to write a sync, maybe open a menu to check for games with support or something.
	_menu
}

_install(){
    fileSelected=$(dialog --title "${title}" --stdout --fselect "${tmpdir}" 22 77)

    gameID=$(innoextract -s --gog-game-id "${fileSelected}")
	gameName=$(echo "${wyvernls}" | jq --raw-output --argjson var "${gameID}" '.games[] | .ProductInfo | select(.id==$var) | .title')

	rm -rf "${tmpdir}/app" #clean the extract path (is this okay to do like this?)
	innoextract --gog --include app "${fileSelected}" --output-dir "${tmpdir}"
	mv "${tmpdir}/app" "${tmpdir}/${gameName}"

	_getType "${gameName}"

	if [[ "$type" == "dosbox" ]]; then
		mv "${tmpdir}/${gameName}" "${romdir}/pc"
		cd "${romdir}" || exit 1
		ln -s "${basename%/*}/DOSBox-template.sh" "${gameName}.sh"
	elif [[ "$type" == "scummvm" ]]; then
		mv "${tmpdir}/${gameName}" "${romdir}/scummvm"
		cd "${romdir}" || exit 1
		ln -s "${basename%/*}/ScummVM-template.sh" "${gameName}.sh"
	fi
	
	clear
	echo "${fileSelected}" #this shouldn't be here when this function works.
	#_menu
}

_getType(){

	_path=$(cat "${1}"/goggame-*.info | jq --raw-output '.playTasks[] | select(.isPrimary==true) | .path')

	if [[ "${_path}" == *"DOSBOX"* ]]; then
		type="dosbox"
	elif [[ "${_path}" == *"SCUMMVM"* ]]; then
		# not tested
		type="scummvm" 
	elif [[ "${_path}" == *"neogeo"* ]]; then
		# Surly this wont work, but its a placeholder
		type="neogeo"
	else
		dialog --title "${title}" --msgbox "Didn't find what game it was.\nNot installing." 22 77
		_menu
		# can maybe detect and install some ports too.
	fi
	
}

_exit() {
	clear
	exit 0
}

_depends
_checklogin
_menu

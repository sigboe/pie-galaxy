#!/usr/bin/env bash

title="Pie Galaxy"
tmpdir="${HOME}/wyvern_tmp"
romdir="${HOME}/RetroPie/roms"
dosboxdir="${romdir}/pc"
scummvmdir="${romdir}/scummvm"
wyvernbin="/home/pi/pie-galaxy/wyvern"
innobin="$(command -v innoextract)"
exceptions="${HOME}/pie-galaxy/exceptions.sh"
#scriptdir=$(pwd)
renderhtml="html2text"
#version="0.1" #set a version when the core function work

_depends() {
	#wyvern needs cargo and libssl-dev
	#wyvern needs $HOME/.cargo/bin in path
	if ! [[ -x "${wyvernbin}" ]]; then
		echo "Wyvern not installed."
		exit 1
	fi
	if ! [[ -x "${innobin}" ]]; then
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
	if ! [[ -x "$(command -v html2text)" ]]; then
		renderhtml="sed s:\<br\>:\\n:g"
	fi
	#need to also check for dosbox
}

_menu() {
	menuOptions=(
		"connect" "Operations associated with GOG Connect." 
		"down" "Download specific game." 
		"install" "Install a GOG game from an installer." 
		"ls" "List all games you own." 
		"sync" "Sync a game's saves to a specific location for backup." 
		"about" "About this program."
		)

	selected=$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--menu "Chose one" 22 77 16 "${menuOptions[@]}" 3>&2 2>&1 1>&3)

	"_${selected:-exit}"
	#echo -e "\n${selected}"
	#printf '%s\n' "${menuOptions[@]}"
}

_ls() {
	mapfile -t myLibrary < <(echo "${wyvernls}" | jq --raw-output '.games[] | .ProductInfo | .id, .title')

	unset selectedGame
	selectedGame=$(dialog \
		--backtitle "${title}" \
		--ok-label "Details" \
		--menu "Chose one" 22 77 16 "${myLibrary[@]}" 3>&2 2>&1 1>&3)

	if [[ -n "${selectedGame}" ]]; then
		_description "${selectedGame}"
	fi

	_menu
}

_description() {
	gameName=$(echo "${wyvernls}" | jq --raw-output --argjson var "${1}" '.games[] | .ProductInfo | select(.id==$var) | .title')
	gameDescription=$(curl -s "http://api.gog.com/products/${1}?expand=description" | jq --raw-output '.description | .full' | $renderhtml)
	
	local url page
	url="$(echo "${wyvernls}" | jq --raw-output --argjson var "${1}" '.games[] | .ProductInfo | select(.id==$var) | .url' )"
	page="$(curl -s "https://www.gog.com${url}")"

    if echo "${page}" | grep -q "This game is powered by <a href=\"https://www.dosbox.com/\" class=\"dosbox-info__link\">DOSBox"; then
        gameDescription="This game is powered by DOSBox\n\n${gameDescription}"

    elif echo "${page}" | grep -q "This game is powered by <a href=http://scummvm.org>ScummVM"; then
        gameDescription="This game is powered by ScummVM\n\n${gameDescription}"

    else
        gameDescription="${gameDescription}"

    fi

	dialog \
		--backtitle "${title}" \
		--title "${gameName}" \
		--ok-label "Select" \
		--msgbox "${gameDescription}" \
		22 77

}

_connect() {
	availableGames=$("${wyvernbin}" connect ls 2>&1)

	local response
	response=$(dialog \
	--backtitle "${title}" \
	--yesno "Available games:\n\n${availableGames##*wyvern} \n\nDo you want to claim the games?" 22 77)

	if [[ $response ]]; then
		"${wyvernbin}" connect claim
	fi

	_menu
}

_down() {
	if [[ -z ${selectedGame} ]]; then
		dialog --backtitle "${title}" --msgbox "No game selected, please use ls to list all games you own." 22 77
		_menu
	else
		mkdir -p "${tmpdir}"
		cd "${tmpdir}/" || _exit 1
		"${wyvernbin}" down --id "${selectedGame}" --force-windows
		dialog --backtitle "${title}" --msgbox "${gameName} finished downloading." 22 77
	fi

	_menu
}

_checklogin() {
	if [[ -f "${HOME}/.config/wyvern/wyvern.toml" ]]; then
		if grep -q "access_token =" "${HOME}/.config/wyvern/wyvern.toml"; then
			wyvernls=$("${wyvernbin}" ls --json)
		else
			echo "Right now its easier if you ssh into the RaspberryPie and run \`wyvern ls\` and follow the instructions to login."
			_exit 1
		fi
	fi
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
}

_about() {
	dialog \
	--backtitle "${title}" \
	--msgbox "This graphical user interface is made possible by Nico Hickman's Wyvern which is a terminal based GOG client. ${title} was developed to make make it useful on RetroPie." 22 77
	#this about screen can get a bit more detailed
	_menu
}

_sync() {
	dialog --backtitle "${title}" --msgbox "This feature is not written yet for RetroPie." 22 77
	#need to write a sync, maybe open a menu to check for games with support or something.
	_menu
}

_install() {
	local fileSelected setupInfo gameName gameID response match type
	fileSelected=$(dialog --title "${title}" --stdout --fselect "${tmpdir}/" 22 77)

	if ! [[ -f "${fileSelected}" ]]; then
		dialog --backtitle "${title}" --msgbox "No file was selected." 22 77
	else

		setupInfo=$("${innobin}" --gog-game-id "${fileSelected}")
		gameName=$(echo "${setupInfo}" | awk -F'"' '{print $2}')
		gameID=$("${innobin}" -s --gog-game-id "${fileSelected}")

		dialog \
			--backtitle "${title}" \
			--title "${gameName}" \
			--yesno "${setupInfo}" \
			22 77 || _menu

		source "${exceptions}"
		match=$(echo "${exceptionList[@]:0}" | grep -o "${gameID}")  
		if [[ -n "${match}" ]]; then
			_extract
			"${gameID}_exception"
			_menu
		else
		_extract
		fi

		type=$(_getType "${gameName}")

		if [[ "$type" == "dosbox" ]]; then
			mv -f "${tmpdir}/${gameName}" "${dosboxdir}"
			cd "${dosboxdir}" || _exit 1
			#ln -s "${scriptdir}/DOSBox-template.sh" "${gameName}.sh"
		elif [[ "$type" == "scummvm" ]]; then
			mv -f "${tmpdir}/${gameName}" "${scummvmdir}"
			cd "${scummvmdir}" || _exit 1
			#ln -s "${scriptdir}/ScummVM-template.sh" "${gameName}.sh"
		elif [[ "$type" == "unsupported" ]]; then
			dialog --backtitle "${title}" --msgbox "${fileSelected} apperantly is unsupported." 22 77
			_menu
		fi

		dialog --backtitle "${title}" --msgbox "${gameName} was installed.\n${gameID}\n${fileSelected} was extracted and installed to ${romdir}" 22 77
	fi

	_menu

}

_extract() {
	rm -rf "${tmpdir}/app" #clean the extract path (is this okay to do like this?)
	"${innobin}" --gog --include app "${fileSelected}" --output-dir "${tmpdir}/" || (dialog --backtitle "${title}" --msgbox "ERROR: Unable to read setup file" 22 77; _menu)
	mv "${tmpdir}/app" "${tmpdir}/${gameName}"
	true
}

_getType() {

	local gamePath type
	gamePath=$(cat "${tmpdir}/${1}/"goggame-*.info | jq --raw-output '.playTasks[] | select(.isPrimary==true) | .path')

	if [[ "${gamePath}" == *"DOSBOX"* ]]; then
		type="dosbox"
	elif [[ "${gamePath}" == *"SCUMMVM"* ]]; then
		# not tested
		type="scummvm"
	elif [[ "${gamePath}" == *"neogeo"* ]]; then
		# Surly this wont work, but its a placeholder
		type="neogeo"
	else
		dialog --backtitle "${title}" --msgbox "Didn't find what game it was.\nNot installing." 22 77
		_menu
		# can maybe detect and install some ports too.
	fi

	echo "${type:-unsupported}"
}

_joy2key() {
	if [[ -f "${HOME}/RetroPie-Setup/scriptmodules/helpers.sh" ]]; then
		local scriptdir="/home/pi/RetroPie-Setup"
		source "${HOME}/RetroPie-Setup/scriptmodules/helpers.sh"
		joy2keyStart
	fi
}
_exit() {
	clear
	if [[ -f "${HOME}/RetroPie-Setup/scriptmodules/helpers.sh" ]]; then
		joy2keyStop
	fi
	exit "${1:-0}"
}

_joy2key
_depends
_checklogin
_menu
_exit

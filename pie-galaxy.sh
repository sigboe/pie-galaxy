#!/usr/bin/env bash
# This application was made by https://github.com/sigboe
# The License is GNU General Public License v3.0
# https://github.com/sigboe/pie-galaxy/blob/master/LICENSE

title="Pie Galaxy"
tmpdir="${HOME}/tmp/piegalaxy"
romdir="${HOME}/RetroPie/roms"
dosboxdir="${romdir}/pc"
scummvmdir="${romdir}/scummvm"
scriptdir="$(dirname "$(readlink -f "${0}")")"
wyvernbin="${scriptdir}/wyvern"
innobin="${scriptdir}/innoextract"
exceptions="${scriptdir}/exceptions"
renderhtml="html2text"
exceptionList="" #empty var, this will be overrwritten at runime
version="0.1"

_depends() {
	if ! [[ -x "${wyvernbin}" ]]; then
		_error "Wyvern not installed."
		exit 1
	fi
	if ! [[ -x "${innobin}" ]]; then
		_error "innoextract not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v jq)" ]]; then
		_error "jq not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v dialog)" ]]; then
		_error "dialog not installed."
		exit 1
	fi
	if ! [[ -x "$(command -v html2text)" ]]; then
		renderhtml="sed s:\<br\>:\\n:g"
	fi
}

_menu() {
	menuOptions=(
		"Connect" "Operations associated with GOG Connect"
		"Download" "Download game ${gameName:-selected from the Library}"
		"Install" "Install a GOG game from an installer"
		"Library" "List all games you own"
		"Sync" "Sync a game's saves to a specific location for backup"
		"About" "About this program"
	)

	selected=$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >$(tty) <$(tty))

	"_${selected:-exit}"
}

_Library() {
	mapfile -t myLibrary < <(echo "${wyvernls}" | jq --raw-output '.games[] | .ProductInfo | .id, .title')

	unset selectedGame
	selectedGame=$(dialog \
		--backtitle "${title}" \
		--ok-label "Details" \
		--menu "Chose one" 22 77 16 "${myLibrary[@]}" 3>&1 1>&2 2>&3 >$(tty) <$(tty))

	if [[ -n "${selectedGame}" ]]; then
		_description "${selectedGame}"
	fi

	_menu
}

_description() {
	gameName=$(echo "${wyvernls}" | jq --raw-output --argjson var "${1}" '.games[] | .ProductInfo | select(.id==$var) | .title')
	gameDescription=$(curl -s "http://api.gog.com/products/${1}?expand=description" | jq --raw-output '.description | .full' | $renderhtml)

	local url page
	url="$(echo "${wyvernls}" | jq --raw-output --argjson var "${1}" '.games[] | .ProductInfo | select(.id==$var) | .url')"
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

_Connect() {
	availableGames=$("${wyvernbin}" connect ls 3>&1 1>&2 2>&3 >$(tty) <$(tty))

	local response
	response=$(dialog \
		--backtitle "${title}" \
		--yesno "Available games:\n\n${availableGames##*wyvern} \n\nDo you want to claim the games?" \
		22 77 3>&1 1>&2 2>&3 >$(tty) <$(tty))

	if [[ $response ]]; then
		"${wyvernbin}" connect claim
	fi

	_menu
}

_Download() {
	if [[ -z ${selectedGame} ]]; then
		dialog \
			--backtitle "${title}" \
			--msgbox "No game selected, please use ls to list all games you own." \
			22 77
		_menu
	else
		mkdir -p "${tmpdir}"
		cd "${tmpdir}/" || _exit 1
		"${wyvernbin}" down --id "${selectedGame}" --force-windows 3>&1 1>&2 2>&3 >$(tty) <$(tty)
		dialog \
			--backtitle "${title}" \
			--msgbox "${gameName} finished downloading." \
			22 77
	fi

	_menu
}

_checklogin() {
	if grep -q "access_token =" "${HOME}/.config/wyvern/wyvern.toml"; then
		wyvernls=$("${wyvernbin}" ls --json)
	else
		dialog \
			--backtitle "${title}" \
			--msgbox "You are not logged into wyvern\nLogging inn via this UI is not yet developed.\nRight now its easier if you ssh into the RaspberryPie and run\n\n${wyvernbin} ls\n\nand follow the instructions to login." \
			22 77
		_exit 1
	fi
}

_About() {
	dialog \
		--backtitle "${title}" \
		--msgbox "Version: ${version}\n\nA GOG client for RetroPie and other GNU/Linux distributions. It uses Wyvern to download and Innoextract to extract games. Pie Galaxy also provides a user interface navigatable by game controllers and will install games in such a way that it will use native runtimes. It also uses Wyvern to let you claim games available from GOG Connect." \
		22 77
	_menu
}

_Sync() {
	dialog \
		--backtitle "${title}" \
		--msgbox "This feature is not written yet for RetroPie." \
		22 77
	#need to write a sync, maybe open a menu to check for games with support or something.
	_menu
}

_Install() {
	local fileSelected setupInfo gameName gameID response match type shortName
	fileSelected=$(dialog --backtitle "${title}" --fselect "${tmpdir}/" 22 77 3>&1 1>&2 2>&3 >$(tty) <$(tty))

	if ! [[ -f "${fileSelected}" ]]; then
		dialog \
			--backtitle "${title}" \
			--msgbox "No file was selected." \
			22 77
	else

		setupInfo=$("${innobin}" --gog-game-id "${fileSelected}")
		gameName=$(echo "${setupInfo}" |& awk -F'"' '{print $2}')
		gameID=$("${innobin}" -s --gog-game-id "${fileSelected}")

		dialog \
			--backtitle "${title}" \
			--title "${gameName}" \
			--yesno "${setupInfo}" \
			22 77 || _menu

		# shellcheck source=/dev/null
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
			mv -f "${tmpdir}/${gameName}" "${dosboxdir}" || _error "Uname to copy game to ${dosboxdir}\n\nThis is likely due to ScummVM not being installed."
		elif [[ "$type" == "scummvm" ]]; then
			shortName=$(find "${tmpdir}/${gameName}" -name '*.ini' -exec cat {} + | grep gameid | awk -F= '{print $2}' | sed -e "s/\r//g")
			mv -f "${tmpdir}/${gameName}" "${scummvmdir}/${gameName}.svm" || _error "Uname to copy game to ${scummvmdir}\n\nThis is likely due to ScummVM not being installed."
			echo "${shortName}" > "${scummvmdir}/${gameName}.svm/${shortName}.svm"
			local extraMessage="To finish the installation and open ScummVM and add game."
		elif [[ "$type" == "unsupported" ]]; then
			_error "${fileSelected} apperantly is unsupported."
			_menu
		fi

		dialog \
			--backtitle "${title}" \
			--msgbox "${gameName} was installed.\n${gameID}\n${fileSelected} was extracted and installed to ${romdir}\n\n${extraMessage}" \
			22 77
	fi

	_menu

}

_extract() {
	#There is a bug in innoextract that missinterprets the filestructure. using dirname & find as a workaround
	local folder
	rm -rf "${tmpdir:?}/output" #clean the extract path (is this okay to do like this?)
	"${innobin}" --gog "${fileSelected}" --output-dir "${tmpdir}/output" || (
		dialog \
			--backtitle "${title}" \
			--msgbox "ERROR: Unable to read setup file" \
			22 77
		_menu
	)
	folder=$(dirname "$(find "${tmpdir}"/output -name 'goggame-*.info')")
	rm -rf "${tmpdir:?}/${gameName}"
	mv "${folder}" "${tmpdir}/${gameName}"
}

_getType() {

	local gamePath type
	gamePath=$(cat "${tmpdir}/${1}/"goggame-*.info | jq --raw-output '.playTasks[] | select(.isPrimary==true) | .path')

	if [[ "${gamePath}" == *"DOSBOX"* ]]; then
		type="dosbox"
	elif [[ "${gamePath}" == *"scummvm"* ]]; then
		type="scummvm"
	elif [[ "${gamePath}" == *"neogeo"* ]]; then
		# Surly this wont work, but its a placeholder
		type="neogeo"
	else
		dialog \
			--backtitle "${title}" \
			--msgbox "Didn't find what game it was.\nNot installing." \
			22 77
		_menu
	fi

	echo "${type:-unsupported}"
}

_error() {
	dialog \
		--backtitle "${title}" \
		--msgbox "Error:\n\n${1}" \
		22 77
	_menu
}

_joy2key() {
	if [[ -f "${HOME}/RetroPie-Setup/scriptmodules/helpers.sh" ]]; then
		local scriptdir="/home/pi/RetroPie-Setup"
		# shellcheck source=/dev/null
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

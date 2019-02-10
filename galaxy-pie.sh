#!/usr/bin/env bash

title="Galaxy Pie"
tmpdir="${HOME}/wyvern_tmp/"
#version="0.1"

# _usage() {
# 	cat <<_EOF_ >&2
# Usage:
# $(basename "$0")
# _EOF_
# 	exit "${1}"
# }

# _version() {
# 	echo "$(basename "$0") ${version}"
# 	exit "${1}"
# }

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
	menuOptions=("connect" "Operations associated with GOG Connect." "down" "Download specific game" "install" "Install a GOG game from an installer." "ls" "List all games you own" "sync" "Sync a game's saves to a specific location for backup" "about" "About this program.")

	selected=$(dialog --title "${title}" --menu "Chose one" 22 77 16 "${menuOptions[@]}" 3>&2 2>&1 1>&3)

	"_${selected}"
	#echo -e "\n${selected}"
	#printf '%s\n' "${menuOptions[@]}"
}

_ls() {
	mapfile -t myLibrary < <(wyvern ls --json | jq --raw-output '.games[] | .[1,0]')

	selectedGame=$(dialog --title "${title}" --menu "Chose one" 22 77 16 "${myLibrary[@]}" 3>&2 2>&1 1>&3)

	for i in "${!myLibrary[@]}"; do
		if [[ "${myLibrary[$i]}" = "${selectedGame}" ]]; then
			gameName="${i}"
		fi
	done

	gameName="${myLibrary[$gameName+1]}"


	_menu
}

_connect() {
	availableGames=$(wyvern connect ls 2>&1)
	#echo -e "${availableGames}"; exit
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
		wyvern down --id "${selectedGame}" --windows-auto
		dialog --title "${title}" --msgbox "${gameName} finished downloading." 22 77
	fi

	_menu
}

_checklogin(){
	if ! [[ -f "${HOME}/.config/wyvern/wyvern.toml" ]]; then

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
	dialog --title "${title}" --msgbox "This graphical user interface is made possible by Nico Hickman's Wyvern which is a terminal based GOG client. ${title} was developed to make make it useful on RetroPie. \n\n\n ${gameName}" 22 77
	_menu
}

_sync(){
	dialog --title "${title}" --msgbox "This feature is not written yet for RetroPie." 22 77
	_menu
}

_install(){
	fileSelected=$(dialog --title "${title}" --stdout --fselect "${tmpdir}" 22 77)

	gameName=$(echo "${fileSelected}" | awk -F"/" '{print $(NF-1)}')

	innoextract --gog --exclude-temp "${fileSelected}" --output-dir "${tmpdir}"
	rm -rf "${tmpdir}/commonappdata"
	mv "${tmpdir}/app" "${tmpdir}/${gameName}"
	dosboxarg=$(jq '.playTasks[] | select(.isPrimary==true) | .arguments' "${tmpdir}/${gameName}/goggame-*.info" | sed 's:\\\\:/:g')
	


	clear
	echo "${fileSelected}"
	#_menu
}


_depends
_checklogin
_menu

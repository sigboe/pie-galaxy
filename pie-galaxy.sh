#!/usr/bin/env bash
# This application was made by https://github.com/sigboe
# The License is GNU General Public License v3.0
# https://github.com/sigboe/pie-galaxy/blob/master/LICENSE
# shellcheck disable=SC2094 # Dirty hack avoid runcommand to steal stdout

#Default settings don't edit as they will be overwritten when you update the program
#set prefrences in ~/.config/piegalaxy/piegalaxy.conf
title="Pie Galaxy"
tmpdir="${HOME}/.cache/piegalaxy"
downdir="${HOME}/Downloads"
romdir="${HOME}/RetroPie/roms"
dosboxdir="${romdir}/pc/gog"
scummvmdir="${romdir}/scummvm"
biosdir="${HOME}/RetroPie/BIOS"
scriptdir="$(dirname "$(readlink -f "${0}")")"
wyvernbin="${scriptdir}/wyvern"
innobin="${scriptdir}/innoextract"
imgViewer=(fbi -1 -t 5 -noverbose -a) #fbi -a -1 -t 5 #"${scriptdir}/pixterm" -d 1 -s 1
exceptions="${scriptdir}/exceptions"
renderhtml=(html2text -width 999 -style pretty)
retropiehelper="${HOME}/RetroPie-Setup/scriptmodules/helpers.sh"
configfile="${HOME}/.config/piegalaxy/piegalaxy.conf"
fullFileBrowser="false"
showImage="true"
version="0.2"

# fix UTF-8 symbols like © or ™
export LC_ALL=C.UTF-8
export LANGUAGE=C.UTF-8

if [[ -n "${XDG_CACHE_HOME}" ]]; then
	tmpdir="${XDG_CACHE_HOME}/piegalaxy"
fi

if [[ -n "${XDG_CONFIG_HOME}" ]]; then
	configfile="${XDG_CONFIG_HOME}/piegalaxy/piegalaxy.conf"
fi

# Read config file and sanitize input. If you want to change the defaults.
if [[ -f "${configfile}" ]]; then
	if grep -E -q -v '^#|^[^ ]*=[^;]*' "{$configfile}"; then
		echo "Config file is unclean, cleaning it..." >&2
		mv "${configfile}" "$(dirname "${configfile}")/dirty.conf"
		grep -E '^#|^[^ ]*=[^;&]*' "$(dirname "${configfile}")/dirty.conf" >"${configfile}"
	fi
	# shellcheck source=/dev/null
	source "${configfile}"
fi

# shellcheck source=exceptions
source "${exceptions}"

_depends() {
	if ! [[ -x "$(command -v dialog)" ]]; then
		echo "dialog not installed." >"$(tty)"
		sleep 10
		_exit 1
	fi

	if ! [[ -x "${wyvernbin}" ]]; then
		_error "Wyvern not installed." 1
	fi

	if ! [[ -x "${innobin}" ]]; then
		_error "innoextract not installed." 1
	fi

	if ! [[ -x "$(command -v jq)" ]]; then
		_error "jq not installed." 1
	fi

	if ! [[ -x "$(command -v "${renderhtml[0]}")" ]]; then
		renderhtml=(sed 's:\<br\>:\\n:g')
	fi

	if [[ -n "$DISPLAY" ]]; then
		imgViewer=(feh -F -N -Z -Y -q -D 5 --on-last-slide quit)
	fi
}

main() {
	menuOptions=(
		"Connect" "Operations associated with GOG Connect"
		"Library" "List all games you own"
		"Install" "Install a GOG game from an installer"
		"Sync" "Sync a game's saves to a specific location for backup"
		"About" "About this program"
	)

	selected="$(dialog \
		--backtitle "${title}" \
		--cancel-label "Exit" \
		--default-item "${selected}" \
		--menu "Choose one" \
		22 77 16 "${menuOptions[@]}" 3>&1 1>&2 2>&3 >"$(tty)")"

}

_Library() {
	local preSelected
	preSelected="${1}"

	[[ -n "${preSelected}" ]] && _description "${preSelected}"

	mapfile -t myLibrary < <(jq --raw-output '.games[] | .ProductInfo | .id, .title' <<<"${wyvernls}")

	selectedGame="$(dialog \
		--backtitle "${title}" \
		--ok-label "Details" \
		--default-item "${selectedGame}" \
		--menu "Choose one" 22 77 16 "${myLibrary[@]}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)")"

	if [[ -n "${selectedGame}" ]]; then
		_description "${selectedGame}"

		case "${?}" in
		0)
			# Download button
			_Download
			;;

		1 | 255)
			# Back button
			_Library
			;;

		3)
			# Image button
			"${imgViewer[@]}" "${imageCache}" </dev/tty &>/dev/null || _error "Image viewer failed"
			_Library "${selectedGame}"
			;;
		esac

	fi

}

# Displays the description of a game
# Checks if game is dosbox or scummvm by curling the store page
# usage _description "${gameID}"
_description() {
	local url page gameID gameDescription imgArgs
	export gameImage
	gameID="${1}"
	gameMetadata="$(curl -s "http://api.gog.com/products/${gameID}?expand=description")"

	gameName="$(jq --raw-output --argjson var "${gameID}" '.games[] | .ProductInfo | select(.id==$var) | .title' <<<"${wyvernls}")"
	gameDescription="$(jq --raw-output '.description | .full' <<<"${gameMetadata}")"
	gameDescription="$(echo "${gameDescription}" | "${renderhtml[@]}")"

	url="$(jq --raw-output --argjson var "${gameID}" '.games[] | .ProductInfo | select(.id==$var) | .url' <<<"${wyvernls}")"
	page="$(curl -s "https://www.gog.com${url}")"

	if grep -q "This game is powered by <a href=\"https://www.dosbox.com/\" class=\"dosbox-info__link\">DOSBox" <<<"${page}"; then
		printf -v gameDescription '%s\n\n%s\n' "This game is powered by DOSBox" "${gameDescription}"

	elif grep -q "This game is powered by <a href=http://scummvm.org>ScummVM" <<<"${page}"; then
		printf -v gameDescription '%s\n\n%s\n' "This game is powered by ScummVM" "${gameDescription}"
	fi

	if [[ "${showImage}" ]]; then
		imgArgs=(--extra-button --extra-label "Image")
		gameImageURL="https:$(jq --raw-output '.images | .logo2x' <<<"${gameMetadata}")"
		wget -O "${tmpdir}/${gameID}.${gameImageURL##*.}" "${gameImageURL}"
		imageCache="${tmpdir}/${gameID}.${gameImageURL##*.}"
	fi

	_yesno "${gameDescription}" --title "${gameName}" --ok-label "Download" "${imgArgs[@]}" --no-label "Back" --defaultno
	return "${?}"
}

_Connect() {
	availableGames="$("${wyvernbin}" connect ls 2>&1)"

	if _yesno "Available games:\n\n${availableGames##*wyvern} \n\nDo you want to claim the games?"; then
		"${wyvernbin}" connect claim
		_msgbox "Games claimed"
	fi

}

_Download() {
	if [[ -z "${selectedGame}" ]]; then
		_msgbox "No game selected, please use one from your library."
		return

	else
		mkdir -p "${downdir}"
		"${wyvernbin}" down --id "${selectedGame}" --windows-auto --output "${downdir}/" &>"$(tty)" || {
			_error "download failed"
			return
		}
		_msgbox "${gameName} finished downloading."
	fi

}

_checklogin() {
	if grep -q "access_token =" "${HOME}/.config/wyvern/wyvern.toml"; then
		wyvernls="$(timeout 30 "${wyvernbin}" ls --json)" || _error "It took longer than 30 seconds. You may need to log in again.\nLogging inn via this UI is not yet developed.\nRight now its easier if you ssh into the RaspberryPie and run\n\n${wyvernbin} ls\n\nand follow the instructions to login." 1

	else
		_error "You are not logged into wyvern\nLogging inn via this UI is not yet developed.\nRight now its easier if you ssh into the RaspberryPie and run\n\n${wyvernbin} ls\n\nand follow the instructions to login." 1
	fi
}

_About() {
	local about githash builddate wyvernVersion innoVersion gitbranch
	githash="$(git --git-dir="${scriptdir}/.git" rev-parse --short HEAD)"
	gitbranch="$(git --git-dir="${scriptdir}/.git" rev-parse --abbrev-ref HEAD)"
	builddate="$(git --git-dir="${scriptdir}/.git" log -1 --date=short --pretty=format:%cd)"
	wyvernVersion="$(${wyvernbin} --version)"
	innoVersion="$("${innobin}" --version -s)"
	read -rd '' about <<_EOF_
Pie Galaxy ${version}-${gitbranch}-${builddate} + ${githash}
innoextract ${innoVersion}
${wyvernVersion}


A GOG client for RetroPie and other GNU/Linux distributions. It uses Wyvern to download and Innoextract to extract games. Pie Galaxy also provides a user interface navigatable by game controllers and will install games in such a way that it will use native runtimes. It also uses Wyvern to let you claim games available from GOG Connect.
_EOF_
	_msgbox "${about}" --title "About"
}

_Sync() {
	_msgbox "This feature is not written yet for RetroPie."
}

_Install() {
	local fileSelected setupInfo gameName gameID gameType shortName extension subdir
	fileSelected="$(_fselect "${downdir}")"
	extension="${fileSelected##*.}"
	fileSize="$(du -h "${fileSelected}")"
	fileSize="${fileSize%%	*}"

	if [[ ! -f "${fileSelected}" ]]; then
		_error "No file was selected."
		return
	fi

	case "${extension,,}" in
	"exe")
		setupInfo="$("${innobin}" --gog-game-id "${fileSelected}")"
		gameName="$(awk -F'"' 'NR==1{print $2}' <<<"${setupInfo}")"
		gameID="$("${innobin}" -s --gog-game-id "${fileSelected}")"
		;;

	"sh")
		gameName="$(grep -Poam 1 'label="\K.*' "${fileSelected}")"
		gameName="${gameName% (GOG.com)\"}"
		setupInfo="Can't read info from .sh files yet."
		gameID="0"
		;;

	*)
		_error "$(basename "${fileSelected}")\n${fileSize}\n\nFile extension ${extension} not supported. Supported extensions are exe or sh." --extra-button --extra-label "Delete"
		if [[ "${?}" == "3" ]]; then rm "${fileSelected}"; fi
		return
		;;
	esac

	_yesno "${setupInfo}" --title "${gameName}" --extra-button --extra-label "Delete" --ok-label "Install"

	case $? in
	1 | 255)
		# cancel or esc
		return
		;;

	3)
		#delete
		rm "${fileSelected}" || {
			_error "unable to delete file"
			return
		}
		_msgbox "${fileSelected} deleted."
		return
		;;
	esac

	# If the setup.exe doesn't have the gameID try to fetch it from the gameName and the library.
	[[ -z "${gameID}" ]] && gameID="$(jq --raw-output --arg var "${gameName}" '.games[] | .ProductInfo | select(.title==$var) | .id' <<<"${wyvernls}")"

	if [[ -z "${gameID}" ]]; then
		# If setup.exe still doesn't contain gameID, try guessing the slug, and fetchign the ID that way.
		gameSlug="${gameName// /_}"
		gameSlug="${gameSlug,,}"
		gameID="$(jq --raw-output --arg var "${gameSlug}" '.games[] | .ProductInfo | select(.slug==$var) | .id' <<<"${wyvernls}")"
	fi

	[[ -z "${gameID}" ]] && {
		_error "Can't figure out the Game ID. Aborting installation."
		return
	}

	#Sanitize game name
	gameName="${gameName/™/}"
	gameName="${gameName/©/}"
	gameName="${gameName//+([[:blank:]])/ }"

	_extract "${fileSelected}" "${gameName}"

	if type "${gameID}_exception" &>/dev/null; then
		"${gameID}_exception"
		return

	elif [[ ! -d "${tmpdir}/${gameName}" ]]; then
		_error "Extraction did not succeed"
		return
	fi

	gameType="$(_getType "${gameName}")"

	case "${gameType}" in

	"dosbox")
		[[ ! -d "${dosboxdir}" ]] || {
			_error "Unable to copy game to ${dosboxdir}\n\nThis is likely due to DOSBox not being installed."
			return
		}
		[[ ! -d "${dosboxdir}/gog" ]] || mkdir -p "${dosboxdir}/gog"
		mv -f "${tmpdir}/${gameName}" "${dosboxdir}/${gameName}"
		ln -sf "${scriptdir}/dosbox-launcher.sh" "${romdir}/pc/${gameName}.sh" || _error "Failed to create launcher."
		_msgbox "GOG.com game ID: ${gameID}\n$(basename "${fileSelected}") was extracted and installed to ${dosboxdir}" --title "${gameName} was installed."
		;;

	"scummvm")
		shortName=$(find "${tmpdir}/${gameName}" -name '*.ini' -exec grep -Pom 1 'gameid=\K.*' {} \; -quit)
		shortName=${shortName%$'\r'}

		[[ "${extension,,}" == "sh" ]] && subdir="/data"
		mv -f "${tmpdir}/${gameName}${subdir}" "${scummvmdir}/${gameName}.svm" || {
			_error "Uname to copy game to ${scummvmdir}\n\nThis is likely due to ScummVM not being installed."
			return
		}
		echo "${shortName}" >"${scummvmdir}/${gameName}.svm/${shortName}.svm"
		_msgbox "GOG.com game ID: ${gameID}\n$(basename "${fileSelected}") was extracted and installed to ${scummvmdir}\n\nTo finish the installation and open ScummVM and add game, or install lr-scummvm." --title "${gameName} was installed."
		;;

	"neogeo")
		if [[ ! -d "${romdir}/neogeo/" ]] && _yesno "${romdir}/neogeo/ Does not exist.\n\nDo you want to install lr-fbalpha"; then
			sudo RetroPie-Setup/retropie_packages.sh lr-fbalpha

		fi

		if [[ -f "${romdir}/neogeo/neogeo.zip" ]] && _yesno "neogeo.zip already existsts in ${romdir}/neogeo/\n\nDo you want to overwrite?"; then
			cp -f "${tmpdir}/${gameName}/game/neogeo.zip" "${romdir}/neogeo/"

		else
			cp "${tmpdir}/${gameName}/game/neogeo.zip" "${romdir}/neogeo/"
		fi

		if [[ "$(find "${tmpdir}/${gameName}" -name '*.zip' ! -name 'neogeo.zip' | wc -l)" == "1" ]]; then
			cp "$(find "${tmpdir}/${gameName}" -name '*.zip' ! -name 'neogeo.zip')" "${romdir}/neogeo/"
			_msgbox "GOG.com game ID: ${gameID}\n$(basename "${fileSelected}") was extracted and installed to ${dosboxdir}" --title "${gameName} was installed."

		else
			_error "Game not supported yet."
			return
		fi
		;;

	"unsupported")
		_error "${fileSelected} apperantly is unsupported."
		return
		;;
	esac

}

# Extracts a setup file
# Usage: _extract "${fileName}" "${gameName}"
# extracts "${filename}" and moves game to "${tmpdir}/${gameName}"
_extract() {
	local fileSelected extension gameName
	fileSelected="${1}"
	gameName="${2}"
	extension="${fileSelected##*.}"

	case "${extension,,}" in
	"exe")
		#There is a bug in innoextract that missinterprets the filestructure. using dirname & find as a workaround
		local folder
		rm -rf "${tmpdir:?}/output"
		rm -rf "${tmpdir:?}/${gameName}"
		mkdir -p "${tmpdir}/output" || {
			_error "Could not initialize temp folder for extraction"
			return
		}
		"${innobin}" --gog "${fileSelected}" --output-dir "${tmpdir}/output" &>"$(tty)"
		folder="$(dirname "$(find "${tmpdir}/output" -name 'goggame-*.info')")"
		if [[ "${folder}" == "." ]]; then
			# Didn't find goggame-*.info, now we must rely on exception to catch this install.
			folder="${tmpdir}/output/app"
		fi
		if [[ -n "$(ls -A "${folder}/__support/app")" ]]; then
			cp -r "${folder}"/__support/app/* "${folder}/"
		fi
		mv "${folder}" "${tmpdir}/${gameName}"
		;;

	"sh")
		rm -rf "${tmpdir:?}/output"
		rm -rf "${tmpdir:?}/${gameName}"
		mkdir -p "${tmpdir}/output" || {
			_error "Could not initialize temp folder for extraction"
			return
		}
		unzip "${fileSelected}" -d "${tmpdir}/output" &>"$(tty)"
		folder="${tmpdir}/output/data/noarch"
		mv "${folder}" "${tmpdir}/${gameName}"
		;;

	*)
		_error "File extension not supported."
		;;
	esac

}

# Detect the game type
# Usage: _getType "${gameName}"
# returns dosbox, scummvm or neogeo
_getType() {

	local gamePath type
	gamePath="$(jq --raw-output '.playTasks[] | select(.isPrimary==true) | .path' <"${tmpdir}/${1}/"goggame-*.info)"

	if [[ "${gamePath}" == *"DOSBOX"* ]] || [[ -d "${tmpdir}/${1}/DOSBOX" ]] || [[ -d "${tmpdir}/${1}/dosbox" ]]; then
		type="dosbox"

	elif [[ "${gamePath}" == *"scummvm"* ]] || [[ -d "${tmpdir}/${1}/scummvm" ]]; then
		type="scummvm"

	elif [[ "$(find "${tmpdir}/${1}" -name "neogeo.zip")" ]]; then
		type="neogeo"

	else
		_error "Didn't find what game it was.\nNot installing."
		return
	fi

	echo "${type:-unsupported}"
}

# dialog --fselect broken out to a function,
# the purpouse is that
# if the screen is smaller then what --fselec can handle
# I can do somethig else
# Usage: _fselect "${fullPath}"
# returns the file that is selected including the full path, if full path is used.
_fselect() {
	local termh windowh dirList selected extension fileName fullPath gameName newDir
	fullPath="${1}"
	termh="$(tput lines)"
	((windowh = "${termh}" - 10))
	[[ "${windowh}" -gt "22" ]] && windowh="22"
	if "${fullFileBrowser}" && [[ "${windowh}" -ge "8" ]]; then
		dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--fselect "${fullPath}/" \
			"${windowh}" 77 3>&1 1>&2 2>&3 >"$(tty)"

	else
		# in case of a very tiny terminal window
		# make an array of the filenames and put them into --menu instead
		dirList=(
			"goto" "Go to directory (keyboard required)"
			".." "Up one directory"
		)

		while read -r folderName; do
			dirList+=("$(basename "${folderName}")" "Directory")

		done < <(find "${fullPath}" -mindepth 1 -maxdepth 1 ! -name '.*' -type d)

		while read -r fileName; do
			extension="${fileName##*.}"
			case "${extension,,}" in
			"exe")
				dirList+=("$(basename "${fileName}")")

				gameName="$("${innobin}" --gog-game-id "${fileName}")"
				gameName="$(awk -F'"' 'NR==1{print $2}' <<<"${gameName}")"
				dirList+=("${gameName}")
				;;

			"sh")
				dirList+=("$(basename "${fileName}")")

				gameName="$(grep -Poam 1 'label="\K.*' "${fileName}")"
				dirList+=("${gameName% (GOG.com)\"}")
				;;
			esac

		done < <(find "${fullPath}" -maxdepth 1 -type f)

		selected="$(dialog \
			--backtitle "${title}" \
			--title "${fullPath}" \
			--menu "Pick a file to install" \
			22 77 16 "${dirList[@]}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)")"

		[[ "${?}" -ge 1 ]] && return

		case "${selected}" in
		"goto")
			newDir="$(_inputbox "Input a directory to go to" "${HOME}/Downloads")"
			_fselect "${newDir}"
			;;
		"..")
			_fselect "${fullPath%/*}"
			;;
		*.sh | *.exe)
			echo "${fullPath}/${selected}"
			;;
		*)
			_fselect "${fullPath}/${selected}"
			;;
		esac

	fi

}

# Ask user for a string
# Usage: _inputbox "My message" "Initial text" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_inputbox() {
	local msg opts init
	msg="${1}"
	init="${2}"
	shift 2
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--inputbox "${msg}" \
		22 77 "${init}" 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Display a message
# Usage: _msgbox "My message" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
_msgbox() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
}

# Request user input
# Usage: _yesno "My question" [--optional-arguments]
# You can pass additioal arguments to the dialog program
# Backtitle is already set
# returns the exit code from dialog which depends on the user answer
_yesno() {
	local msg opts
	msg="${1}"
	shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		"${opts[@]}" \
		--yesno "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	return "${?}"
}

# Display an error
# Usage: _error "My error" [1] [--optional-arguments]
# If the second argument is a number, the program will exit with that number as an exit code.
# You can pass additioal arguments to the dialog program
# Backtitle and title are already set
# Returns the exit code of the dialog program
_error() {
	local msg opts answer exitcode
	msg="${1}"
	shift
	[[ "${1}" =~ ^[0-9]+$ ]] && exitcode="${1}" && shift
	opts=("${@}")
	dialog \
		--backtitle "${title}" \
		--title "ERROR:" \
		"${opts[@]}" \
		--msgbox "${msg}" \
		22 77 3>&1 1>&2 2>&3 >"$(tty)" <"$(tty)"
	answer="${?}"
	[[ -n "${exitcode}" ]] && _exit "${exitcode}"
	return "${answer}"
}

# Checks if retropie helper script exists
# sources it
# and enable joy2key for gamepad input
# Usage: _joy2key
_joy2key() {
	if [[ -f "${retropiehelper}" ]]; then
		local scriptdir="/home/pi/RetroPie-Setup"
		# shellcheck source=/dev/null
		source "${retropiehelper}"
		joy2keyStart
	fi
}

# Exits the program
# it also clears
# it also does turns off joy2key if the retropie helper script exists
_exit() {
	clear
	if [[ -f "${retropiehelper}" ]]; then
		joy2keyStop
	fi
	exit "${1:-0}"
}

_joy2key
_depends
_checklogin

while true; do
	main
	"_${selected:-exit}"
done

_exit

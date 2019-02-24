#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="piegalaxy"
rp_module_desc="Pie Galaxy - Downloand and install GOG.com games in RetroPie"
rp_module_licence="GPL https://github.com/sigboe/pie-galaxy/blob/master/LICENSE"
rp_module_section="exp"

function depends_piegalaxy() {
	getDepends jq html2text unar
}

function install_bin_piegalaxy() {
	local innoversion="1.8-dev-2019-01-13"
	gitPullOrClone "$md_inst" https://github.com/sigboe/pie-galaxy.git master

	if isPlatform "x86"; then
		downloadAndExtract "http://constexpr.org/innoextract/files/snapshots/innoextract-${innoversion}/innoextract-${innoversion}-linux.tar.xz" "$md_inst/innotemp" 2
		mv "$md_inst/innotemp/amd64/innoextract" "$md_inst/"
		rm -rf "$md_inst/innotemp"
		(
			cd "$md_inst" || exit 1
			curl -o wyvern -O https://demenses.net/wyvern-nightly
		)
	fi
	if isPlatform "arm"; then
		downloadAndExtract "http://constexpr.org/innoextract/files/snapshots/innoextract-${innoversion}/innoextract-${innoversion}-linux.tar.xz" "$md_inst/innotemp" 2
		mv "$md_inst/innotemp/armv6j-hardfloat/innoextract" "$md_inst/"
		rm -rf "$md_inst/innotemp"
		(
			cd "$md_inst" || exit 1
			curl -o wyvern -O https://demenses.net/wyvern-1.3.0-armv7
		)
	fi
	chmod +x "$md_inst"/wyvern "$md_inst"/innoextract "$md_inst"/pie-galaxy.sh
}

function configure_piegalaxy() {
	addPort "$md_id" "piegalaxy" "Pie Galaxy" "$md_inst/pie-galaxy.sh"
}

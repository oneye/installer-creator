#!/bin/bash
#
# Copyright © since 2013 Lars Knickrehm, mail@lars-sh.de
#

#
# HELP
#

##
# HELP
#
# Prints the help to stdout
function creator_help() {
	cat << EOF
creator.sh (-h|--help)
  Print this help and exit

creator.sh ONEYE_PATH INSTALLER_PATH
  where ONEYE_PATH is a path to the oneye system folder
  where INSTALLER_PATH is a path to the oneye installer folder
EOF
}

#
# ERRORS
#

##
# ERROR
#
# Prints the passed error and the help to stderr and exits
function creator_error() {
	echo "$1" 1>&2
	echo 1>&2
	creator_help 1>&2
	exit 1
}

##
# ERROR: FAILING COMMAND
#
# Prints the error "command not found"
#
# @param1 Command, which has not been found.
function creator_error_command() {
	creator_error "Command not found: $1"
}

##
# ERROR: INVALID PARAMETER
#
# Prints the error "invalid parameter"
function creator_error_parameter() {
	creator_error 'Invalid parameter passed.'
}

#
# TOOLS
#

##
# BASE64
#
# Creates a base64 encoded stream out of a given file.
#
# @param1 File to be encoded.
function creator_base64 {
	if [[ $(command -v base64) ]]; then
		base64 --wrap=0 "$1"
	elif [[ $(command -v openssl) ]]; then
		openssl base64 "$1" | tr '\r\n' ' ' | sed 's/\s+//g'
	else
		creator_error_command 'base64'
	fi
}

##
# MD5
#
# Creates the 32 byte long md5 hash out of a given file.
#
# @param1 File to be hashed.
function creator_md5 {
	local md5=''
	
	if [[ $(command -v md5) ]]; then
		md5=$(md5 -q "$1")
	elif [[ $(command -v md5sum) ]]; then
		md5=$(md5sum "$1")
	else
		creator_error_command 'md5'
	fi
	
	echo -n ${md5:0:32}
}

##
# REALPATH
#
# Canonicalizes a given path.
#
# @param1 Path to be canonicalized.
function creator_realpath() {
	cd "$1"
	path=$(pwd)
	cd - > /dev/null
	echo "$path"
}

#
# ACTIONS
#
# @param1 ONEYE_PATH
# @param2 INSTALLER_PATH

##
# ACTION 1
#
# Clean up temporary directory
function creator_action_1() {
	echo "Clean up temporary directories"
	rm -f -r "$1/system/tmp/*"
	touch "$1/system/tmp/.htaccess"
}

##
# ACTION 2
#
# Copy index.php and settings.php
function creator_action_2() {
	echo "Copy index.php and settings.php"
	cp "$1/index.php" "$2/installer/files/index.txt"
	cp "$1/settings.php" "$2/installer/files/settings.txt"
}

##
# ACTION 3: BASE64
#
# Creates a list of all files in a folder and their base64 encoded content.
#
# @param1: Path to be scanned.
# @param2: Path used for substitution.
function creator_action_3_base64() {
	local path=''
	
	for file in $1/*; do
		if [[ -d "$file" ]]; then
			creator_action_3_base64 "$file" "$2"
		else
			path="${file:${#2}}"
			
			echo -n -e "\t\t<$path>" | sed 's/&/&amp;/g'
			creator_base64 "$file"
			echo "</$path>" | sed 's/&/&amp;/g'
		fi
	done
}

##
# ACTION 3: INIT
#
# Initializes the third action
function creator_action_3_init() {
	echo '<modules>'
		echo -e '\t<browser>'
			creator_action_3_base64 "$1/browser" "$1/browser/"
		echo -e '\t</browser>'
		echo -e '\t<iphone>'
			creator_action_3_base64 "$1/iphone" "$1/iphone/"
		echo -e '\t</iphone>'
		echo -e '\t<mobile>'
			creator_action_3_base64 "$1/mobile" "$1/mobile/"
		echo -e '\t</mobile>'
	echo -e '</modules>'
}

##
# ACTION 3
#
# Generate modules.xml
function creator_action_3() {
	local modules_path="$installer_path/installer/files/modules.xml"
	
	echo "Generate modules.xml"
	creator_action_3_init "$@" > "$modules_path"
}

##
# ACTION 4
#
# Create package.eyepackage
function creator_action_4() {
	echo "Create package.eyepackage"
	cd "$1"
	tar --create --file="$2/package.eyepackage" --gzip --exclude '.git*' "./system"
	cd - > /dev/null
}

##
# ACTION 5
#
# Update installer/index.php
function creator_action_5() {
	local md5=$(creator_md5 "$2/package.eyepackage")
	if [[ $? -ne 0 ]]; then
		creator_error_command 'md5'
	fi
	local md5_from="define('INSTALL_MD5',\s*'.\{0,32\}');"
	local md5_to="define('INSTALL_MD5', '$md5');"
	
	local version=$(date +%Y%m%d%H%M%S)
	local version_from="define('INSTALL_VERSION',\s*'\([0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+\(\|-[0-9]\+\)\)\(\|preview[0-9]\+\)');"
	local version_to="define('INSTALL_VERSION', '\1preview$version');"
	
	echo "Update installer/index.php"
	cat "$2/installer/index.php" | sed "s/$md5_from/$md5_to/" | sed "s/$version_from/$version_to/" > "$2/installer/index.tmp"
	mv "$2/installer/index.tmp" "$2/installer/index.php"
}

#
# MAIN
#

##
# MAIN
#
# Main function, handling working directory and calling actions.
function creator_main() {
	local i=0
	local j=5
	
	oneye_path=$(creator_realpath "$1")
	installer_path=$(creator_realpath "$2")
	
	cd $(dirname "$0")
	
	while [[ $i -lt $j ]]; do
		i=$(($i + 1))
		
		if [[ $i -gt 1 ]]; then
			echo
		fi
		echo -n "$i/$j "
		"creator_action_$i" "$oneye_path" "$installer_path"
	done
	
	cd - > /dev/null
}

#
# PARAMETERS
#

# Help
if [[ $# -eq 0 ]] || ([[ $# -eq 1 ]] && ([[ "$1" == '-h' ]] || [[ "$1" == '--help' ]])); then
	creator_help
	exit 0
fi

# Main
if [[ $# -eq 2 ]]; then
	creator_main "$@"
	exit 0
fi

# Invalid parameter
creator_error_parameter

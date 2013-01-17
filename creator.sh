#!/bin/bash
cd=$(realpath .)
cd $(dirname "$0")

oneye_path=$(realpath '../../www/oneye')
installer_path=$(realpath '../../www/installer')

browser_dir='browser'
iphone_dir='iphone'
mobile_dir='mobile'
oneyexxxxxxxxxx_dir='eyeOS'

files_path="$installer_path/installer/files"
modules_path="$files_path/modules.xml"

function creator_modules_xml() {
	local filexml
	
	for file in $1/*; do
		if [[ -d "$file" ]]; then
			creator_modules_xml "$file" "$2"
		else
			filexml="${file:${#2}}"
			
			echo -n "<$filexml>" | sed 's/&/&amp;/g' >> "$modules_path"
			cat "$file" | base64 --wrap=0 >> "$modules_path"
			echo -n "</$filexml>" | sed 's/&/&amp;/g' >> "$modules_path"
		fi
	done
}

function creator_main () {
	local i=1
	local j=6
	
	local md5
	local datetime
	
	# Clean up temporary directory
	echo "$i/$j Clean up temporary directory"
	echo
	rm --force --recursive "$oneye_path/$oneyexxxxxxxxxx_dir/tmp/*"
	touch "$oneye_path/$oneyexxxxxxxxxx_dir/tmp/.htaccess"
	i=$(( $i + 1 ))
	
	# Copy index.php and settings.php
	echo "$i/$j Copy index.php and settings.php"
	echo
	cp "$oneye_path/index.php" "$files_path/index.txt"
	cp "$oneye_path/settings.php" "$files_path/settings.txt"
	i=$(( $i + 1 ))
	
	# Generate modules.xml
	echo "$i/$j Generate modules.xml"
	echo
	echo -n '<modules><browser>' > "$modules_path"
	creator_modules_xml "$oneye_path/$browser_dir" "$oneye_path/$browser_dir/"
	echo -n '</browser><iphone>' >> "$modules_path"
	creator_modules_xml "$oneye_path/$iphone_dir" "$oneye_path/$iphone_dir/"
	echo -n '</iphone><mobile>' >> "$modules_path"
	creator_modules_xml "$oneye_path/$mobile_dir" "$oneye_path/$mobile_dir/"
	echo -n '</mobile></modules>' >> "$modules_path"
	i=$(( $i + 1 ))
	
	# Create package.eyepackage
	echo "$i/$j Create package.eyepackage"
	echo
	cd "$oneye_path"
	tar --create --file="$installer_path/package.eyepackage" --gzip --exclude-vcs "$oneyexxxxxxxxxx_dir"
	i=$(( $i + 1 ))
	
	# Update installer/index.php
	echo "$i/$j Update installer/index.php"
	echo
	md5=$(md5sum "$installer_path/package.eyepackage")
	md5=${md5:0:32}
	datetime=$(date +%Y%m%d%H%M%S)
	cat "$installer_path/installer/index.php" | sed "s/define('INSTALL_MD5','.\{32\}');/define('INSTALL_MD5','$md5');/" | sed "s/define('INSTALL_VERSION','\([0-9]\+.[0-9]\+.[0-9]\+.[0-9]\+\(\|-[0-9]\+\)\)\(\|preview[0-9]\+\)');/define('INSTALL_VERSION','\1preview$datetime');/" > "$installer_path/installer/index.php"
	i=$(( $i + 1 ))
	
	# Ready.
	echo "$i/$j Remember to update \"update.xml\" manually!"
}

creator_main
cd "$cd"
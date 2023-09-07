#!/bin/sh

# This script is responsible for installed new-project in the system. Multiple types of
# installation are available.
#
# ./install.sh local  - user-local installation
# ./install.sh system - system-wide installation
# ./install.sh dev    - developer installation
#
# The software can be uninstalled with ./install.sh uninstall [local | system | dev].
# The install directories for these modes can be modified below:

LOCAL_DATA_DIR="$HOME/.local/share/new-project"
LOCAL_BIN_DIR="$HOME/.local/bin"

SYS_DATA_DIR="/usr/share/new-project"
SYS_BIN_DIR="/usr/bin"

DEV_DATA_DIR="$PWD"
DEV_BIN_DIR="$PWD"

# Copyright 2023 Humberto Gomes
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

TMP_DIR="/tmp/new-project"

# Makes sure the script has access to all dependencies it needs to work.
assert_dependencies() {
	if ! command -v jq > /dev/null; then
		echo "jq need to be installed and in \$PATH. Leaving ..." >&2
		exit 1
	fi

	if ! command -v curl > /dev/null; then
		echo "curl need to be installed and in \$PATH. Leaving ..." >&2
		exit 1
	fi
}

# Parse command-line arguments and determine the action that should be performed.
parse_arguments() {
	# Print installed command-line usage.
	usage() {
		echo "Unknown command line arguments! Usage:" >&2
		echo >&2
		echo "./install.sh local  - user-local installation" >&2
		echo "./install.sh system - system-wide installation" >&2
		echo "./install.sh dev    - developer installation" >&2
		echo >&2
		echo "./install.sh uninstall [local | system | dev] - uninstallation" >&2
	}

	# Sets the $DATA_DIR and $BIN_DIR
	# $1 - type of installation
	set_directories() {
		if [ "$1" = "local" ]; then
			DATA_DIR="$LOCAL_DATA_DIR"
			BIN_DIR="$LOCAL_BIN_DIR"
		elif [ "$1" = "system" ]; then

			# Assert root
			if [ "$(id -u)" != "0" ]; then
				echo "Root permissions are needed for a system (un)installation." \
					"Leaving ..." >&2
				exit 1
			fi

			DATA_DIR="$SYS_DATA_DIR"
			BIN_DIR="$SYS_BIN_DIR"
		elif [ "$1" = "dev" ]; then
			DATA_DIR="$DEV_DATA_DIR"
			BIN_DIR="$DEV_BIN_DIR"
		elif [ "$1" = "uninstall" ]; then
			usage # Use a less cryptic error message
			exit 1
		else
			echo "Unknown (un)installation type \"$1\". Leaving ..." >&2
			exit 1
		fi
	}

	if [ "$#" -eq 1 ]; then
		action="install"
		set_directories "$1"
	elif [ "$#" -eq 2 ] && [ "$1" = "uninstall" ]; then
		action="uninstall"
		set_directories "$2"
	else
		usage
		exit 1
	fi
}

# Uninstalls new-project.
uninstall() {
	if [ "$(realpath "$DATA_DIR")" = "$PWD" ]; then
		# Don't delete templates (dev build)
		if ! rm -r "$DATA_DIR/licenses"; then
			echo "Failed to delete licenses directory. Leaving ..." >&2
			exit 1
		fi
	else
		# Delete all data
		if ! rm -r "$DATA_DIR"; then
			echo "Failed to delete new-project's data directory. Leaving ..." >&2
			exit 1
		fi
	fi

	if [ "$(realpath "$BIN_DIR")" != "$PWD" ]; then
		if ! rm "$BIN_DIR/new-project"; then
			echo "Failed to delete new-project's script. Leaving ..." >&2
			exit 1
		fi
	fi
}

# Creates a directory, but exits the script if the directory already exists and isn't empty.
mkdir_not_empty() {
	if [ -d "$1" ] && [ -n "$(ls -A "$1")" ]; then
		echo "\"$1\" already exists and isn't empty." >&2
		exit 1
	elif ! mkdir -p "$1"; then
		echo "mkdir -p $1 failed. Leaving ..." >&2
		exit 1
	fi
}

# Performs a GitHub API request, leaving the program on failure.
# $1 - Request URL is "https://api.github.com/$1"
# $2 - Path to the output file
github_request() {
	if ! curl -s -m 10 --retry-delay 5 --retry 5 -o "$2" "https://api.github.com/$1"; then
		echo "curl failed while (https://api.github.com/$1). Leaving ..." >&2
		exit 1
	fi

	if grep -q "rate limit" "$2"; then
		echo "GitHub API rate limit exceeded. Leaving ..." >&2
		exit 1
	fi
}

# Downloads licenses from the GitHub API.
download_license_data() {
	# Licenses that this program knowns and was tested with.
	known_licenses=" agpl-3.0 apache-2.0 bsd-2-clause bsd-3-clause bsl-1.0 cc0-1.0 epl-2.0 gpl-2.0 gpl-3.0 lgpl-2.1 mit mpl-2.0 unlicense "

	echo "Downloading licenses from GitHub API ..."
	echo "  - downloading license list"
	mkdir_not_empty "$TMP_DIR/licenses"
	github_request "licenses" "$TMP_DIR/licenses.json"

	for key in $(jq -r ".[].key" "$TMP_DIR/licenses.json"); do
		echo "  - downloading $key"
		github_request "licenses/$key" "$TMP_DIR/licenses/$key"

		if ! echo "$known_licenses" | grep -q " $key "; then
			echo "Unrecognized license \"$(jq -r ".name" "$TMP_DIR/licenses/$key")\"." \
			     "Please warn the developer to update the program!"
		fi
	done
}

# Creates all the needed subdirectories in $DATA_DIR, along with a README warning, telling that
# the files in $DATA_DIR/licenses are autogenerated.
create_output_directory_structure() {
	mkdir_not_empty "$DATA_DIR/licenses/names"
	mkdir_not_empty "$DATA_DIR/licenses/headers"
	mkdir_not_empty "$DATA_DIR/licenses/bodies"

	{
		echo "# Licenses" ;
		echo "" ;
		echo "These license files were autogenerated by [licenses.sh](../licenses.sh), by" ;
		printf "getting data from the " ;
		echo "[GitHub API](https://docs.github.com/en/rest/licenses/licenses)." ;
	} > "$DATA_DIR/licenses/README.md"
}

# Generates the human-readable names of licenses in $DATA_DIR/licenses/names, from previously
# downloaded license information.
generate_license_names() {
	echo "Generating license names ..."
	for license in "$TMP_DIR/licenses"/*; do
		jq -r ".name" "$license" > "$DATA_DIR/licenses/names/$(basename "$license")"
	done
}

# Generates the licenses bodies in $DATA_DIR/licenses/bodies, from previously downloaded license
# information.
generate_license_bodies() {
	echo "Generating license bodies ..."
	for license in "$TMP_DIR/licenses"/*; do
		jq -r ".body[:-1]" "$license" > "$DATA_DIR/licenses/bodies/$(basename "$license")"
	done
}

# Generates license headers for files.
generate_license_headers() {

	# Generates a header from a range of lines in a license.
	# $1 - name of the license file (no directory)
	# $2 - start line (inclusive)
	# $3 - end line (inclusive)
	# $4 - command to run before saving (indentation removal, text replacement, ...). Leave empty
	#      for removal of all indentation.
	header_from_lines() {
		if ! [ -f "$TMP_DIR/licenses/$1" ]; then
			echo "License \"$1\" has been removed from the GitHub API. Please warn the" \
			     "developer to update the program!"
			return 1
		fi

		if [ -z "$4" ]; then
			final_command="sed -r 's/^\\s+//'"
		else
			final_command="$4"
		fi

		jq -r ".body" "$TMP_DIR/licenses/$1" | \
			tail -n "+$2" | head -n "$(($3 - $2 + 1))" | eval "$final_command" \
			> "$DATA_DIR/licenses/headers/$1"
	}

	# Command used to format (A/L)GPL licenses
	gpl_command() {
		sed -re 's/^\s+//; s/<year>/[year]/g; s/<name of author>/[fullname]/g ; 1s/.*/[description]/g'
	}

	# Command used to format the Apache license
	apache_command() {
		sed -re 's/^   //g; s/\[yyyy\]/[year]/g; s/\[name of copyright owner\]/[fullname]/g'
	}

	echo "Generating license headers for source files ..."

	header_from_lines "agpl-3.0" 632 646 gpl_command
	header_from_lines "apache-2.0" 189 201 apache_command

	{
		echo "          Copyright [fullname] [year]." ;
		echo "Distributed under the Boost Software License, Version 1.0." ;
		echo "   (See accompanying file LICENSE_1_0.txt or copy at" ;
		echo "         https://www.boost.org/LICENSE_1_0.txt)" ;
	} > "$DATA_DIR/licenses/headers/bsl-1.0"

	header_from_lines "gpl-2.0" 293 308 gpl_command
	header_from_lines "gpl-3.0" 634 648 gpl_command
	header_from_lines "lgpl-2.1" 473 489 gpl_command
	header_from_lines "mpl-2.0" 358 360

	# Warning for missing headers
	echo "You can add a custom license file header to licenses that don't contain one. Check" \
	     "\"$DATA_DIR/licenses/headers\". Here are those licenses:"
	echo ""

	for license in "$DATA_DIR/licenses/names"/*; do
		if ! [ -f "$DATA_DIR/licenses/headers/$(basename "$license")" ]; then
			cat "$license"
		fi
	done
}

# Installs project templates to $DATA_DIR.
install_templates() {
	if [ "$(realpath "$DATA_DIR")" != "$PWD" ]; then # Not dev install
		if ! cp -r "./templates" "$DATA_DIR/templates"; then
			echo "Failed to install templates' directory. Leaving ..." >&2
			exit 1
		fi
	fi
}

# Installs the new-project shell script.
install_binaries() {
	if [ "$(realpath "$DATA_DIR")" != "$PWD" ]; then # Not dev install
		sed "s:DATA_DIR=\"\$PWD\":DATA_DIR=\"$DATA_DIR\":g" new-project > \
			"$BIN_DIR/new-project"
		chmod +x "$BIN_DIR/new-project"
	fi
}

parse_arguments "$@"

if [ "$action" = "install" ]; then
	assert_dependencies
	create_output_directory_structure
	download_license_data

	generate_license_names
	generate_license_bodies
	generate_license_headers

	install_templates
	install_binaries
	echo "Done! :-)"
else
	uninstall
fi

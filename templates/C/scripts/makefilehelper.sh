#!/bin/sh

# This script is needed for make to work. It regenerates dependency files
# (make rules) when a file is recompiled. This script will also delete the
# temporary rule created by the compiler.
#
# Arguments:
# $1 - path to the rule to be regenerated. It's assumes that compiler has
#      already generated the 2nd version of that rule (e.g.: main.d2).

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"

if [ "$#" -ne 1 ]; then
	echo "This script isn't meant to be used by regular users!" >&2
	exit 1
fi

# A rule includes 3 commands:
#   - Creating the parent directory of the file
#   - Running the compiler
#   - Calling this script
COMMANDS_PER_RULE=3

{
	# Add the dependency file (makefile rule) to the target of the new rule
	printf "$1 " | cat - "${1}2"

	# Keep the commands from the original rule
	tail "-n-$COMMANDS_PER_RULE" "$1"
} > "${1}3"

cp "${1}3" "$1"
rm "${1}2" "${1}3"

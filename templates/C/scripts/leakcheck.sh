#!/bin/sh

# This script runs the built executable, checking for memory leaks using
# valgrind.

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"

assert_installed_command valgrind

MAKEFILE_BUILDDIR="$(get_makefile_const BUILDDIR)"
MAKEFILE_EXENAME="$(get_makefile_const EXENAME)"
EXE_PATH="$MAKEFILE_BUILDDIR/$MAKEFILE_EXENAME"

if ! [ -f "$EXE_PATH" ] || ! [ -f "${EXE_PATH}_type" ]; then
	echo "Executable not built! Build it and try again. Leaving ..." >&2
	exit 1
elif [ "$(cat "${EXE_PATH}_type")" != "DEBUG" ]; then
	printf "Executable not built in DEBUG mode %s" "($(cat "${EXE_PATH}_type") "
	printf "used instead). Valgrind won't be able to know which lines of code"
	printf "cause a leak.\n"

	if ! yesno "Proceed? [Y/n]: "; then
		echo "User cancelled action. Leaving ..."
		exit 1
	fi
fi

LOG_FILE="$(mktemp)"
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --leak-resolution=high \
         --log-file="$LOG_FILE" \
         "$EXE_PATH" "$@"

less "$LOG_FILE"
rm "$LOG_FILE"

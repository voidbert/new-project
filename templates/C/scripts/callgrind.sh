#!/bin/bash
# |
# \_ bash is needed for process substitution, for fully correct filtering of
#    callgrind's stderr (POSIX shell solutions assume fd 3 isn't in use).

# This script runs and profiles the built executable.

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"

assert_installed_command valgrind
assert_installed_command kcachegrind

MAKEFILE_BUILDDIR="$(get_makefile_const BUILDDIR)"
MAKEFILE_EXENAME="$(get_makefile_const EXENAME)"
EXE_PATH="$MAKEFILE_BUILDDIR/$MAKEFILE_EXENAME"

if ! [ -f "$EXE_PATH" ] || ! [ -f "${EXE_PATH}_type" ]; then
	echo "Executable not built! Build it and try again. Leaving ..." >&2
	exit 1
elif [ "$(cat "${EXE_PATH}_type")" != "PROFILE" ]; then
	printf "Executable not built in PROFILE mode. Callgrind's results "
	printf "won't be the best possible.\n"

	if ! yesno "Proceed? [Y/n]: "; then
		echo "User cancelled action. Leaving ..."
		exit 1
	fi
fi

OUTPUT="$(mktemp)"
valgrind --tool=callgrind --collect-jumps=yes --callgrind-out-file="$OUTPUT" \
	"$EXE_PATH" "$@" 2> >(sed -zE \
		's/^(==[0-9]*==[^\n]*\n)*//g ; s/(==[0-9]*==[^\n]*\n)*$//g' >&2)
		# |
		# \_ remove ==[PID]== messages from callgrind

sh -c "kcachegrind \"$OUTPUT\" ; rm \"$OUTPUT\"" &> /dev/null &
disown

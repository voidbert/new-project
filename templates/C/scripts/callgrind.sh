#!/bin/bash
# |
# \_ bash is needed for process substitution, for fully correct filtering of
#    callgrind's stderr (POSIX shell solutions assume fd 3 isn't in use).

# This script runs and profiles the built executable.

# %LICENSE_HEADER%
if ! command -v valgrind > /dev/null; then
	printf "Valgrind not installed! Please install it and try again. " >&2
	echo   "Leaving ..." >&2
	exit 1
fi

if ! command -v kcachegrind > /dev/null; then
	printf "Kcachegrind not installed! Please install it and try again. " >&2
	echo   "Leaving ..." >&2
	exit 1
fi

REPO_DIR="$(realpath "$(dirname -- "$0")/..")"

if ! [ -f "$REPO_DIR/Makefile" ]; then
	echo "Makefile has been deleted! Leaving ..." >&2
	exit 1
fi

MAKEFILE_BUILDDIR="$(< "$REPO_DIR/Makefile" \
	grep '^BUILDDIR\s*:=' | sed 's/^BUILDDIR\s*:=\s*//g')"
MAKEFILE_EXENAME="$(< "$REPO_DIR/Makefile" \
	grep '^EXENAME\s*:=' | sed 's/^EXENAME\s*:=\s*//g')"
EXE_PATH="$REPO_DIR/$MAKEFILE_BUILDDIR/$MAKEFILE_EXENAME"

if ! [ -f "$EXE_PATH" ] || ! [ -f "${EXE_PATH}_type" ]; then
	echo "Executable not built! Build it and try again. Leaving ..." >&2
	exit 1
elif [ "$(cat "${EXE_PATH}_type")" != "PROFILE" ]; then
	printf "Executable not built in PROFILE mode. Callgrind's results "
	printf "won't be the best possible.\n"

	stdbuf -o 0 printf "Proceed? [Y/n]: "
	read -r RESULT
	echo # Spacing

	if echo "$RESULT" | grep -Eq '^[Nn][Oo]?$'; then
		echo "User cancelled action. Leaving ..."
		exit 1
	elif ! echo "$RESULT" | grep -Eq '^[Yy]([Ee][Ss])?$'; then
		echo "Invalid input. Leaving ..." >&2
		exit 1
	fi
fi

OUTPUT="$(mktemp)"
valgrind --tool=callgrind --collect-jumps=yes --callgrind-out-file="$OUTPUT" \
	"$EXE_PATH" "$@" 2> >(sed -zE \
		's/^(==[0-9]*==[^\n]*\n)*//g ; s/(==[0-9]*==[^\n]*\n)*$//g' >&2)
            # |
		# \_ remove ==[PID]== messages from callgrind

kcachegrind "$OUTPUT" &> /dev/null && rm "$OUTPUT" &> /dev/null &!

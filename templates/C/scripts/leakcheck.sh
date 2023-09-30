#!/bin/sh

# This script runs the built executable, checking for memory leaks using
# valgrind.

# %LICENSE_HEADER%
if ! command -v valgrind > /dev/null; then
	printf "Valgrind not installed! Please install it and try again. " >&2
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
elif [ "$(cat "${EXE_PATH}_type")" != "DEBUG" ]; then
	printf "Executable not built in DEBUG mode. Valgrind won't be "
	printf "able to know which lines of code cause a leak.\n"

	stdbuf -o 0 printf "Proceed? [Y/n]: "
	read -r RESULT

	if echo "$RESULT" | grep -Eq '^[Nn][Oo]?$'; then
		echo "User cancelled action. Leaving ..."
		exit 1
	elif ! echo "$RESULT" | grep -Eq '^[Yy]([Ee][Ss])?$'; then
		echo "Invalid input. Leaving ..." >&2
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

#!/bin/sh

# This script looks for the TODO string in the C codebase.

# %LICENSE_HEADER%
REPO_DIR="$(realpath "$(dirname -- "$0")/..")"
cd "$REPO_DIR"

if ! grep -r TODO src include; then
	echo "No TODO's left in the code!"
fi

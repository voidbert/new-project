#!/bin/sh

# This script looks for the TODO string in the C codebase.

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"

if ! grep -r TODO src include; then
	echo "No TODO's left in the code!"
fi

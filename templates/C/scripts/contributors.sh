#!/bin/sh

# This script counts lines (includes comments and empty lines) committed by
# each contributor.

# %LICENSE_HEADER%
if ! command -v git > /dev/null; then
	printf "git not installed! Please install it and try again. " >&2
	echo   "Leaving ..." >&2
	exit 1
fi

REPO_DIR="$(realpath "$(dirname -- "$0")/..")"
cd "$REPO_DIR"

find Makefile src include scripts %THEMES_DIR% -type f \
	-exec grep -I -q . {} \; -print | while read -r file; do

	# Only report files tracked by git
	if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
		git blame --line-porcelain "$file" \
			| grep '^author ' | sed 's/^author //g'
	fi
done | sort -f | uniq -ic

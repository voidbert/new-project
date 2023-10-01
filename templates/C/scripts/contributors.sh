#!/bin/sh

# This script counts lines (includes comments and empty lines) committed by
# each contributor.

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"
assert_installed_command git

find Makefile src include scripts %THEMES_DIR% -type f \
	-exec grep -I -q . {} \; -print | while read -r file; do

	# Only report files tracked by git
	if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
		git blame --line-porcelain "$file" \
			| grep '^author ' | sed 's/^author //g'
	fi
done | sort -f | uniq -ic

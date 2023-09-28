#!/bin/sh

# This script formats the source code, and asks the user if they wish to keep
# the changes.

# %LICENSE_HEADER%
if ! command -v clang-format > /dev/null; then
	printf "clang-format not installed! Please install it and try again. " >&2
	echo   "Leaving ..." >&2
	exit 1
fi

if ! command -v git > /dev/null; then # For diffs
	printf "git not installed! Please install it and try again. " >&2
	echo   "Leaving ..." >&2
	exit 1
fi

REPO_DIR="$(realpath "$(dirname -- "$0")/..")"
cd "$REPO_DIR"

out_dir="$(mktemp -d)"
diff_path="$(mktemp)"
mkdir "$out_dir/src" "$out_dir/include"

find src include -type f | while read -r file; do
	clang-format "$file" | sed '$a\' > "$out_dir/$file"
done

git --no-pager -c color.ui=always diff --no-index "src" "$out_dir/src" \
	> "$diff_path"
git --no-pager -c color.ui=always diff --no-index "include" "$out_dir/include" \
	>> "$diff_path"

if ! [ -s "$diff_path" ]; then
	echo "Already formatted! Leaving ..."
	rm -r "$diff_path" "$out_dir"
	exit 0
fi

less -R "$diff_path"

stdbuf -o 0 printf "Agree with these changes? [Y/n]: "
read -r RESULT

if echo "$RESULT" | grep -Eq '^[Nn][Oo]?$'; then
	echo "Source code left unformatted. Leaving ..."
	perform_changes=false
elif ! echo "$RESULT" | grep -Eq '^[Yy]([Ee][Ss])?$'; then
	echo "Invalid input. Leaving ..."
	perform_changes=false
else
	perform_changes=true
fi

if $perform_changes; then
	cp -r "$out_dir/src"     .
	cp -r "$out_dir/include" .
fi

# Clean up and exit with correct exit code
rm -r "$diff_path" "$out_dir"
$perform_changes
exit $?

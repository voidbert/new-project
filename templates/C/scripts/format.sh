#!/bin/sh

# This script formats the source code, and asks the user if they wish to keep
# the changes.

# %LICENSE_HEADER%
. "$(dirname "$0")/utils.sh"

assert_installed_command clang-format
assert_installed_command git

out_dir="$(mktemp -d)"
diff_path="$(mktemp)"
mkdir "$out_dir/src" "$out_dir/include"

find src include -type f | while read -r file; do
	mkdir -p "$(dirname "$out_dir/$file")"
	clang-format "$file" | sed "\$a\\" > "$out_dir/$file"
done

git --no-pager -c color.ui=always diff --no-index "src" "$out_dir/src" \
	> "$diff_path"
git --no-pager -c color.ui=always diff --no-index "include" "$out_dir/include" \
	>> "$diff_path"

if ! [ -s "$diff_path" ]; then
	echo "Already formatted! Leaving ..."
	rm -r "$diff_path" "$out_dir"
	exit 0
elif [ "$1" = "--check" ]; then
	echo "Formatting errors!"
	cat "$diff_path"
	rm -r "$diff_path" "$out_dir"
	exit 1
else
	less -R "$diff_path"
fi

if yesno "Agree with these changes? [Y/n]: " true; then
	perform_changes=true
else
	echo "Source code left unformatted. Leaving ..."
	perform_changes=false
fi

if $perform_changes; then
	cp -r "$out_dir/src"     .
	cp -r "$out_dir/include" .
fi

# Clean up and exit with correct exit code
rm -r "$diff_path" "$out_dir"
$perform_changes
exit $?

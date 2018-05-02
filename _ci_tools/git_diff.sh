#!/usr/bin/env sh

# Example Usage:
# git diff develop --name-only | xargs bash git_diff.sh | uniq

# Latch in all strings
diffs=$@

for diff in $diffs; do
    # Trims everything after the first '/' in the strings
    cleaned_diff=${diff%%/*}
    # Only print if this is a directory
    if [[ -d $cleaned_diff ]];
    then
        # The returned string needs to be a NodeJS folder; simply identified by a package.json
        if [[ -f $cleaned_diff/package.json ]]; then
            echo $cleaned_diff
        fi
    fi
done

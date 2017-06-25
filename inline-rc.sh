#!/bin/bash

# Quick bash script to inline .lua files into a DCSS rc.

# Base RC file. Script looks for a line with # LUA_INCLUDE, placing the
# inlined lua files after that line.
rc_file="gammafunk_base.rc"
# Dir with the lua files
lua_dir=~/Games/dcss/dcss-rc
# Final RC file
out_file=~/Games/dcss/dcss-rc/gammafunk.rc

read -d '' usage_string <<EOF
$(basename $0) [-b <file> ] [-d <dir>] [-o <file>] <file> [<file>...]
EOF

while getopts "h?b:d:o:" opt; do
    case "$opt" in
        h|\?)
            echo $usage_string
            exit 0
            ;;
        b)  rc_file="$OPTARG"
            ;;
        d)  lua_dir="$OPTARG"
            ;;
        o)  out_file="$OPTARG"
            ;;
    esac
done
shift $(($OPTIND - 1))

if [ -z "$1" ]; then
     echo $usage_string
     exit 0
fi

set -e
cd $lua_dir
lua_text=$'{\n'$(cat "$@")$'\n}'
myrc=$(cat $rc_file)
printf "%s\n" "${myrc/\# BEGIN LUA/$lua_text}" > "$out_file"
rc_nlines=$(cat $rc_file | wc -l)
lua_nlines=$(echo "$lua_text" | wc -l)
echo "Added $rc_nlines lines from $rc_file to $out_file"
echo "Added $lua_nlines lines to $out_file from files: $@"

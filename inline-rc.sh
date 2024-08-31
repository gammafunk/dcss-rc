#!/bin/bash

# Quick bash script to inline .lua files into a DCSS rc.

out_file=
marker='\# BEGIN LUA'

read -d '' usage_string <<EOF
$(basename $0) [-m MARKER] [-o OUT-FILE] RC-FILE LUA-FILE [LUA-FILE...]
Replace an instance of the MARKER string in RC-FILE with the contents of the
LUA-FILE arguments.
Default marker string: $marker
EOF

while getopts "h?m:o:" opt; do
    case "$opt" in
        h|\?)
            echo -e "$usage_string"
            exit 0
            ;;
        o)  out_file="$OPTARG"
            ;;
        m)  marker="$OPTARG"
            ;;
    esac
done
shift $(($OPTIND - 1))

if [ -z "$1" ]; then
    echo -e "$usage_string"
    exit 0
else
    rc_file="$1"
    shift
fi
if [ $# -eq 0 ]; then
    echo -e "$usage_string"
    exit 0
fi
if [ -z "$out_file" ]; then
    out_file="${rc_file}.new"
fi

set -e
lua_text=$'\n'$(cat "$@")$'\n'
myrc=$(cat $rc_file)
# Quotes needed around $lua_text to prevent expansion of & characters for
# bash 5.2 and later.
printf "%s\n" "${myrc/$marker/"$lua_text"}" > "$out_file"
rc_nlines=$(cat $rc_file | wc -l)
lua_nlines=$(echo "$lua_text" | wc -l)
echo "Added $rc_nlines lines from $rc_file to $out_file"
echo "Added $lua_nlines lines to $out_file from files: $@"

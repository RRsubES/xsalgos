#!/bin/bash

declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)

function usage {
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) < LIST_TO_COMPILE

e.g.: $(basename $0) < uir > list.compiled
EOF
	exit 1
}

function expand {
	#echo "$@" > "/dev/stderr"
	echo -n "$1 "
	shift
	for i; do
		#echo "\"$i\": " > /dev/stderr
		echo {A..Z}{A..Z} | grep -o "[^ ]*" | grep -E "$i"
	done | awk 'NR==1 { printf("%s", $1); next } NR>1 { printf(" %s", $1) } END { printf("\n") }'
}

CHAR="[A-Z]"
CHAR_REGEX="\[${CHAR}+\]"
CHARS_REGEX="(${CHAR_REGEX}${CHAR_REGEX}|${CHAR}${CHAR_REGEX}|${CHAR_REGEX}${CHAR})"

[[ -p 0 || -t 0 ]] && usage "No valid detected data to process"

while read LINE; do
	echo $LINE | grep -E "${CHARS_REGEX}" > /dev/null
	[ $? -eq 0 ] && expand $LINE || echo ${LINE}
done

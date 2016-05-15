#!/bin/bash

function expand {
	#echo "$@" > "/dev/stderr"
	echo -n "$1 "
	shift
	for i; do
		#echo "[$i]: " > /dev/stderr
		echo {A..Z}{A..Z} | awk '{ for(i=1; i <= NF; i++) print $i }' | grep -E "$i"
	done | awk '{ printf("%s", $1) } END { printf("\n") }'
}

CHAR="[A-Z]"
CHAR_REGEX="\[${CHAR}+\]"
CHARS_REGEX="(${CHAR_REGEX}${CHAR_REGEX}|${CHAR}${CHAR_REGEX}|${CHAR_REGEX}${CHAR})"

while read LINE; do
	echo $LINE | grep -E "${CHARS_REGEX}" > /dev/null
	[ $? -eq 0 ] && expand $LINE || echo ${LINE}
done

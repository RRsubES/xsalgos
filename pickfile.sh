#!/bin/bash

declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)

function usage {
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) DATE_YYYYMMDD TIME_HHMM

e.g.: $(basename $0) 20160504 1905
EOF
	exit 1
}
YEAR_REGEX="(20[0-9]{2})"
MONTH_REGEX="(0[1-9]|1[012])"
DAY_REGEX="([012][0-9]|3[01])"
DATE_REGEX="(${YEAR_REGEX}${MONTH_REGEX}${DAY_REGEX})"

HOUR_REGEX="([01][0-9]|2[0-3])"
MINUTE_REGEX="([0-5][0-9])"
TIME_REGEX="(${HOUR_REGEX}${MINUTE_REGEX})"

[[ $# -eq 0 ]] || [[ $1 == "--help" ]] && usage
[[ $1 =~ ^${DATE_REGEX}$ ]] && { DATE="$1"; shift; }
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }

YEAR=${DATE:0:4}
[[ ! ${YEAR} =~ ^${YEAR_REGEX}$ ]] && usage "${YEAR} is not detected as being a valid year pattern"

FIND_DIR="./_XSALGOS/"

files=()
for f in $(find "${FIND_DIR}" -mindepth 2 -type f | grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}\.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk "{ YEAR=MONTH=\"\"; n=split(\$0,a,\"/\"); for(i=1; i <= n; i++) { if (a[i] ~ /^${YEAR_REGEX}\$/) YEAR=a[i]; if (a[i] ~ /^${MONTH_REGEX}_?.+\$/) MONTH=substr(a[i],0,2); }  printf(\"%s%s%s %s\n\", YEAR, MONTH, substr(a[n],7,2), \$0); }" | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | cut -d ' ' -f2-); do
	files+=( "$f" )
	echo "${f#${FIND_DIR}}" > /dev/stderr
done

read -p "Proceeding with those files ? [Y] " choice
if [[ $choice =~ ^[nN] ]]; then
	exit 0
fi

#cat "${files[@]}" | sed -E "s/\x03//" > tmp.$$.txt 
cat "${files[@]}" | ./gen.scripts.sh ${DATE} ${TIME}


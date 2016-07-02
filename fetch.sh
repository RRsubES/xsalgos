#!/bin/bash

declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)

FIND_DIR="./_XSALGOS/"
OPTION_BEFORE=1

function usage {
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) [-b|--before n] DATE_YYYYMMDD 

-b n		: how many days are kept before the date
		(1 by default).

e.g.: $(basename $0) 20160504
e.g.: $(basename $0) -b 3 20160504
EOF
	exit 1
}

BEFORE_REGEX="([0-9]+)"
YEAR_REGEX="(20[0-9]{2})"
MONTH_REGEX="(0[1-9]|1[012])"
DAY_REGEX="([012][0-9]|3[01])"
DATE_REGEX="(${YEAR_REGEX}${MONTH_REGEX}${DAY_REGEX})"

while (($# > 0)); do
	case "$1" in
	-b|--before)
		OPTION_BEFORE=$2
		shift
		;;
	-h|--help)
		usage
		;;
	*)
		if [[ $1 =~ ^${DATE_REGEX}$ ]]; then
			DATE="$1"
		else
			usage "$1 is of type unknown"
		fi
		;;
	esac
	shift
done

YEAR=${DATE:0:4}
[[ ! ${YEAR} =~ ^${YEAR_REGEX}$ ]] && usage "${YEAR} is not detected as being a valid year pattern"
[[ ! ${OPTION_BEFORE} =~ ^${BEFORE_REGEX}$ ]] && usage "${OPTION_BEFORE} is not detected as valid, supposed to be a number"


files=() #no spaces/blanks allowed
for f in $(find "${FIND_DIR}" -mindepth 2 -type f | grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}\.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk "{ year=month=\"\"; n=split(\$0,a,\"/\"); for(i=1; i <= n; i++) { if (a[i] ~ /^${YEAR_REGEX}\$/) year=a[i]; if (a[i] ~ /^${MONTH_REGEX}_?.+\$/) month=substr(a[i],0,2); }  printf(\"%s%s%s %s\n\", year, month, substr(a[n],7,2), \$0); }" | sort | uniq -w 8 | grep -B ${OPTION_BEFORE} -E "^${DATE}" | cut -d ' ' -f2-); do
	files+=( "$f" )
	echo "${f#${FIND_DIR}}" > /dev/stderr
done

read -p "Proceeding with those files ? [Y] " choice > /dev/stderr
if [[ $choice =~ ^[nN] ]]; then
	exit 0
else
	for i in $(seq 1 ${#files[@]}); do
		echo "${files[$((i - 1))]}"
	done
fi

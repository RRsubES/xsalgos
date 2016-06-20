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
MONTH_REGEX="(0[0-9]|1[012])"
DAY_REGEX="([012][0-9]|3[01])"
DATE_REGEX="(${YEAR_REGEX}${MONTH_REGEX}${DAY_REGEX})"

HOUR_REGEX="([01][0-9]|2[0-3])"
MINUTE_REGEX="([0-5][0-9])"
TIME_REGEX="(${HOUR_REGEX}${MINUTE_REGEX})"

[[ $1 =~ ^${DATE_REGEX}$ ]] && { DATE="$1"; shift; }
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }

YEAR=${DATE:0:4}

#JAN_REGEX="((01)_?([Jj]an(vier)?))"
#FEB_REGEX="((02)_?([Ff][ée]v(rier)?))"
#MAR_REGEX="((03)_?([Mm]ars))"
#APR_REGEX="((04)_?([Aa]vril))"
#MAY_REGEX="((05)_?([Mm]ai))"
#JUN_REGEX="((06)_?([Jj]uin))"
#JUL_REGEX="((07)_?([Jj]uillet))"
#AUG_REGEX="((08)_?([Aa]out))"
#SEP_REGEX="((09)_?([Ss]ep(tembre)?))"
#OCT_REGEX="((10)_?([Oo]ct(obre)?))"
#NOV_REGEX="((11)_?([Nn]ov(embre)?))"
#DEC_REGEX="((12)_?([Dd][ée]c(embre)?))"
#
#NUMMONTH_REGEX="(${JAN_REGEX}|${FEB_REGEX}|${MAR_REGEX}|${APR_REGEX}|${MAY_REGEX}|${JUN_REGEX}|${JUL_REGEX}|${AUG_REGEX}|${SEP_REGEX}|${OCT_REGEX}|${NOV_REGEX}|${DEC_REGEX})"
#FIND_REGEX=".*/${YEAR_REGEX}/${NUMMONTH_REGEX}"

# may need to change it and expressions such as a[6], a[7]...
FIND_DIR="./_XSALGOS"

echo "date: ${DATE}" > /dev/stderr
files=()
for f in $(find "${FIND_DIR}" -mindepth 2 -type f | grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}\.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[3], substr(a[4],0,2), substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | sed -E "s/([0-9]{8} )(.*)/\2/"); do
	files+=( "$f" )
	echo "${f#${FIND_DIR}}" > /dev/stderr
done
#echo "${files[@]}" > /dev/stderr
#printf '%s\n' "${files[@]}" > /dev/stderr
#echo "${files[@]//${FIND_DIR}/}" | tr " " "\n" > /dev/stderr
read -p "Proceeding with those files ? [Y] " choice
if [[ $choice =~ ^[nN] ]]; then
	exit 0
fi

#cat "${files[@]}" | sed -E "s/\x03//" > tmp.$$.txt 
cat "${files[@]}" | sed -E "s/\x03//" | ./gen.scripts.sh ${DATE} ${TIME}
#echo "tmp.$$.txt created" > /dev/stderr


#find ../penndolog/sub_CV/Echanges_CV-ES/_XSALGOS -mindepth 2 -type f| grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[6],substr(a[7],0,2),substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == 20160607) exit(0); }"

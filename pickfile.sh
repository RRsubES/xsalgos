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
MONTH_REGEX="(0[0-9]|11|12)"
DAY_REGEX="([012][0-9]|30|31)"
DATE_REGEX="(${YEAR_REGEX}${MONTH_REGEX}${DAY_REGEX})"

HOUR_REGEX="([01][0-9]|2[0-3])"
MINUTE_REGEX="([0-5][0-9])"
TIME_REGEX="(${HOUR_REGEX}${MINUTE_REGEX})"

[[ $1 =~ ^${DATE_REGEX}$ ]] && { DATE="$1"; shift; }
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }


declare -A MONTH_ARY
#MONTH_ARY="janvier fevrier mars avril mai juin juillet aout septembre octobre novembre decembre"
MONTH_ARY[1]="janvier"
MONTH_ARY[2]="fevrier"
MONTH_ARY[3]="mars"
MONTH_ARY[4]="avril"
MONTH_ARY[5]="mai"
MONTH_ARY[6]="juin"
MONTH_ARY[7]="juillet"
MONTH_ARY[8]="aout"
MONTH_ARY[9]="septembre"
MONTH_ARY[10]="octobre"
MONTH_ARY[11]="novembre"
MONTH_ARY[12]="decembre"

YEAR=${DATE:0:4}

#for i in {1..12}; do echo "prev(${MONTH_ARY[$i]} ${YEAR}) = ${MONTH_ARY[$(( ( (${i}-1+11) % 12 + 1) ))]} $(( YEAR + $(($i>1?0:-1)) ))"; done

CUR_NR_MONTH=$((${DATE:4:2}))
PREV_NR_MONTH=$(( (${CUR_NR_MONTH}-1+11) % 12 + 1))
YEAR_PREV_MONTH=$(( YEAR + $(( CUR_NR_MONTH>1?0:-1)) ))
#echo "cur_month/year = ${CUR_NR_MONTH}/${YEAR}"
#echo "prev_nr_month/year_prev_month = ${PREV_NR_MONTH}/${YEAR_PREV_MONTH}"

#find . -name "xslgs_[0-9]*" | sort | tail -n 1 # get last file from prev month

# list all files of the current month and prev month
# print all files and filter with prev and current day

JAN_REGEX="((01)_?([Jj]an(vier)?))"
FEB_REGEX="((02)_?([Ff][ée]v(rier)?))"
MAR_REGEX="((03)_?([Mm]ars))"
APR_REGEX="((04)_?([Aa]vril))"
MAY_REGEX="((05)_?([Mm]ai))"
JUN_REGEX="((06)_?([Jj]uin))"
JUL_REGEX="((07)_?([Jj]uillet))"
AUG_REGEX="((08)_?([Aa]out))"
SEP_REGEX="((09)_?([Ss]ep(tembre)?))"
OCT_REGEX="((10)_?([Oo]ct(obre)?))"
NOV_REGEX="((11)_?([Nn]ov(embre)?))"
DEC_REGEX="((12)_?([Dd][ée]c(embre)?))"

NUMMONTH_REGEX="(${JAN_REGEX}|${FEB_REGEX}|${MAR_REGEX}|${APR_REGEX}|${MAY_REGEX}|${JUN_REGEX}|${JUL_REGEX}|${AUG_REGEX}|${SEP_REGEX}|${OCT_REGEX}|${NOV_REGEX}|${DEC_REGEX})"
FIND_REGEX=".*/${YEAR_REGEX}/${NUMMONTH_REGEX}"

FIND_DIR="_XSALGOS"

echo "date: ${DATE}" > /dev/stderr
#find "${FIND_DIR}" -mindepth 2 -maxdepth 2 -type d | grep -E "${FIND_REGEX}" | awk '{ n=split($0,a,"/"); printf("%s%s %s\n", a[n-1], substr(a[n],1,2), $0); }' | sort | awk "{ print ; if (\$1 == ${DATE:0:6}) exit(0); }" | tail -n 2
#find "${FIND_DIR}" -mindepth 2 -type f | grep -E "xslgs_[0-9]{2}.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "[xX][sS][cC][dD][sS]2" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[2], substr(a[3],0,2), substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | sed -E "s/(.{8} )(.*)/\2/"
	#find "${FIND_DIR}" -mindepth 2 -type f | grep -E "xslgs_[0-9]{2}.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "[xX][sS][cC][dD][sS]2" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[2], substr(a[3],0,2), substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | sed -E "s/(.{8} )(.*)/\2/" | xargs cat >> tmp.$$.txt
	#find "${FIND_DIR}" -mindepth 2 -type f | grep -E "xslgs_[0-9]{2}.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "[xX][sS][cC][dD][sS]2" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[2], substr(a[3],0,2), substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | sed -E "s/(.{8} )(.*)/\2/" | ./gen.scripts.sh ${DATE} ${TIME}
files=()
for f in $(find "${FIND_DIR}" -mindepth 2 -type f | grep -E "xslgs_[0-9]{2}.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "[xX][sS][cC][dD][sS]2" | awk '{ n=split($0,a,"/"); printf("%s%s%s %s\n", a[2], substr(a[3],0,2), substr(a[n],7,2), $0); }' | sort | uniq -w 8 | awk "{ print ; if (\$1 == ${DATE}) exit(0); }" | tail -n 2 | sed -E "s/(.{8} )(.*)/\2/"); do
	files+=( "$f" )
done
echo "${files[@]}" > "/dev/stderr"
read -p "Proceeding with those files ? [Y] " choice
if [[ $choice =~ ^[nN] ]]; then
	exit 0
fi

cat "${files[@]}" | sed -E "s/\x03//" > tmp.$$.txt 
cat "${files[@]}" | sed -E "s/\x03//" | ./gen.scripts.sh ${DATE} ${TIME}
	#echo "tmp.$$.txt created" > /dev/stderr


#find . -type f | grep -E "${REGEX}" |  sed -E "s/${REGEX}/\1\2\3 \0/" | sort | awk '{ if ($1 == "20160506") { print ; exit 0 } print ;}' | tail -n 2
#find . -maxdepth 2 -type d | grep -E "^\./[0-9]{4}/(avril|mai)" | awk 'BEGIN  { MONTH["avril"]="04"; MONTH["mai"]="05"; } { split($0,a,"/"); printf("%s%s %s\n", a[2], MONTH[a[3]], $0); } ' | awk '{ print ; if ($1 == 201604) exit(0); }' | tail -n 2 | cut -d ' ' -f2

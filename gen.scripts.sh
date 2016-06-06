#!/bin/bash

declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)

function usage {
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) DATE_YYYYMMDD TIME_HHMM < XSALGOS_FILE
For any new group, amend list.rgrp file. No pipe allowed, only redirected file.

e.g.: $(basename $0) 20160504 1905 < xslgs.04-05

e.g.: cat xslgs.01-05 xslgs.02-05 xslgs.03-05 > xslgs 
      $(basename $0) 20160503 0005 < xslgs
EOF
	exit 1
}

[ $# -eq 0 ] && usage "no parameter detected"
[ ! -w ./ ] && usage "unable to write in the current directory"

TIME_REGEX="([01][0-9]|2[0-3])[0-5][0-9]"

DAY_IN_REGEX="( [1-9]|[12][0-9]|3[01])"
MONTH_IN_REGEX="( [1-9]|1[012])"
YEAR_IN_REGEX="([0-9]{4})"
DATE_IN_REGEX="(${DAY_IN_REGEX}\/${MONTH_IN_REGEX}\/${YEAR_IN_REGEX})"

DAY_REGEX="${DAY_IN_REGEX// /0}"
MONTH_REGEX="${MONTH_IN_REGEX// /0}"
YEAR_REGEX="${YEAR_IN_REGEX}"
DATE_REGEX="(${YEAR_REGEX}${MONTH_REGEX}${DAY_REGEX})"

POSI_REGEX="P[NESF][0-9]"

CSECT_REGEX="([MQZXNGA][SIU]|[JVKW][SU]|JH|I[ND])" # civil sector
MSECT_REGEX="R${CSECT_REGEX}" # military sector
GSECT_REGEX="R?${CSECT_REGEX}" # generic sector

CLIST_REGEX="(${CSECT_REGEX} +)+"
GLIST_REGEX="(${GSECT_REGEX} +)+"

DEFCF_REGEX="${POSI_REGEX} += (FERMEE|${GLIST_REGEX})"

#-v TIME: checks if TIME variable has been set
#FIXME: bc stuff because 0500 can be evaluated otherwise as octal, in awk as well...
[[ $1 =~ ^${DATE_REGEX}$ ]] && { DATE="$1"; shift; }
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }
# -t 0: check if stdin is connected to a terminal
# -p 0: check if stdin is connected via a pipe
# if both fail, it means it was redirected via a "< FILE"
#echo "pipe? $([[ -p 0 ]]; echo $?)"
#echo "terminal? $([[ -t 0 ]]; echo $?)"
[[ -v DATE ]] && [[ -v TIME ]] && [[ -p 0 || -t 0 ]] && [[ -f "$1" ]] && { exec < "$1"; shift; }

while (($# > 0)); do
	case "$1" in
	-h|--help)
		usage
		;;
	*)
		usage "$1 is of type unknown"
		;;
	esac
	shift
done

#echo "TIME? $([[ -v TIME ]]; echo $?)"
[[ ! -v DATE ]] && usage "DATE_YYYYMMDD not defined"
[[ ! -v TIME ]] && usage "TIME_HHMM not defined"
#[[ -p 0 || -t 0 ]] && usage "No valid detected data to process"

echo "#!/usr/bin/awk -f
function display(d,h,l) {
	# delete military sectors
	gsub(/${MSECT_REGEX}/, \"\", l)
	# delete extra spaces
	gsub(/ +/, \" \", l)
	gsub(/^ +/,\"\", l)
	if (!length(d))
		print l, \" : date not found, left out\" > \"/dev/stderr\"
	if (length(l) > 0 && length(h) > 0) 
		print d, h, l
}

/^\*\*\* JOURNEE DU ${DATE_IN_REGEX} CALCULATEUR [0-9] \*\*\*/ {
	DAY=substr(\$0,16,2)
	MONTH=substr(\$0,19,2)
	YEAR=substr(\$0,22,4)
	gsub(/ /, \"0\", DAY)
	gsub(/ /, \"0\", MONTH)
	gsub(/ /, \"0\", YEAR)
	DATE=YEAR \"\" MONTH \"\" DAY
}

/^0\*\*\* ${TIME_REGEX} STPV-Loc OPP ${DEFCF_REGEX}\$/ {
	display(DATE,HOUR,LINE)
	HOUR=\$2
	LINE=\"\"
	if (\$7 == \"FERMEE\")
		next
	\$1=\$2=\$3=\$4=\"\"
	LINE=\$0
}

/^ +${GLIST_REGEX}\$/ {
	LINE=LINE\$0
}

/^ +${DEFCF_REGEX}\$/ {
	display(DATE,HOUR,LINE)
	LINE=\"\"
	if (\$3 == \"FERMEE\")
		next
	LINE=\$0
}

END {
	display(DATE,HOUR,LINE)
}" > filter.$$.awk
chmod +x filter.$$.awk

echo "#!/usr/bin/awk -f

function is_before(d,h) {
	if (d > $(echo ${DATE} | bc))
		return 0
	if (d < $(echo ${DATE} | bc))
		return 1
	if (h <= $(echo ${TIME} | bc))
		return 1
	return 0
}

# military sectors already left out...
/^${DATE_REGEX} ${TIME_REGEX} ${POSI_REGEX} = ${CLIST_REGEX}\$/ {
	DATE=\$1
	HOUR=\$2
	if (is_before(DATE,HOUR)) {
		for(i = 5; i <= NF; i++)
			db[\$i]=\$3
	} else
		exit 0
}

END {
	if (is_before(DATE,HOUR)) {
		printf(\"${DATE} not found, exiting\\n\") > \"/dev/stderr\"
		exit 1
	}
	layer=\"NDSHIU\"
	sect=\"I NGA JVKW MQZX\"
	for(s in db) {
		#printf(\"%s %d %s = %s\n\", index(sect,substr(s,1,1)), index(layer,substr(s,2,1)), s, db[s])
		printf(\"%s = %s\n\", s, db[s])
	}
}" > read.along.$$.awk
chmod +x read.along.$$.awk

echo "#!/usr/bin/awk -f
{
	db[substr(\$1,1,1)][substr(\$1,2,1)] = \$0
}

END {
	layer=\"NDSHIU\"
	sect=\"I NGA JVKW MQZX\"
	# printf(\"Statut à %s:\n\", ${TIME}) > \"/dev/stderr\"
	for(i = 1; i <= length(sect); i++) {
		if (substr(sect, i, 1) == \" \")
			print \"\"
		else {
			for(j = 1; j <= length(layer); j++) {
				tmp=db[substr(sect, i, 1)][substr(layer, j, 1)]
				if (length(tmp) > 0)
					print tmp
			}
		}
	}
}" > sort.$$.awk
chmod +x sort.$$.awk

if [ -e list.rgrp ]; then
	./filter.$$.awk "$@" | ./read.along.$$.awk | awk -f expand.and.rename.awk "PASS=1" list.rgrp "PASS=2" /dev/stdin | sort
else
	echo "${RED}[E]${NORMAL} list.rgrp not found, unable to shorten expressions" > /dev/stderr
	./filter.$$.awk "$@" | ./read.along.$$.awk | ./sort.$$.awk
fi

rm -f filter.$$.awk read.along.$$.awk sort.$$.awk 2>/dev/null


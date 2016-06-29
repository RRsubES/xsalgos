#!/bin/bash

declare -r RED=$(tput setaf 1)
declare -r NORMAL=$(tput sgr0)

function usage {
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) DATE TIME [-q|--quiet] [-f|--keep-filter] < XSALGOS_FILE

DATE and TIME formats:
		DATE YYYYMMDD
		TIME HHMM

-f		: keep the script used to extract information. Filename is specified.
		  Syntax to use it:
		  e.g.: ./filter.12345.awk < XSALGOS_FILE
-h		: displays help
-q		: quiet mode (unset by default)

For any new group, amend list.rgrp file, if not found, simple sort is applied.
The order of the parameters does not matter anymore.

e.g.: $(basename $0) 20160504 1905 < xslgs.04-05

e.g.: cat xslgs.01-05 xslgs.02-05 xslgs.03-05 > xslgs 
      $(basename $0) -q -f 20160503 0005 < xslgs
EOF
	exit 1
}

function echo_if {
	if [ ${OPTION_QUIET} -ne 0 ]; then
		return
	fi
	echo "$@" > /dev/stderr
}

[ $# -eq 0 ] && usage "no parameter detected"
[ ! -w ./ ] && usage "unable to write in the current directory"

TIME_REGEX="([01][0-9]|2[0-3])[0-5][0-9]"

# stdin date pattern, may contain blanks
DAY_IN_REGEX="( [1-9]|[12][0-9]|3[01])"
MONTH_IN_REGEX="( [1-9]|1[012])"
YEAR_IN_REGEX="(20[0-9]{2})"
DATE_IN_REGEX="(${DAY_IN_REGEX}\/${MONTH_IN_REGEX}\/${YEAR_IN_REGEX})"

# in generated awk scripts, no blanks, only figures
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

OPTION_QUIET=0
OPTION_ERASE_FILTER=1

#-v TIME: checks if TIME variable has been set

# -t 0: check if stdin is connected to a terminal
# -p 0: check if stdin is connected via a pipe
# if both fail, it means it was redirected via a "< FILE"
#echo "pipe? $([[ -p 0 ]]; echo $?)"
#echo "terminal? $([[ -t 0 ]]; echo $?)"

while (($# > 0)); do
	if [[ $1 =~ ^${DATE_REGEX}$ ]]; then
		DATE="$1"
	elif [[ $1 =~ ^${TIME_REGEX}$ ]]; then
		TIME="$1"
	else
		case "$1" in
		-f|--keep-filter)
			OPTION_ERASE_FILTER=0
			;;
		-h|--help)
			usage
			;;
		-q|--quiet)
			OPTION_QUIET=1
			;;
		*)
			if [[ -t 0 || -p 0 ]] && [ -f "$1" ]; then
				exec < "$1"
			else
				usage "$1 is of type unknown"
			fi
			;;
		esac
	fi
	shift
done

[[ ! -v DATE ]] && usage "DATE_YYYYMMDD not defined"
[[ ! -v TIME ]] && usage "TIME_HHMM not defined"
#[[ -p 0 || -t 0 ]] && usage "No valid detected data to process"
[[ ${OPTION_QUIET} -eq 0 ]] && { echo_if "DATE=${DATE} TIME=${TIME}" ; }

echo "#!/usr/bin/awk -f
function display(d,h,p,l,		ary,i) {
	# delete military sectors
	gsub(/${MSECT_REGEX}/, \"\", l)
	if (!length(d)) {
		print \"At line\", NR ,\"date not available yet, check header, exiting\" > \"/dev/stderr\"
		exit(1)	
	}
	split(l,ary)	
	asort(ary)
	l=\"\"
	for(i=1; i<=length(ary); i++)
		l=l ary[i] \" \"
	if (length(l) > 0 && length(h) > 0) 
		print d\".\"h, p, \"=\", l
}

/^\*\*\* JOURNEE DU ${DATE_IN_REGEX} CALCULATEUR [0-9] \*\*\*$/ {
	# expression may be found more than once (multiple concatenated
	# files), * special case *
	if (length(DATE) > 0) {
		display(DATE,HOUR,POSI,LINE)
		DATE=HOUR=LINE=\"\"
	}
	DAY=substr(\$0,16,2)
	MONTH=substr(\$0,19,2)
	YEAR=substr(\$0,22,4)
	gsub(/ /, \"0\", DAY)
	gsub(/ /, \"0\", MONTH)
	gsub(/ /, \"0\", YEAR)
	DATE=YEAR \"\" MONTH \"\" DAY
	next
}

/^0\*\*\* ${TIME_REGEX} STPV-Loc OPP ${DEFCF_REGEX}\$/ {
	display(DATE,HOUR,POSI,LINE)
	HOUR=\$2
	LINE=\"\"
	if (\$7 == \"FERMEE\")
		next
	POSI=\$5
	\$1=\$2=\$3=\$4=\$5=\$6=\"\"
	LINE=\$0
	next
}

/^ +${GLIST_REGEX}\$/ {
	LINE=LINE\$0
	next
}

/^ +${DEFCF_REGEX}\$/ {
	display(DATE,HOUR,POSI,LINE)
	LINE=\"\"
	if (\$3 == \"FERMEE\")
		next
	POSI=\$1
	\$1=\$2=\"\"
	LINE=\$0
	next
}

END {
	display(DATE,HOUR,POSI,LINE)
}" > filter.$$.awk
chmod +x filter.$$.awk

echo "#!/usr/bin/awk -f

function is_before(tc) {
	if (tc <= ${DATE}.${TIME})
		return 1
	return 0
}

# military sectors already left out...
/^${DATE_REGEX}\.${TIME_REGEX} ${POSI_REGEX} = ${CLIST_REGEX}\$/ {
	TIME_CHECK=\$1
	if (is_before(TIME_CHECK)) {
		for(i = 4; i <= NF; i++)
			db[\$i]=\$2
	} else
		exit 0
}

END {
	if (is_before(TIME_CHECK)) {
		printf(\"${DATE} not found, exiting\\n\") > \"/dev/stderr\"
		exit 1
	}
	for(s in db)
		printf(\"%s = %s\n\", s, db[s])
}" > read.along.$$.awk
chmod +x read.along.$$.awk

echo "#!/usr/bin/awk -f
{
	db[substr(\$1,1,1)][substr(\$1,2,1)] = \$0
}

END {
	layer=\"NDSHIU\"
	sect=\"I NGA JVKW MQZX\"
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
	sed -E "s/\x03//" | ./filter.$$.awk "$@" | ./read.along.$$.awk | awk -f expand.and.rename.awk "PASS=1" list.rgrp "PASS=2" /dev/stdin | sort
else
	echo_if "${RED}[E]${NORMAL} list.rgrp not found, unable to shorten expressions"
	sed -E "s/\x03//" | ./filter.$$.awk "$@" | ./read.along.$$.awk | ./sort.$$.awk
fi

[[ ${OPTION_ERASE_FILTER} -ne 0 ]] && rm -f filter.$$.awk 2>/dev/null || echo_if "${RED}Script filename:${NORMAL} filter.$$.awk"
rm -f read.along.$$.awk sort.$$.awk 2>/dev/null


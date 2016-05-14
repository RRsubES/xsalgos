#!/bin/bash

function usage {
	declare -r RED=$(tput setaf 1)
	declare -r NORMAL=$(tput sgr0)
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1" > "/dev/stderr"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) TIME_HHMM < XSALGOS_FILE

e.g.: $(basename $0) 1905 < xslgs.04-05
EOF
	exit 1
}
[ $# -eq 0 ] && usage "no parameter detected"
[ ! -w ./ ] && usage "unable to write in the current directory"

TIME_REGEX="([01][0-9]|20|21|22|23)[0-5][0-9]"
POSI_REGEX="P[NESF][0-9]"

CSECT_REGEX="([MQZXNGA][SIU]|[JVKW][SU]|JH|I[ND])" # civil sector
MSECT_REGEX="R${CSECT_REGEX}" # military sector
GSECT_REGEX="R?${CSECT_REGEX}" # generic sector

CLIST_REGEX="(${CSECT_REGEX} +)+"
GLIST_REGEX="(${GSECT_REGEX} +)+"

DEFCF_REGEX="${POSI_REGEX} += (FERMEE|${GLIST_REGEX})"

#-v TIME: checks if TIME variable has been set
#FIXME: bc stuff because 0500 can be evaluated otherwise as octal, in awk as well...
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }
# -t 0: check if stdin is connected to a terminal
# -p 0: check if stdin is connected via a pipe
# if both fail, it means it was redirected via a "< FILE"
#echo "pipe? $([[ -p 0 ]]; echo $?)"
#echo "terminal? $([[ -t 0 ]]; echo $?)"
[[ -v TIME ]] && [[ -p 0 || -t 0 ]] && [[ -f "$1" ]] && { exec < "$1"; shift; }

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
[[ ! -v TIME ]] && usage "TIME_HHMM not defined"
[[ -p 0 || -t 0 ]] && usage "No valid detected data to process"

echo "#!/usr/bin/awk -f
function display(h,l) {
	# delete military sectors
	gsub(/${MSECT_REGEX}/, \"\", l)
	# delete extra spaces
	gsub(/ +/, \" \", l)
	gsub(/^ +/,\"\", l)
	if (length(l) > 0)
		print h, l
}

/^0\*\*\* ${TIME_REGEX} STPV-Loc OPP ${DEFCF_REGEX}\$/ {
	display(HOUR,LINE)
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
	display(HOUR,LINE)
	LINE=\"\"
	if (\$3 == \"FERMEE\")
		next
	LINE=\$0
}

END {
	display(HOUR,LINE)
}" > filter.$$.awk
chmod +x filter.$$.awk

echo "#!/usr/bin/awk -f

# military sectors already left out...
/^${TIME_REGEX} ${POSI_REGEX} = ${CLIST_REGEX}\$/ {
	if (\$1 > $(echo ${TIME} | bc))
		exit 0
	for(i = 4; i <= NF; i++)
		db[\$i]=\$2
}

END {
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

./filter.$$.awk "$@" | ./read.along.$$.awk | awk -f concat.awk "PASS=1" uir "PASS=2" /dev/stdin #| sort
#| ./sort.$$.awk

rm -f filter.$$.awk read.along.$$.awk sort.$$.awk 2>/dev/null


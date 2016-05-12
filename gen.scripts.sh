#!/bin/bash

function usage {
	declare -r RED=$(tput setaf 1)
	declare -r NORMAL=$(tput sgr0)
	if ! [ -z "$1" ]; then
		echo -e "${RED}[E]${NORMAL}: $1"
	fi
cat << EOF
Syntax: $(basename $0) TIME_HHMM < XSALGOS_FILE

e.g.: $(basename $0) 1905 < xslgs.04-05
EOF
	exit 1
}
[ $# -eq 0 ] && usage "no parameter detected"
[ ! -w ./ ] && usage "unable to write in the current directory"

TIME_REGEX="([01][0-9]|20|21|22|23)[0-5][0-9]"
POSI_REGEX="P[NESF][0-9]"

CSECT_REGEX="[MQZXNGAIJVKW][NDSHIU]" # civil sector
MSECT_REGEX="R${CSECT_REGEX}" # military sector
GSECT_REGEX="R?${CSECT_REGEX}" # generic sector

CLIST_REGEX="(${CSECT_REGEX} +)+"
GLIST_REGEX="(${GSECT_REGEX} +)+"

DEFCF_REGEX="${POSI_REGEX} += (FERMEE|${GLIST_REGEX})"

while (($# > 0)); do
	case "$1" in
	-h|--help)
		usage
		;;
	*)
		[[ ! $1 =~ ${TIME_REGEX} ]] && usage "TIME $1 invalid"
		TIME=$1
		;;

	esac
	shift
done

if [ -z TIME ]; then
	usage "TIME_HHMM not found"
fi

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
}" > script.awk
chmod +x script.awk

echo "#!/usr/bin/awk -f

# military sectors already left out...
/^${TIME_REGEX} ${POSI_REGEX} = ${CLIST_REGEX}\$/ {
	if (\$1 > ${TIME})
		exit 0
	for(i = 4; i <= NF; i++)
		db[\$i]=\$2
}

END {
	for(p in db) {
		printf(\"%s = %s\n\", p, db[p]) | \"sort -k1,1\"
	}
}" > get.conf.awk
chmod +x get.conf.awk

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
}" > display.awk
chmod +x display.awk

./script.awk "$@" | ./get.conf.awk | ./display.awk

rm -f script.awk get.conf.awk display.awk 2>/dev/null

#!/bin/bash

function usage {
cat << EOF
Syntax: $(basename $0) TIME_HHMM < XSALGOS_FILE

e.g.: $(basename $0) 1905 < xsalgos.04-05
EOF
	exit 1
}
[ $# -eq 0 ] && usage
[[ ! $1 =~ [012][0-9][0-5][0-9] ]] && usage

CSECT="[MQZXNGAIJVKW][NDSHIU]"
MSECT="R${CSECT}"
SECT="R?${CSECT}"
HOUR="[012][0-9][0-5][0-9]"
POSI="P[NESF][0-9]"
LIST="(${SECT} +)+"
CLIST="(${CSECT} +)+"
HEAD="${POSI} += (FERMEE|${LIST})"
TIME=$1

echo "#!/usr/bin/awk -f
function display(h,l) {
	# delete military sectors
	gsub(/${MSECT}/, \"\", l)
	# delete extra spaces
	gsub(/ +/, \" \", l)
	gsub(/^ +/,\"\", l)
	if (length(l) > 0)
		print h, l
}

/^0\*\*\* ${HOUR} STPV-Loc OPP ${HEAD}\$/ {
	display(HOUR,LINE)
	HOUR=\$2
	LINE=\"\"
	if (\$7 == \"FERMEE\")
		next
	\$1=\$2=\$3=\$4=\"\"
	LINE=\$0
}

/^ +${LIST}\$/ {
	LINE=LINE\$0
}

/^ +${HEAD}\$/ {
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
/^${HOUR} ${POSI} = ${CLIST}\$/ {
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
	printf(\"Statut à %s:\n\", ${TIME}) > \"/dev/stderr\"
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

./script.awk | ./get.conf.awk | ./display.awk

rm -f script.awk get.conf.awk display.awk 2>/dev/null

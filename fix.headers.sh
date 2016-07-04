#!/bin/bash

[[ -e ./shared.include ]] && source ./shared.include || { echo "error: shared.include not found" > /dev/stderr; exit 1; }

function usage {
	if ! [ -z "$1" ]; then
		err "$1"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0)

e.g.: $(basename $0)
EOF
	exit 1
}

function fix_header {
	# $1 : date
	# $2 : filename
	info "Fixing header for $2"
	local year=${1:0:4}
	local month=${1:4:2}
	local day=${1:6:2}
	echo "*** JOURNEE DU ${day/#0/ }/${month/#0/ }/${year} CALCULATEUR 1 *** FIX" > "$2.$$"
	#cat "$2" | sed -E "s/${ETX_CHAR}//" >> "$2.$$"
	#cat "$2" >> "$2.$$"
	#mv "$2.$$" "$2"
}

function fix_tail {
	info "Fixing tail for $1"
	echo "" >> "$1"
}

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


#no spaces/blanks allowed
find "${FIND_DIR}" -mindepth 2 -type f | grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}\.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk "{ year=month=\"\"; n=split(\$0,a,\"/\"); for(i=1; i <= n; i++) { if (a[i] ~ /^${YEAR_REGEX}\$/) year=a[i]; if (a[i] ~ /^${MONTH_REGEX}_?.+\$/) month=substr(a[i],0,2); }  printf(\"%s%s%s %s\n\", year, month, substr(a[n],7,2), \$0); }" | sort | while read DATE FILE; do
	check_header "${FILE}"
	[[ $? -ne 0 ]] && fix_header "$DATE" "$FILE"
	#check_tail "${FILE}"
	#[[ $? -ne 0 ]] && fix_tail "$FILE"
done

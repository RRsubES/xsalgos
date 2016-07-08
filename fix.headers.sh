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
	declare -r FAKE=0
	info "Fixing header for $2"
	local year=${1:0:4}
	local month=${1:4:2}
	local day=${1:6:2}
	if [ $FAKE -eq 0 ]; then
		info "Fake fix for test purpose; change FAKE variable"
	else
		echo "*** JOURNEE DU ${day/#0/ }/${month/#0/ }/${year} CALCULATEUR 1 *** FIX" > "$2.$$"
		cat "$2" >> "$2.$$"
		mv "$2.$$" "$2"
	fi
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
xsalgos_files | while read DATE FILE; do
	check_header "${FILE}"
	[[ $? -ne 0 ]] && fix_header "$DATE" "$FILE"
done

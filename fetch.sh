#!/bin/bash

[[ -e ./shared.include ]] && source ./shared.include || { echo "error: shared.include not found" > /dev/stderr; exit 1; }

#NO BLANK ALLOWED IN FILENAMES
OPTION_BEFORE=1
OPTION_AUTO=1
declare -r BEFORE_REGEX="([0-9]+)"

function usage {
	if ! [ -z "$1" ]; then
		err "$1"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) [-a|--auto] [-b|--before n] DATE_YYYYMMDD 

-a		: skip questions, auto mode.
-b n		: how many days are kept before the date
		(1 by default).

e.g.: $(basename $0) 20160504
e.g.: $(basename $0) -a -b 3 20160504
EOF
	exit 1
}

while (($# > 0)); do
	case "$1" in
	-a|--auto)
		OPTION_AUTO=0
		;;
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

[[ ! ${OPTION_BEFORE} =~ ^${BEFORE_REGEX}$ ]] && usage "${OPTION_BEFORE} is not detected as valid, supposed to be a number"

files=() #no spaces/blanks allowed
for f in $(xsalgos_files | uniq -w 8 | grep -B ${OPTION_BEFORE} -E "^${DATE}" | cut -d ' ' -f2-); do
	files+=( "$f" )
	echo "${f#${FIND_DIR}}" > /dev/stderr
done

if [ ${#files[@]} -eq 0 ]; then
	info "No file found with ${DATE}"
	exit 0
fi

if [ ${OPTION_AUTO} -eq 1 ]; then
	read -p "Proceeding with those files ? [Y] " choice > /dev/stderr
	[ $choice =~ ^[nN] ] && exit 0
fi

headers_missing=0
for f in ${files[@]}; do
	check_header "$f"
	[ $? -ne 0 ] && { (( headers_missing++ )); err ">> $f"; }
	list="${list} $f"
done
if [ ${headers_missing} -gt 0 ]; then
	err "${headers_missing} invalid header(s) found, lack of:"
	err "${HEADER_REGEX//\\/}"
	err "Fix them first."
	exit 1
fi
# problem if prev file does not end up with LF
# need to add it with echo
#cat "${files[@]}" | sed -E "s/${ETX_CHAR}//"
for f in ${files[@]}; do
	cat "$f"; echo ""
done | sed -E "s/${ETX_CHAR}//"


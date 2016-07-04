#!/bin/bash

[[ -e ./shared.include ]] && source ./shared.include || { echo "error: shared.include not found" > /dev/stderr; exit 1; }

#NO BLANK ALLOWED IN FILENAMES
OPTION_BEFORE=1
declare -r BEFORE_REGEX="([0-9]+)"

function usage {
	if ! [ -z "$1" ]; then
		err "$1"
	fi
cat << EOF > "/dev/stderr"
Syntax: $(basename $0) [-b|--before n] DATE_YYYYMMDD 

-b n		: how many days are kept before the date
		(1 by default).

e.g.: $(basename $0) 20160504
e.g.: $(basename $0) -b 3 20160504
EOF
	exit 1
}

while (($# > 0)); do
	case "$1" in
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
for f in $(find "${FIND_DIR}" -mindepth 2 -type f | grep -E "[xX][sS][lL][gG][sS]_[0-9]{2}\.[0-9]{2}(\.[tT][xX][tT])?$" | grep -v -E "([xX][sS][cC][dD][sS]2|STATUCE)" | awk "{ year=month=\"\"; n=split(\$0,a,\"/\"); for(i=1; i <= n; i++) { if (a[i] ~ /^${YEAR_REGEX}\$/) year=a[i]; if (a[i] ~ /^${MONTH_REGEX}_?.+\$/) month=substr(a[i],0,2); }  printf(\"%s%s%s %s\n\", year, month, substr(a[n],7,2), \$0); }" | sort | uniq -w 8 | grep -B ${OPTION_BEFORE} -E "^${DATE}" | cut -d ' ' -f2-); do
	files+=( "$f" )
	echo "${f#${FIND_DIR}}" > /dev/stderr
done

if [ ${#files[@]} -eq 0 ]; then
	info "No file found with ${DATE}"
	exit 0
fi
read -p "Proceeding with those files ? [Y] " choice > /dev/stderr
if [[ $choice =~ ^[nN] ]]; then
	exit 0
else
	headers_missing=0
	for f in ${files[@]}; do
		check_header "$f"
		[ $? -ne 0 ] && { headers_missing=$(($headers_missing + 1)); err ">> $f"; }
		list="${list} $f"
	done
	if [ ${headers_missing} -gt 0 ]; then
		err "${headers_missing} invalid header(s) found, lack of:"
		err "${HEADER_REGEX//\\/}"
		err "Fix them first."
		exit 1
	fi
	cat "${files[@]}" | sed -E "s/${ETX_CHAR}//"
fi


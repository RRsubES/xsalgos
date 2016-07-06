#!/bin/bash

[[ -e ./shared.include ]] && source ./shared.include || { echo "error: shared.include not found" > /dev/stderr; exit 1; }

function usage {
	if ! [ -z "$1" ]; then
		err "$1"
	fi
	cat << EOF > /dev/stderr
Syntax: $(basename $0) YYYYMMDD HHMM
EOF
	exit 1
}

[[ $1 =~ ^${DATE_REGEX}$ ]] && { DATE="$1"; shift; }
[[ $1 =~ ^${TIME_REGEX}$ ]] && { TIME="$1"; shift; }
[[ $1 =~ ^-h$ ]] || [[ $1 =~ ^--help$ ]] && usage

[[ ! -v DATE ]] || [[ ! -v TIME ]] && usage "DATE or TIME missing"

./fetch.sh ${DATE} | ./gen.scripts.sh ${DATE} ${TIME}

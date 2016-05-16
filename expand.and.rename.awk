function expand_subgrp(array,idx,	i,j,tmp) {
	tmp=""
	gsub(/(\[|\])/, "", array[idx])
	gsub(/(\[|\])/, "", array[idx+1])
	for(i=1; i <= length(array[idx]); i++) {
		for(j=1; j <= length(array[idx+1]); j++)
			tmp=tmp " " substr(array[idx],i,1) substr(array[idx+1],j,1)
	}
	return substr(tmp,2)
}

function store_sectors(expr,	n,tmp,j,ary,m,sub_ary) {
	# FIXME: check if n!=2, error.
	n=patsplit(expr, ary, /(\[([A-Z]+)\]|[A-Z])/)
	tmp=expand_subgrp(ary,1)
	m=split(tmp,sub_ary)
	for(j=1; j <= m; j++) {
		if (sub_ary[j] in Sector)
			continue
		Sector[sub_ary[j]]=Sectors_Pow
		SectId[Sectors_Pow]=sub_ary[j]
		Sectors_Pow*=2
	}
}

function store_group(name,expr,		n,ary,i,tmp,m,tmp_ary,j) {
	if (expr in Grp) {
		Grp[name]=or(Grp[name],Grp[expr])
	} else {
		# check if n!=2
		n=patsplit(expr, ary, /(\[([A-Z]+)\]|[A-Z])/)
		tmp=expand_subgrp(ary,1)
		m=split(tmp,tmp_ary)
		for(j=1; j <= m; j++)
			Grp[name]=or(Grp[name],Sector[tmp_ary[j]])
	}
}

function enum(bit,		tmp,j) {
	tmp = ""
	for(j = 1; bit != 0; bit = rshift(bit, 1)) {
		if (and(bit,1) == 1)
			tmp = tmp " " SectId[j]
		j *= 2
	}
	return substr(tmp,2)
}

BEGIN {
	Sectors_Pow = 1
}

PASS==1 && $1 ~ /^#.*/ { next } # allow comments starting with #

PASS==1 && $1 == "__ENUM__" {
	for(i=2; i <= NF; i++)
		store_sectors($i)
	next
}

PASS==1 && NF>1{
	for (i=2; i <= NF; i++)
		store_group($1,$i)
}

PASS==2 {
	PosId[$3]=or(PosId[$3],Sector[$1])
}

END {
	# need to wait to validate all values of Grp
	for(g in Grp)
		GrpId[Grp[g]]=g
	for(p in PosId) {
		if (PosId[p] in GrpId)
			print p, GrpId[PosId[p]]
		else
			print p, enum(PosId[p])
	}
}

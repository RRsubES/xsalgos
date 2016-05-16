function expand_subgrp(array,idx,	i,j,tmp,s) {
	tmp=""
	gsub(/(\[|\])/, "", array[idx])
	gsub(/(\[|\])/, "", array[idx+1])
	#printf("expand: %s\n", expr)
	for(i=1; i <= length(array[idx]); i++) {
		for(j=1; j <= length(array[idx+1]); j++) {
			s=substr(array[idx],i,1) substr(array[idx+1],j,1)
			tmp=tmp " " s
		}
	}
	gsub(/^ /, "", tmp)
	return tmp
}

function store_sectors(expr,	n,tmp,ary,sub_ary) {
	print ">>>>store_sectors:", expr
	tmp=""
	n=patsplit(expr, ary, /(\[([A-Z]+)\]|[A-Z])/)
	#printf("ary[1]: %s ", ary[1])
	#printf("ary[2]: %s ", ary[2])
	tmp=expand_subgrp(ary,1)
	#printf(">>%s\n", tmp)
	m=split(tmp,sub_ary)
	for(j=1; j <= m; j++) {
		#printf("%d=[%s] ", sectors_pow, sub_ary[j])
		sector[sub_ary[j]]=sectors_pow
		sectId[sectors_pow]=sub_ary[j]
		sectors_pow*=2
	}
	printf("\n")
}

function store_group(name,expr,		n,ary,i,tmp,m,tary,j) {
	print ">>>>store_group:", name, expr
	tmp=""
	if (expr in grp) {
		print "for ", name, ":", expr, "FOUND", grp[expr]
		grp[name]=or(grp[name],grp[expr])
	} else {
		print "for ", name, ":", expr, "NOT FOUND"
		n=patsplit(expr, ary, /(\[([A-Z]+)\]|[A-Z])/)
		#print "ary[1]: ",ary[1]
		#print "ary[2]: ",ary[2]
		#printf("%s ", ary[i])
		tmp=expand_subgrp(ary,1)
		gsub(/^ /, "", tmp)
		#print ">>", name, " = ", tmp
		m=split(tmp,tary)
		for(j=1; j <= m; j++) {
			grp[name]=or(grp[name],sector[tary[j]])
		}
		print "after ", name, grp[name]
	}
	#BAD
	#grpId[grp[name]]=name
	#printf("\n")
	#print expand_nr(ary)
	#return expand_nr(ary)
	#return tmp
}

function enum(bit,		tmp,j) {
	#print ">>>", bit
	tmp = ""
	for(j = 1; bit != 0; bit = rshift(bit, 1)) {
		if (and(bit,1) == 1)
			tmp = tmp " " sectId[j] 
		#print j, tmp
		j *= 2
	}
	return substr(tmp,2)
}

BEGIN {
	sectors_pow = 1
}

PASS==1 && $1 == "__ENUM__" {
	for(i=2; i <= NF; i++)
		store_sectors($i)
	next
}

PASS==1 && NF>1{
	tmp=""
	for (i=2; i <= NF; i++) {
		store_group($1,$i)
		#tmp=tmp " " expand($1,$i)
	}
	#gsub(/^ /, "", tmp)
	#printf("*%s %s\n", $1, tmp)
	
}

PASS==2 {
	posId[$3]=or(posId[$3],sector[$1])
	print "PASS2:", $3, $1, posId[$3], sector[$1]
}

END {
	# need to wait to validate all values of grp
	for(g in grp)
		grpId[grp[g]]=g
	for(p in posId) {
		if (posId[p] in grpId)
			print p, grpId[posId[p]]
		else
			print p, enum(posId[p])
	}
	#for (s in sectId) {
	#	print s, sectId[s]
	#}
	#printf("\n")
	#for (g in grpId) {
	#	print g, grpId[g]
	#}
}

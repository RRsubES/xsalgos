function set_bit(b, n) {
	if (n < 0)
		return b
	return or(b, 2 ** n)
}

function get_sect_id(s) {
	return id[s]
}

function enum(bit,		tmp,j) {
	#print ">>>", bit
	tmp = ""
	for(j = 1; bit != 0; bit = rshift(bit, 1)) {
		if (and(bit,1) == 1)
			tmp = tmp " " pat2name[j] 
		#print j, tmp
		j *= 2
	}
	return substr(tmp,2)
}

# __ENUM__ needed for get_id...
# first of the file
PASS==1 && $1 == "__ENUM__" {
	j=1
	for(i=2; i <= NF; i++) {
		id[$i]=i-2
		name2pat[$i]=j
		pat2name[j]=$i
		j*=2
	}
	next
}

PASS == 1 && $0 !~ /^[ \t]*$/ {
	pat = 0
	for(i = 2; i <= NF; i++)
		pat = set_bit(pat, get_sect_id($i))
	name2pat[$1] = pat
	pat2name[pat] = $1
}

PASS == 2 {
	db[$3] = set_bit(db[$3], get_sect_id($1))
}

END {
	for(p in db) {
		if (db[p] in pat2name)
			print p, pat2name[db[p]] 
		else
			print p, enum(db[p])
	}
}

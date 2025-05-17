capture program drop sim_infinite
program define sim_infinite, rclass
    syntax, sampsize(integer)
    
    clear
    set obs `sampsize'
    set seed 54321  
	
    * Generate X and Y using the same DGP as before
    gen X = rnormal()
    gen error = rnormal()
    gen Y = 2*X + error

    quietly regress Y X
	quietly matrix rtable = r(table)
    * Return results
    return scalar beta = _b[X]
    return scalar sem = _se[X]
    return scalar pvalue = rtable[4,1]
	return scalar ci_lower = rtable[5,1]
    return scalar ci_upper = rtable[6,1]
	drop error Y X
	
end





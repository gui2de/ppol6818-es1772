capture program drop sim_fixed
program define sim_fixed, rclass
    syntax, sampsize(integer)

    * Load the fixed population
    use "01_data/total_pop.dta", clear

    * Draw a random sample without replacement
    sample `sampsize', count
    quietly regress Y X
	quietly matrix rtable = r(table)
    * Return results
    return scalar beta = _b[X]
    return scalar sem = _se[X]
    return scalar pvalue = rtable[4,1]
	return scalar ci_lower = rtable[5,1]
    return scalar ci_upper = rtable[6,1]

end

**# test 
*sim_fixed, sampsize(1000)

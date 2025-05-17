clear 

* Define sample sizes as two macros

local powers ""
forvalues i = 2/21 {  // 2^2=4 to 2^21
    local size = 2^`i'
    local powers "`powers' `size'"
}

local tens "10 100 1000 10000 100000 1000000"

tempfile results_inf
save `results_inf', emptyok

foreach s of local powers {
    di "Running simulation for sample size `s'"
    simulate beta=r(beta) sem=r(sem) pvalue=r(pvalue) ci_lower=r(ci_lower) ci_upper=r(ci_upper), ///
        reps(500) nodots: sim_infinite, sampsize(`s')
    
    gen sample_size = `s'
    save sim_`s'_inf.dta, replace
    append using `results_inf'
    save `results_inf', replace
}

foreach s of local tens {
    di "Running simulation for sample size `s'"
    simulate beta=r(beta) sem=r(sem) pvalue=r(pvalue) ci_lower=r(ci_lower) ci_upper=r(ci_upper), ///
        reps(500) nodots: sim_infinite, sampsize(`s')
    
    gen sample_size = `s'
    save sim_`s'_inf.dta, replace
    append using `results_inf'
    save `results_inf', replace
}

use `results_inf', clear

save "01_data/sim_inf_results.dta", replace

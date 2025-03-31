* Define a local macro with the sample sizes
local sizes "10 100 1000 10000"

tempfile results
save `results', emptyok

foreach s of local sizes {
    di "Running simulation for sample size `s'"
    simulate beta=r(beta) sem=r(sem) pvalue=r(pvalue) ci_lower=r(ci_lower) ci_upper=r(ci_upper), ///
        reps(500) nodots: sim_fixed, sampsize(`s')
    
    * Add a variable for sample size and append to results
    gen sample_size = `s'
    save sim_`s'.dta, replace
    append using `results'
    save `results', replace
}

use `results', clear
drop X Y error

save "01_data/sim_results.dta", replace

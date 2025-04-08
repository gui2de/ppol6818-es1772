* Set up wd for jacob 
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="eman7" { 
	
	global wd "C:\Users\eman7\Dropbox\ppol6818" 
}

********************************************************************************
* Part One *********************************************************************
********************************************************************************

clear
* create a dummy dataset for the outcome var 
set seed 110898

set obs 100000

gen id = _n
gen y_pre = rnormal(0,1)
gen te = runiform(0, 0.20)

gen rand = runiform()
sort rand
gen treat = 0
replace treat = 1 in 1/500
drop rand 
sort id 

* Add treatment effect
gen y_post = y_pre + te 

* Check that we match (within rounding error) of required stats for Y TE and Treat (treat should be exact as it is not pulled form population)
sum treat y_* te 

global outcome_pre "y_pre"
global outcome_post "y_post"
global treatment "treat"

local power = 0.8																
local nratio = 1																
local alpha = 0.05																

quietly sum $outcome_pre   										
local sd = `r(sd)'
local baseline = `r(mean)'

quietly sum $outcome_post					       					
local treat = `r(mean)'

* Compute required sample size for 80% power to detect a 0.1 SD difference:
power twomeans `baseline' `treat', power(`power') sd(`sd') nratio(`nratio') table

local effect = round(r(delta), .01)

local samplesize = r(N)


di as error "The required sample size needed is `samplesize' to detect an effect size of `effect' sd's with a probability of `power' if the effect is true and the ratio of units in treatment and control is `nratio'"

*This is pretty simple we just need to inflate the sample size by 15%.
local new_samp_size = round(`samplesize'/.85)
local diff = `new_samp_size' - `samplesize'

di as error  "So... we now need `new_samp_size' which is `diff' more respondents than perfect uptake"


* If only 30% receive treatment, the allocation ratio is no longer 1:1.
* Here, nratio = (control sample size)/(treatment sample size) = 0.7/0.3 ≈ 2.333.
local power = 0.8																
local nratio = 2.333																
local alpha = 0.05																

quietly sum $outcome_pre   										
local sd = `r(sd)'
local baseline = `r(mean)'

quietly sum $outcome_post					       					
local treat = `r(mean)'

power twomeans `baseline' `treat', power(`power') sd(`sd') nratio(`nratio') table

local effect = round(r(delta), .01)

local samplesize = r(N)

di as error "The required sample size needed is `samplesize' to detect an effect size of `effect' sd's with a probability of `power' if the effect is true and the ratio of units in treatment and control is `nratio' or 30% treated"

********************************************************************************
* Part Two *********************************************************************
********************************************************************************
* Define a program to simulate cluster data 
* given a number of clusters and cluster size.
capture program drop cluster_sim

program define cluster_sim, rclass
    syntax, clusters(integer) clustersize(integer) rho(real) uptake(real)
    clear
    * Create one observation per cluster (school)
    quietly set obs `clusters'
	local rho_val = `rho'
	local uptake_prop = `uptake'
	local sd_ui = sqrt(`rho_val')
	local sd_uij = sqrt(1-`rho_val')
    * 1. Generate school-level effect u ~ N(0, sqrt(sd_ui))
	quietly gen schoolid = _n
	expand `clustersize'
    quietly by schoolid, sort: gen student = _n
	
	* each school gets the same effect
	quietly by schoolid (student), sort: gen u_i = rnormal(0, `sd_ui') if _n == 1
	quietly by schoolid (student): replace u_i = u_i[1]
	

    * 2. Generate individual-level error e ~ N(0, sqrt(sd_uij)) 
	* so that icc fits what was set
	
    quietly gen u_ij = rnormal(0, sqrt(`sd_uij'))

    * 3. Randomly assign treatment at the school level (50% treated)
	quietly gen rand = rnormal()
	quietly summarize rand, detail 
	local med = r(p50)
    quietly by schoolid: gen treat = (rand <= `med')
	* simulate random uptake if prop = 1 then it perfect compliance :) 
	quietly gen rand1 = rnormal()
	quietly gen uptake_f = (rand1 <= `uptake_prop') if treat == 1

    * 4. For schools in treatment, assign a treatment effect drawn from
	* Uniform(0.15,0.25)
	quietly gen te = 0
    quietly by schoolid: replace te = uptake_f * runiform(0.15,0.25)

    * Generate outcome
	* outcome = intercept + effect*treatment_dummy + cluster_error + individual_error
    quietly gen y = rnormal(50, 15) + u_i + u_ij 
	* by standizing the var we can set .2 to be exactly .2 sd as the new var is ~N(0,1)
	quietly sum y 
	quietly gen y_norm = (y - r(mean)) / r(sd)
	quietly replace y_norm = y_norm + te if treat == 1	
	reg y_norm treat, vce(cluster schoolid)
	
    matrix result = r(table)
    return scalar coef = result[1,1]
    return scalar pval = result[4,1]	
end


* 5. Examine power as cluster size increases (with 200 clusters).
clear
tempfile res
save `res', replace emptyok

display "Testing different cluster sizes (first 10 powers of 2):"
local sizes "1 2 4 8 16 32 64 128 256 512"
foreach cs of local sizes {
	
    simulate coef=r(coef) pval = r(pval), reps(500): ///
	cluster_sim, clusters(200) clustersize(`cs') rho(0.3) uptake(1)
	
	gen samp_size = `cs'
    append using `res'
    save `res', replace 
}

use `res', replace

gen reject_null = 0
replace reject_null = 1 if pval <= 0.05 

tab reject_null samp_size, col

vioplot pval, over(samp_size)

*I would reccomend selecting the sample size of 1600 (i.e 8 per cluster) even 
*though we are able to detect the effect at sig levels for 800 given the potentional 
*for icc to vary its best to make the sample slightly more resliant to this issue. 
*However a larger sample than this would probably be overkill. 


// Step 5: Run simulation over varying cluster sizes
clear
tempfile res1
save `res1', replace emptyok

display "Testing different number of clusters:"
forvalues cs = 50(25)300 {
	
    simulate coef=r(coef) pval = r(pval), reps(500): ///
	cluster_sim, clusters(`cs') clustersize(15) rho(0.3) uptake(1)
	
	gen num_cluster = `cs'
    append using `res1'
    save `res1', replace 
}

use `res1', replace

gen reject_null = 0
replace reject_null = 1 if pval <= 0.05 

tab reject_null num_cluster, col

display "For perfect compliance the sample size of 15 allows us to have 50 clusters with 15 students per school"

* same thing but with partial uptake 
clear
tempfile res1
save `res1', replace emptyok

display "Testing different number of clusters:"
forvalues cs = 50(25)300 {
	
    simulate coef=r(coef) pval = r(pval), reps(500): ///
	cluster_sim, clusters(`cs') clustersize(15) rho(0.3) uptake(.7)
	
	gen num_cluster = `cs'
    append using `res1'
    save `res1', replace 
}

use `res1', replace

gen reject_null = 0
replace reject_null = 1 if pval <= 0.05 

tab reject_null num_cluster, col

display "For partial uptake of .7 we would need 100 clusters with 15 students per school, we can check this math by taking 50 + 1/.7^2 which gives us 102 clusters needed"

********************************************************************************
* Part Three *******************************************************************
********************************************************************************

/*
1.	Develop some data generating process for outcome Y, with some treatment variable and treatment effect. 
2.	This DGP should include strata groups and continuous covariates, as well as random noise. Make sure that the strata groups affect the outcome Y. You will want to create the strata groups first, then use a command like expand or merge to add them to an individual-level data set.
3.	Make sure that at least one of the continuous covariates also affects both the outcome and the likelihood of receiving treatment (a "confounder"). Make sure that another one of the covariates affects the outcome but not the treatment. Make sure that another one affects the treatment but not the outcome. (What do these do?)
4.	Construct at least five different regression models with combinations of these covariates and strata fixed effects. (Type h fvvarlist for information on using fixed effects in regression.) Run these regressions at different sample sizes, using a program like last week. Collect as many regression runs as you think you need for each, and produce figures and tables comparing the biasedness and convergence of the models as N grows. Can you produce a figure showing the mean and variance of beta for different regression models, as a function of N? Can you visually compare these to the "true" parameter value?
5.	Fully describe your results in your README file, including figures and tables as appropriate.
*/

capture program drop strata_sim
program define strata_sim, rclass
    syntax, strata_num(integer) samp_within_strata(integer)
* Create strata-level data
clear
set obs `strata_num'
gen strata = _n
gen strata_effect = rnormal(0, 2) 
expand `samp_within_strata'

gen id = _n
* Continuous covariates
* Split the sample in half 
gen confounder = rnormal(10,1)           // affects both treatment & outcome
gen treat = (confounder <= 10)      // this directly makes treatment connected 
gen outcome_only = rnormal(10,1)         // affects only outcome
gen treatment_only = rnormal(3,1)       // affects only treatment
gen treatment_effect = treatment_only + runiform(2,3)  

* Create out dependent variable
gen y = 5 * outcome_only + 2.1 * confounder + treat * treatment_effect + strata_effect

* Run the regressions 
reg y  confounder treat i.strata
matrix X = r(table)
return scalar coef1 = X[1,1]

reg y confounder outcome_only i.strata
matrix X = r(table)
return scalar coef2 = X[1,1]

reg y confounder outcome_only treat treatment_effect i.strata
matrix X = r(table)
return scalar coef3 = X[1,1]

reg y confounder i.treat##c.treatment_effect i.strata
matrix X = r(table)
return scalar coef4 = X[1,1]

reg y confounder outcome_only i.treat##c.treatment_effect i.strata
matrix X = r(table)
return scalar coef5 = X[1,1]

return scalar samp_size = _N

end 

* We are holding strata num fixed
clear
tempfile res2
save `res2', replace emptyok

forvalues i = 10(25)250 {
    simulate m1=r(coef1) m2=r(coef2) m3=r(coef3) m4=r(coef4) m5=r(coef5)  samp_size = r(samp_size), reps(500): ///
    strata_sim, strata_num(6) samp_within_strata(`i')
	
    append using `res2'
    save `res2', replace 
	
}


* Get both mean and standard deviation
estpost tabstat m1 m2 m3 m4 m5, stat(mean sd) by(samp_size) elabels
estimates store summary

* Export to LaTeX with mean (sd) format
esttab summary using "$wd\week 10\03_assignment\summary_table.tex", ///
    cells("m1(fmt(%9.2f) par(%9.2f)) m2(fmt(%9.2f) par(%9.2f)) m3(fmt(%9.2f) par(%9.2f)) m4(fmt(%9.2f) par(%9.2f)) m5(fmt(%9.2f) par(%9.2f))") ///
    unstack varlabels(`e(labels)') nonumb noobs ///
    replace fragment
	
* true effect is 2.1 
vioplot m1, over(samp_size)  horizontal title("Violin Plot of Confounder Beta") subtitle("By sample size (True Effect = 2.1)") ylabel(, angle(0))

graph export "$wd\week 10\03_assignment\vioplot_beta.png"

twoway ///
    (kdensity m1 if samp_size == 60, lcolor(blue) lpattern(solid)) ///
    (kdensity m1 if samp_size == 360, lcolor(black) lpattern(solid)) ///
    (kdensity m1 if samp_size == 660, lcolor(green) lpattern(solid)) ///
    , xline(2.1, lcolor(red) lpattern(dash)) ///
      legend(label(1 "60") label(2 "360") label(3 "660")) ///
      title("Beta Estimates of Y = confounder + treat + strata_fixed effects")
  
graph export "$wd\week 10\03_assignment\density.png"


** Finsihed 



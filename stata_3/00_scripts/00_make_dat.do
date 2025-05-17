*00_make_dat

cd "$wd\stata_3"

clear all
set more off
set seed 08111998

* Create a fixed population of 10,000 observations
set obs 10000

* Generate X from a standard normal distribution
gen X = rnormal()

* Generate error term from a standard normal distribution
gen error = rnormal()

* Generate Y with a true coefficient of 2 on X
gen Y = 2*X + error


* Save the fixed population dataset to your Box folder
save "01_data\total_pop.dta", replace



*set wd dynamically 


if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="eman7" { 
	
	global wd "C:\Users\eman7\Dropbox\ppol6818" 
}

********************************************************************************
*IF PACKAGES NOT INSTALLED PLEASE INSTALL BELOW BY UNCOMMENTING
********************************************************************************
********************************************************************************
*ssc install reclink
*ssc install cluster 
********************************************************************************

*set globals 

global q5_school_location "$wd\week_05\03_assignment\01_data\q5_school_location.dta"
global tz_elec_10_clean "$wd\week_05\03_assignment\01_data\Tz_elec_10_clean.dta"
global tz_elec_15_clean "$wd\week_05\03_assignment\01_data\Tz_elec_15_clean.dta"
global tz_gis "$wd\week_05\03_assignment\01_data\Tz_GIS_2015_2010_intersection.dta"
global q1_psle_raw "$wd\week_05\03_assignment\01_data\q1_psle_student_raw.dta"
global civ_popden "$wd\week_05\03_assignment\01_data\q2_CIV_populationdensity.xlsx"
global civ_section_0 "$wd\week_05\03_assignment\01_data\q2_CIV_Section_0.dta"
global q3_gps "$wd\week_05\03_assignment\01_data\q3_GPS Data.dta"
global tz_elec_10_raw "$wd\week_05\03_assignment\01_data\q4_Tz_election_2010_raw.xls"
global tz_elec_temp "$wd\week_05\03_assignment\01_data\q4_Tz_election_template.dta"
global q5_psle_data "$wd\week_05\03_assignment\01_data\q5_psle_2020_data.dta"


************************
*PPOL6818 Stata 2
************************
*Ethan Sager
************************

*Q1 (Builds on Stata 1 Bonus Question) 
use $q1_psle_raw, replace 

rename s rawdata
gen cleaned = rawdata

* Insert a delimiter "|||" before each candidate record.
* We assume candidate records start with "PS01"
replace cleaned = subinstr(cleaned, "PS0", "|||PS0", .)

* Remove everything before the first candidate record delimiter.
local pos = strpos(cleaned, "|||")
if `pos' > 0 {
    replace cleaned = substr(cleaned, `pos' + 3, .)
}

split cleaned, parse("|||")
* This creates variables cleaned1, cleaned2, … cleanedN where each should (ideally) be one candidate record.

drop rawdata cleaned schoolcode

gen id = _n // just becasue stata requires an id in the pivot 
reshape long cleaned, i(id) j(rec_num) string

* Create new variables and extract each group via the regex:
gen schoolcode     = ustrregexs(1) if ustrregexm(cleaned, "(PS\d{7})")
gen cand_id        = ustrregexs(1) if ustrregexm(cleaned, "(PS\d{7}-\d{4})")
gen prem_number    = ustrregexs(1) if ustrregexm(cleaned, "(\d{11})")
gen gender         = ustrregexs(1) if ustrregexm(cleaned, ">([MF])<")
gen name           = ustrregexs(1) if ustrregexm(cleaned, "<P>(.*?)</FONT>")
gen grade_kiswahili= ustrregexs(1) if ustrregexm(cleaned, "Kiswahili\s*-\s*([A-Z])")
gen grade_english  = ustrregexs(1) if ustrregexm(cleaned, "English\s*-\s*([A-Z])")
gen grade_maarifa  = ustrregexs(1) if ustrregexm(cleaned, "Maarifa\s*-\s*([A-Z])")
gen grade_hisabati = ustrregexs(1) if ustrregexm(cleaned, "Hisabati\s*-\s*([A-Z])")
gen grade_science  = ustrregexs(1) if ustrregexm(cleaned, "Science\s*-\s*([A-Z])")
gen grade_uraia    = ustrregexs(1) if ustrregexm(cleaned, "Uraia\s*-\s*([A-Z])")
gen grade_average  = ustrregexs(1) if ustrregexm(cleaned, "Average Grade\s*-\s*([A-Z])")

* Drop the temporary variable holding the full candidate text.
drop cleaned* id rec_num

* Given the mismatch kinda extra rows will show up just drop
keep if !missing(cand_id)
* Order variables as desired:
order schoolcode cand_id prem_number gender name grade_kiswahili grade_english grade_maarifa grade_hisabati grade_science grade_uraia grade_average

* Q2 Côte d'Ivoire Population Density
import excel using "$civ_popden", clear 
* drop first row 
keep if _n > 1

* clean the string so that we can make sure it matches 
gen b06_departemen = strlower(A)
rename D pop_den 

drop A B C 

* may make more sense to take mean or median value of the dupes 
duplicates drop b06_departemen, force

* fix the issue with str 
preserve 

use "$civ_section_0", clear  
tempfile fix
decode b06_departemen, gen(b06)
drop b06_departemen
rename b06 b06_departemen
save `fix'

restore  

* Merge using the corrected temp dataset
merge 1:m b06_departemen using `fix'

drop if hh1 == . 

* Q3 
use "$q3_gps", replace 

* Set seed for reproducibility
set seed 145678

* Store the target number of enumerations
scalar target_enum = 6 
scalar best_enum_diff = . 
scalar best_enum_iteration = .

* Loop for 1000 iterations of K-means since the starting point is random assignments will vary for each iteration 
forval i = 1/1000 {
    cluster kmeans latitude longitude, k(19) name(enum_`i')
    bysort enum_`i': generate cluster_size_`i' = _N
    qui su cluster_size_`i', meanonly
    scalar enum_diff = abs(r(mean) - target_enum)

    * If this iteration has a smaller difference, keep it
    if missing(best_enum_diff) | enum_diff < best_enum_diff {
        scalar best_enum_diff = enum_diff
        scalar best_enum_iteration = `i'
        tempfile best_enum_results
        save `best_enum_results', replace 
    }
}

* Load the best result
use `best_enum_results', clear
display best_enum_iteration
local num = best_enum_iteration
keep latitude longitude id age female enum_`num' cluster_size_`num'
rename enum_`num' enum
* Display summary of the clusters assigned 
tabulate enum

* Q4 more data clenaing 
import excel using "$tz_elec_10_raw", clear

* drop g and k col not needed 
drop G K

* fix names 
foreach var of varlist * {
    rename `var' `=strtoname(`var'[5])'
}


* drop extra crap from header in excel 
drop if _n < 7


* fill down REGION DISTRICT COSTIT WARD 
foreach var in REGION DISTRICT COSTITUENCY WARD {
    replace `var' = `var'[_n-1] if `var' == ""
}

* now we can get totals of votes and  by ward 
replace TTL_VOTES = "" if TTL_VOTES == "UN OPPOSSED"
destring TTL_VOTES, replace 
bysort WARD: egen total_votes = total(TTL_VOTES)
bysort WARD: gen total_cands = _N

keep REGION DISTRICT COSTITUENCY WARD POLITICAL_PARTY TTL_VOTES total_votes total_cands

duplicates drop
* make a new ward_id var so tahat we can pivot the data as some wards match names across regions 
egen id = group(REGION DISTRICT COSTITUENCY WARD)

* pivot longer but first make pol par pretty 
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, "-", "_", .)
replace POLITICAL_PARTY = subinstr(POLITICAL_PARTY, " ", "", .)

* first retain the info we should merge back form main file 
preserve
keep REGION DISTRICT COSTITUENCY WARD total_votes total_cands id
duplicates drop
tempfile extras
save `extras'
restore

collapse (sum) TTL_VOTES, by(id POLITICAL_PARTY)

reshape wide TTL_VOTES, i(id) j(POLITICAL_PARTY) string 

merge 1:1 id using `extras'

order REGION DISTRICT COSTITUENCY WARD total_votes total_cands id TTL*

rename id ward_id
rename TTL_VOTES* votes_*
rename *, lower 
drop _merge

* Q5 
use $q5_psle_data, replace 

gen NECTACentreNo  = trim(ustrregexs(1)) if ustrregexm(schoolname, "(PS\d{7})")
gen pos = strpos(lower(schoolname), "primary school")
gen School = trim(substr(schoolname, 1, pos - 1)) if pos > 0
replace School = schoolname if pos == 0
gen schoolcode_check = ustrregexs(1) if ustrregexm(school_code_address, "(ps\d{7})")
replace schoolcode_check = strupper(schoolcode_check)
rename district_name Council 

replace Council = regexr(Council, "\s*\([^)]*\)", "")
replace Council = regexr(Council, "\s+(CC|TC|MC)$", "")

duplicates list NECTACentreNo Council School
duplicates drop NECTACentreNo, force
*next we need 

preserve
tempfile merge_dat
use $q5_school_location, clear
tab NECTACentreNo  if NECTACentreNo == "n/a"
replace Council = upper(Council)
drop if NECTACentreNo == "n/a"
replace Council = regexr(Council, "\s*\([^)]*\)", "")
replace Council = regexr(Council, "\s+(CC|TC|MC)$", "")
duplicates list NECTACentreNo Council School
duplicates drop NECTACentreNo Council School, force
duplicates drop NECTACentreNo, force
save `merge_dat'
restore 

merge 1:1 NECTACentreNo using `merge_dat'
drop if _merge == 2

* the above works better than linking by school name however we don't know for sure if ps codes are consistent across the whole data universe but we don't improve using reclink below so we retain the above workaround.

*this lets us get a cleaner school name for misspellings 

// preserve
// tempfile merge_fix
// keep if _merge != 3 
//
// reclink School using `merge_dat', idm(serial) idu(SN) gen(myscore)
// bysort NECTACentreNo Council School (myscore): gen max_myscore = _n == _N | missing(myscore)
// keep if max_myscore == 1
// drop School myscore-_merge
// rename USchool School 
//
//
// merge 1:1 NECTACentreNo Council School using `merge_dat'
//
//
// keep if !missing(region_name)

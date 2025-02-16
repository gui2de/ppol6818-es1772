*set wd dynamically 


if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="eman7" { 
	
	global wd "C:\Users\eman7\Dropbox\ppol6818" //this would your ppol_6818 folder address
}


*set globals 
global q1_school "$wd\week_03\04_assignment\01_data\q1_data\school.dta"
global q1_teacher "$wd\week_03\04_assignment\01_data\q1_data\teacher.dta"
global q1_student "$wd\week_03\04_assignment\01_data\q1_data\student.dta"
global q1_subject "$wd\week_03\04_assignment\01_data\q1_data\subject.dta"
global q2_village "$wd\week_03\04_assignment\01_data\q2_village_pixel.dta"
global q3_proposal "$wd\week_03\04_assignment\01_data\q3_proposal_review.dta"
global excel_t21 "$wd//week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"
global q5_html "$wd\week_03\04_assignment\01_data\q5_Tz_student_roster_html.dta"

************************
*PPOL6818 Stata 1
************************
*Ethan Sager
************************


/*
Q1: As part of a larger examination of how various factors contribute to student achievement, you have been asked to find a couple of pieces of information about a school district. Unfortunately, the relevant data is spread across four different files (student.dta, teacher.dta, school.dta, and subject.dta all in the following subfolder: q1_data. See the readme file for more details regarding each dataset.
*/

use $q1_student, replace  
rename primary_teacher teacher 

merge m:1 teacher using $q1_teacher
drop _merge
merge m:1 school using $q1_school
drop _merge
merge m:1 subject using $q1_subject
drop _merge

*fin now calc

*(a) What is the mean attendance of students at southern schools?
sum attendance if loc == "South"

* The mean is 177.48

*(b) Of all students in high school, what proportion of them have a primary teacher who teaches a tested subject?

count if tested == 1 & level == "High"
local tested_count = r(N)

count if level == "High"
local high_count = r(N)

display `tested_count' / `high_count'

*44.23% of high school students have primary teacher who teaches a tested subject 

*(c) What is the mean gpa of all students in the district?

sum gpa

* The mean is 3.6

*(d) What is the mean attendance of each middle school? 

egen mean_attendance = mean(attendance), by(school)  

tab school mean_attendance if level == "Middle"

*Q2: You are working on a crop insurance project in Kenya. For each household, we have the following information: village name, pixel and payout status.




use $q2_village, replace

*a)	Payout variable should be consistent within a pixel, confirm if that is the case. Create a new dummy variable (pixel_consistent), this variable =0 if payout variable isn't consistent within that pixel (i.e. =1 when all the payouts are exactly the same, =0 if there is even a single different payout in the pixel) 
bysort pixel: gen pixel_consistent = (payout[_N] == payout[1])

tab pixel_consistent
*yep that is correct 

*b)	Usually the households in a particular village are within the same pixel but it is possible that some villages are in multiple pixels (boundary cases). Create a new dummy variable (pixel_village), =0 for the entire village when all the households from the village are within a particular pixel, =1 if households from a particular village are in more than 1 pixel. Hint: This variable is at village level.

egen check = tag(village pixel)
egen ndistinct_vil = total(check), by(village)
gen pixel_village = (ndistinct_vil > 1)
drop check ndistinct_vil // these were just needed to count 
list village if pixel_village == 1

/* c)	For this experiment, it is only an issue if villages are in different pixels AND have different payout status. For this purpose, divide the households in the following three categories:
i.	Villages that are entirely in a particular pixel. (==1)
ii.	Villages that are in different pixels AND have same payout status (Create a list of all hhids in such villages) (==2)
iii.	Villages that are in different pixels AND have different payout status (==3)
Hint: These 3 categories are mutually exclusive AND exhaustive i.e. every single observation should fall in one of the 3 categories. Note also that the categories may or may not line up with what you created in (a) and (b) so read the instructions closely.
*/

gen payout_issue = 0 
replace payout_issue = 1 if pixel_village == 0
egen check_pay = tag(village payout)
egen ndistinct_pay = total(check_pay), by(village)
replace payout_issue = 2 if pixel_village == 1 & ndistinct_pay == 1
replace payout_issue = 3 if pixel_village == 1 & ndistinct_pay > 1
drop check_pay ndistinct_pay // these were just needed to count 
list hhid if payout_issue == 2


/*Q3: Faculty members submitted 128 proposals for funding opportunities. Unfortunately, we only have enough funding for 50 grants. Each proposal was assigned randomly to three selected reviewers who each gave a score between 1 (lowest) and 5 (highest). Each person reviewed 24 proposals and assigned a score. We think it will be better if we normalize the score wrt each reviewer (using unique ids) before calculating the average score. Add the following columns 1) stand_r1_score 2) stand_r2_score 3) stand_r3_score 4) average_stand_score 5) rank (Note: highest score =>1, lowest => 128)
Hint: We can normalize scores using the following formula: (score – mean)/sd, where mean = mean score of that particular reviewer (based on the netid), sd = standard deviation of scores of that particular reviewer (based on that netid). (Hint: we are not standardizing the score wrt reviewer 1, 2 or 3. But by the netID.)
*/

use $q3_proposal, replace 

*issue with naming conventions 
rename Review1Score ReviewerScore1
rename Reviewer2Score ReviewerScore2
rename Reviewer3Score ReviewerScore3

rename Rewiewer1 Reviewer1

reshape long Reviewer ReviewerScore, i(proposal_id) j(rev_num)

egen mean_score_netid = mean(ReviewerScore), by(Reviewer)
egen sd_score_netid = sd(ReviewerScore), by(Reviewer)
gen stand_score = (ReviewerScore - mean_score_netid) / sd_score_netid
drop mean_score_netid sd_score_netid

reshape wide Reviewer ReviewerScore stand_score, i(proposal_id) j(rev_num)


rename ReviewerScore1 Reviewer1Score
rename ReviewerScore2 Reviewer2Score
rename ReviewerScore3 Reviewer3Score

rename stand_score1 stand_r1_score
rename stand_score2 stand_r2_score
rename stand_score3 stand_r3_score

egen average_stand_score = rowmean(stand_r1_score stand_r2_score stand_r3_score)
egen rank = rank(-average_stand_score), unique

/*Q4: We have the information of adults that have computerized national ID card in the following pdf: Pakistan_district_table21.pdf. This pdf has 135 tables (one for each district). We extracted data through an OCR software but unfortunately it wasn't very accurate. We need to extract column 2-13 from the first row ("18 and above") from each table. Create a dataset where each row contains information for a particular district. The hint do file contains the code to loop through each sheet, you need to find a way to align the columns correctly.
*/


clear
tempfile table21
save `table21', replace emptyok

*Run a loop through all the excel sheets (135) this will take 1-5 mins because it has to import all 135 sheets, one by one
forvalues i=1/135 {
	import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring //import
	display as error `i' //display the loop number

// 	gen district_temp = ""
//
// 	foreach var of varlist _all {
// 		quietly replace district_temp = trim(`var') ///
// 			if missing(district_temp) & strpos(upper(`var'), "DISTRICT") > 0
// 	}
//
// 	gen district_found = ""
// 	replace district_found = regexs(1) if regexm(district_temp, "^(.*DISTRICT)")
//
// 	preserve
// 		keep if !missing(district_found)
// 		keep in 1
// 		local final_district = district_found[1]
// 	restore

	keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND" )==1 //keep only those rows that have "18 AND"
	*I'm using regex because the following code won't work if there are any trailing/leading blanks
	*keep if TABLE21PAKISTANICITIZEN1== "18 AND" 
	keep in 1 //there are 3 of them, but we want the first one

	
// 	gen district = "`final_district'"
// 	replace district = "Not found" if district == ""
// 	*handle districts not named district 
// 	drop district_temp district_found
	
	foreach var of varlist _all {
		*fix the multiple ---'s 
		if substr(trim(`var'), 1, 1) == "-" {
		gen `var'_c = subinstr(`var', " ", "", .)
		gen `var'_1 = subinstr(substr(`var'_c, 1, 1) , "-", "", .)
        gen `var'_2 = subinstr(substr(`var'_c, 2, 1) , "-", "", .)
		gen `var'_3 = subinstr(substr(`var'_c, 3, 1) , "-", "", .)
		drop `var'_c `var'
		continue 
		}
		*fix the trailing - in table 36
		replace `var' = subinstr(`var', "-", "", .)
    }
	
	*Drop cols that are all missing 
	foreach var of varlist _all {
		replace `var' = "" if trim(`var') == ""
		capture assert missing(`var')
		if _rc == 0 drop `var'
	}
	* Since merging is finky in stata just name everything to force clean append
	local newvarnames "table21 all_sexes_total all_sexes_card_obt all_sexes_card_notobt male_total male_card_obt male_card_notobt female_total female_card_obt female_card_notobt transgender_total transgender_card_obt transgender_card_notobt"
	ds // triple check col num 
	local oldvarnames `r(varlist)'
	local nvars : word count `newvarnames'

	forval j = 1/`nvars' {
		local old : word `j' of `oldvarnames'
		local new : word `j' of `newvarnames'
		
		capture confirm variable `old'
		if !_rc {
			display "Renaming: `old' -> `new'"
			rename `old' `new'
		}
		else{
			gen `new' = ""
		}
	}
	
	
	
	* We should have 14 columns 
	describe, short


	gen table=`i' //to keep track of the sheet we imported the data from
	append using `table21'  
	save `table21', replace //saving the tempfile so that we don't lose any data
}

*load the tempfile
use `table21', clear

replace table21 = subinstr(table21, "OVERALL", "", .)

list 

*Q5

global q5_html "$wd\week_03\04_assignment\01_data\q5_Tz_student_roster_html.dta"

use $q5_html, replace 

rename s rawdata

* Extract school name and school code
gen school_name = ustrregexs(1) if ustrregexm(rawdata, "([A-Z\s]+)\s*-\s*(PS\d+)")
gen school_code = ustrregexs(2) if ustrregexm(rawdata, "([A-Z\s]+)\s*-\s*(PS\d+)")

* Extract number of students
gen num_students = real(ustrregexs(1)) if ustrregexm(rawdata, "WALIOFANYA MTIHANI\s*:\s*(\d+)")

* Extract school average
gen school_avg = real(ustrregexs(1)) if ustrregexm(rawdata, "WASTANI WA SHULE\s*:\s*([\d\.]+)")

* Extract student group category (Under 40 or >=40)
gen student_group_str = ustrregexs(1) if ustrregexm(rawdata, "KUNDI LA SHULE\s*:\s*([^<]+)")
gen student_group = (ustrregexm(student_group_str, "chini ya 40") == 0)  // 0 if "chini ya 40", 1 otherwise

* Extract rankings
gen council_rank = real(ustrregexs(1)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI\s*:\s*(\d+)\s+kati ya\s+(\d+)")


gen council_total = real(ustrregexs(2)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI\s*:\s*(\d+)\s+kati ya\s+(\d+)")

gen region_rank = real(ustrregexs(1)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*(\d+)\s+kati ya\s+(\d+)")
gen region_total = real(ustrregexs(2)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*(\d+)\s+kati ya\s+(\d+)")

gen national_rank = real(ustrregexs(1)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*(\d+)\s+kati ya\s+(\d+)")
gen national_total = real(ustrregexs(1)) if ustrregexm(rawdata, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*(\d+)\s+kati ya\s+(\d+)")

* Drop unnecessary variables and show extracted data
drop rawdata student_group_str
list


*say thing for students (Bonus Question) 
use $q5_html, replace 

rename s rawdata
gen cleaned = rawdata
* Insert a delimiter "|||" before each candidate record.
* We assume candidate records start with "PS0101114-"
replace cleaned = subinstr(cleaned, "PS0101114-", "|||PS0101114-", .)

* Remove everything before the first candidate record delimiter.
local pos = strpos(cleaned, "|||")
if `pos' > 0 {
    replace cleaned = substr(cleaned, `pos' + 3, .)
}

split cleaned, parse("|||")
* This creates variables cleaned1, cleaned2, … cleanedN where each should (ideally) be one candidate record.

drop rawdata cleaned
gen id = 1 // just becasue stata requires an id in the pivot 
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

* Order variables as desired:
order schoolcode cand_id prem_number gender name grade_kiswahili grade_english grade_maarifa grade_hisabati grade_science grade_uraia grade_average

* Display the student-level dataset (should have 16 rows)
list, sep(0)


//  /$$$$$$$$ /$$           /$$           /$$                       /$$
// | $$_____/|__/          |__/          | $$                      | $$
// | $$       /$$ /$$$$$$$  /$$  /$$$$$$$| $$$$$$$   /$$$$$$   /$$$$$$$
// | $$$$$   | $$| $$__  $$| $$ /$$_____/| $$__  $$ /$$__  $$ /$$__  $$
// | $$__/   | $$| $$  \ $$| $$|  $$$$$$ | $$  \ $$| $$$$$$$$| $$  | $$
// | $$      | $$| $$  | $$| $$ \____  $$| $$  | $$| $$_____/| $$  | $$
// | $$      | $$| $$  | $$| $$ /$$$$$$$/| $$  | $$|  $$$$$$$|  $$$$$$$
// |__/      |__/|__/  |__/|__/|_______/ |__/  |__/ \_______/ \_______/


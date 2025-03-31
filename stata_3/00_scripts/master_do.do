* Set up wd for jacob 
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="eman7" { 
	
	global wd "C:\Users\eman7\Dropbox\ppol6818" 
}

* just run all files from a master script

********************************************************************************
* Part 1
********************************************************************************
do "$wd\stata_3\00_scripts\00_make_dat.do"
do "$wd\stata_3\00_scripts\01_set_sim.do"
do "$wd\stata_3\00_scripts\02_run_sim.do"
********************************************************************************
* Part 2
********************************************************************************
do "$wd\stata_3\00_scripts\03_set_sim_int.do"
do "$wd\stata_3\00_scripts\04_run_sim_int.do"
********************************************************************************
* Build readme.md  
********************************************************************************
dyntext "$wd\stata_3\00_scripts\README.txt", saving("$wd\stata_3\00_scripts\README.md") replace 
dyndoc "$wd\stata_3\00_scripts\README.md", saving("$wd\stata_3\00_scripts\README.html") replace 

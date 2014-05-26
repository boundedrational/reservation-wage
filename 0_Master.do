clear
graph set print logo off 
graph set print tmargin 1
graph set print lmargin 1
set more off, perm
set emptycells drop


clear
clear matrix
set matsize 800
set memory 4g
set varabbrev on


*********************************************************
************* 		Master File 	*********************
*********************************************************


**********************************
**Change paths********************
**********************************

sysdir set PERSONAL "/Users/feli87/Documents/Daten/Do Files/Beispiele/ado"

global do_path `""/Users/feli87/Dropbox/reservation wage puzzle/0-do/""'

global data_path `""/Users/feli87/Documents/LSE/research projects/Manning Petrongolo/2-data manipulated""'
global prepared_data_path `""/Users/feli87/Dropbox/reservation wage puzzle/2-data manipulated""'
global regressions_path `""/Users/feli87/Dropbox/reservation wage puzzle/3-regressions/""'
global log_path `""/Users/feli87/Documents/LSE/research projects/Manning Petrongolo/4-log files""'

global datum = subinstr(c(current_date)," ","",.)


**********************************
**Run Do-Files********************
**********************************


cd $log_path
cap log close
log using preparation${datum}, replace

cd $do_path
do 1_dataset_preparation

cap log close
cd $log_path
cap log close
log using regressions${datum}, replace

cd $do_path
do 2_regressions

cap log close


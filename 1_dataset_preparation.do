/***********************
*
*
* 	This section prepares the variables for the regression:
*	1. picks the required variables from the underlying data sheets
* 	2. Missing data points are set to missing
*  	3. income variables are discounted with cpi 
*	4. Different benefit categories are combined to create total benefits received variable
*
*
***********************/

cd $data_path

import excel using "elfs age.xls", sheet("15-24") first clear
rename GEOTIME svyyear
destring svyyear, replace
g age_u=24
save unemp_age, replace

import excel using "elfs age.xls", sheet("25-64") first clear
rename GEOTIME svyyear
destring svyyear, replace
g age_u=64
append using unemp_age
rename Deu unempl_age
replace unempl_age=ln(unempl_age)
keep svyyear age_u unemp
save unemp_age, replace

import excel using "elfs sex.xls", sheet("male") first clear
rename GEOTIME svyyear
destring svyyear, replace
g female=0
save unemp_sex, replace

import excel using "elfs sex.xls", sheet("female") first clear
rename GEOTIME svyyear
destring svyyear, replace
g female=1
append using unemp_sex
rename Deu unempl_sex
replace unempl_sex=ln(unempl_sex)
keep svyyear female unemp
save unemp_sex, replace

import excel using "elfs education.xls", sheet("0-2") first clear
rename GEOTIME svyyear
destring svyyear, replace
g isced=0
save unemp_educ, replace

import excel using "elfs education.xls", sheet("3-4") first clear
rename GEOTIME svyyear
destring svyyear, replace
g isced=3
append using unemp_educ
save unemp_educ, replace

import excel using "elfs education.xls", sheet("ISCED 5-6") first clear
rename GEOTIME svyyear
destring svyyear, replace
g isced=5
append using unemp_educ
replace Deu="." if Deu==":"
replace Verei="." if Verei==":"
destring Deut Verei, replace
rename Deu unempl_educ
replace unempl_educ=ln(unempl_educ)
keep svyyear isced unemp
save unemp_educ, replace



//from p-file
use "pl.dta"
keep pid svyyear hid p0281 p0283 p0238 p0208 p0195 p0205 p0198 p0243 p0295 p0316 p0318 p0320 p0387 p0204 p0208 p0239 p0238 p_klas p0237 pc0052 pc0053 pc0050 pc0051 p_nace
save "annual1.dta", replace

//from pkal fil
use "pkal.dta", clear
// f unemp benefits, unemo assistance, h maintanance support, a income, b self employment income, c income from secondary jobs
keep pid svyyear kal2f03 kal2g03 kal2h03 kal2a03 kal2c03 kal2b03
save "annual2.dta", replace	

//from pequiv
use "pequiv.dta"
//wave of first observation, number of children <18, state of residence, cpi index by east/west Germany, gender,  east west indicator,
keep pid svyyear d11107 l11101 y11101 d11102 x11104  l11102 w11105 w11101 e11105
rename e11105 occupation_isco
save "annual3.dta", replace

//from pgen
use "pgen.dta"
//family status, nationality, level of education, employment status, full time expierience, part time experience, unemployment experience
keep pid svyyear pgisced pgfamstd pgmonth pgnation pgemplst  pgexppt pgexpft pgexpue pgnace pgoeffd pgjobch pgerwtyp
rename pgmonth pmonin
save "annual4.dta", replace

//from h-file
use "hl.dta"
//housing benefits, subsistance allowance
keep hid svyyear h2734 h4723  h4744 h2728 h2699
save "annual5.dta", replace

//from ppfad
use ppfad
keep pid gebmon gebjahr sex
save "annual6", replace




/* definition and re-naming of variables*/
//merge source sheets

use annual1, clear
g incomplete_info=0

forvalue i= 2/4 {
merge 1:1 pid svyyear using annual`i'
replace incomplete_info=1 if _merge!=3
drop _merge
}
//fail to match people in 1990/1991 between annual1 & annual2
// lot of observations in pequiv that aren't in the other data sets. People missing entirely from other datasets

//merge houshold level variables
merge m:1 hid svyyear using annual5
// no houshold information on a few people, most of them are the one's that are only in pequiv dataset
save annualvariables, replace
replace incomplete_info=1 if _merge!=3
drop if _m==2
//drops people with only household information

//desired hours
rename p0198 part_time_desired
replace part=. if part==-1
replace part=0 if part==-2


//reservation wage
rename p0204 res_wage
replace res_=. if res_<0

//children number
rename d11107 children 
replace children=. if children<0

//east west indicator
rename l11102 west_indicator
replace west_=0 if west_==2

//CPI (2006 based)
rename y11101 cpi
//inflation not included in dataset for 1990 and 1991. assuming that 
//east and west inflation is the same in 1990 and 1989 
//differential inflation for the two regions used for the following years (until 2000)
replace cpi=65.8/1.0156 if svyyear==1991 & cpi==-2
replace cpi=64.79/1.026 if svyyear==1990 & cpi==-2
replace cpi=cpi/100

//German
gen german=1 if pgnation==1
replace german=0 if german>1
replace german=. if pgnation<0


//work experience
rename pgexpft ft_exp
replace ft=. if ft<0
rename pgexppt pt_exp
replace pt=. if pt<0
replace pgexpu=. if pgexpu<=-1


//Bundesland
rename l11101 land
replace land=. if land<0

//degree level
replace pgisced=. if pgisced<0

//male
g female=0 if d11102==1
replace female=. if d11102<0
replace female=1 if d11102==2
drop d11102

//married
g married= 1 if pgfamstd==1 | pgfamstd==2 | pgfamst==6
replace married=0 if pgfamstd!=1 & pgfamstd!=2 & pgfamst!=6 & pgfamstd>0
drop pgfamstd

//wave of first observation
rename x11104ll wave 

//search & income variables (assumes zero income if question doesn't apply)
foreach i of varlist   p0295 p0316 p0318 p0320 p0387 h2699 h2728 h2734 h4723 h4744 kal2a03 kal2b03 kal2c03 kal2f03 kal2g03 kal2h03 {
replace `i'=0 if `i'==-2 
replace `i'=. if `i'==-3 |`i'==-1
}


//euro conversion
g DM_Euro=1.95583 
foreach i of varlist kal2b03 kal2c03 kal2f03 kal2g03 kal2h03 p0387 {
replace `i'=`i'/DM if svyyear<2002
}
drop DM



//cpi deflation and taking logs for variables that relate to the previous year
foreach i of varlist kal2a03 kal2b03 kal2c03 kal2f03 kal2g03 kal2h03 h4744 h2699 {
g last_l`i'_cpi=ln(`i'/cpi) 
g last_c`i'=`i'/cpi
}


// deflation by different years, because questions are about different years
//requires assumption that people don't move between east and west during 1990-2002

xtset pid svyyear

replace cpi=   .668 if svyyear==1983
replace cpi=    .685 if svyyear==1984
replace cpi=    .699 if svyyear==1985
replace cpi=    .698 if svyyear==1986
replace cpi=    .699 if svyyear==1987
replace cpi=    .708 if svyyear==1988
replace cpi=   .728 if svyyear==1989 
replace cpi=   .747 if svyyear==1990 & land<11 | land==11 & svyyear==1990 & west_==1
replace cpi= .6478929 if svyyear==1990 & land>11 | land==11 & svyyear==1990 & west_==0
replace cpi=   .775 if svyyear==1991 & land<11| land==11 & svyyear==1991 & west_==1
replace cpi=   .658 if svyyear==1991 & land>11 | land==11 & svyyear==1991 & west_==0

replace cpi=   .806 if svyyear==1992 & land<11| land==11 & svyyear==1992 & west_==1
replace cpi=   .746 if svyyear==1992 & land>11| land==11 & svyyear==1992 & west_==0

replace cpi=   .825 if svyyear==1993 & land>11| land==11 & svyyear==1993 & west_==0
replace cpi=  .834 if svyyear==1993 & land<11 | land==11 & svyyear==1993 & west_==1
replace cpi=  .854 if svyyear==1994 & land>11| land==11 & svyyear==1994 & west_==0
replace cpi=  .857 if svyyear==1994 & land<11 | land==11 & svyyear==1994 & west_==1
replace cpi=  .871 if svyyear==1995
replace cpi=  .882 if svyyear==1996 & land>11| land==11 & svyyear==1996 & west_==0
replace cpi=  .888 if svyyear==1996 & land<11 | land==11 & svyyear==1996 & west_==1
replace cpi=  .899 if svyyear==1997 & land>11| land==11 & svyyear==1997 & west_==0
replace cpi=  .907 if svyyear==1998 & land>11| land==11 & svyyear==1998 & west_==0
replace cpi=  .908 if svyyear==1997 & land<11 | land==11 & svyyear==1997 & west_==1
replace cpi=  .913 if svyyear==1999 & land>11| land==11 & svyyear==1999 & west_==0
replace cpi=  .917 if svyyear==1998 & land<11 | land==11 & svyyear==1999 & west_==1
replace cpi=  .921 if svyyear==1999 & land<11 | land==11 & svyyear==1999 & west_==1
replace cpi=  .927 if svyyear==2000
replace cpi=  .945 if svyyear==2001
replace cpi=  .959 if svyyear==2002
replace cpi=  .969 if svyyear==2003
replace cpi=   .985 if svyyear==2004
replace cpi=      1 if svyyear==2005
replace cpi=  1.016 if svyyear==2006
replace cpi=  1.039 if svyyear==2007
replace cpi=  1.066 if svyyear==2008
replace cpi=   1.07 if svyyear==2009
replace cpi=1.082 if svyyear==2010

foreach i of varlist res_wage p0295 p0316 p0318 p0320 p0387 h2728 h2734 h4723  {
g l`i'_cpi=ln(`i'/cpi) 
g c`i'=`i'/cpi 
}


//add unemployment variable
drop _m
merge m:1 svyyear using unemp_data.dta
drop if _m==2
drop _m
merge m:1 svyyear using oecd_agg_unemp.dta
drop if _m!=3
//use west Germany until 1990, from 1991 Germany
g agg_unemp=germanytogether
//replace agg_unemp=west if svyyear<1991
g lagg_unemp=ln(agg_unemp)
drop _m germanytogether //west ost



//new job found
g new_job=0 if p0208==2
replace new_j=1 if p0208==1 | p0208==3
replace new_j=0 if p0208==-2
g new_job_alternative=new_job
replace new_job_alternative=1 if p0238==svyyear
xtset pid svyyear
replace new_job_alternative=1 if p0238==L.svyyear & new_job!=1 & L.new_job_alternative!=1
//pgjobch more accurate then pgerwtyp, since it includes data about first time employment
g job_change=1 if pgjobch>3 & pgjobch!=.
replace job_change=0 if pgjobch==2
replace job_change=0 if pgjobch==1

//generate local unemployment rate variable
g local= baden if land==8
replace local=bay if land==9
replace local=berl if land==11
replace local=brand if land==12
replace local=bre if land==4
replace local=ham if land==2
replace local=hes if land==6
replace local=meckl if land==13
replace local=nieder if land==3
replace local=nord if land==5
replace local=rhein if land==7
replace local=saar if land==10
replace local=sachsen if land==14
replace local=sachsena if land==15
replace local=schles if land==1
replace local=thr if land==16
drop schleswigholstein hamburg niedersachsen bremen nordrheinwestfalen hessen rheinlandpfalz saarland badenwrttemberg ///
 bayern mecklenburgvorpommern brandenburg berlin sachsenanhalt thringen sachsen


g llocal=ln(local)
// there is no unemp data for eastern states in 1990...

//no information for 89 on job start year, but do have info on job change
g job_start_year=p0238 
xtset pid svyyear
replace job_start_year=. if job_start_year<0
//replace job_start_year=svyyear-1 if new_job==1 & job_start_year==.
//replace job_start_year=L.job_start_year if new_job==0 & job_start_year==.
replace job_start_year=svyyear-1 if job_change==1 & job_start_year==.
replace job_start_year=L.job_start_year if job_change==0 & job_start_year==.
//start of job unemp
rename svyyear year
rename job_start_year svyyear
merge m:1 svyyear using oecd_agg_unemp
drop if _m==2
drop _m
g lu_agg_jobstart=germanytogether
replace lu_agg_jobstart=west if svyyear<1991
replace lu_agg_jobstart =ln(lu_agg_jobstart)
merge m:1 svyyear using unemp_data
drop if _m==2
drop _m

g u_jobstart= baden if land==8
replace u_jobstart =bay if land==9
replace u_jobstart =berl if land==11
replace u_jobstart =brand if land==12
replace u_jobstart =bre if land==4
replace u_jobstart =ham if land==2
replace u_jobstart =hes if land==6
replace u_jobstart =meckl if land==13
replace u_jobstart =nieder if land==3
replace u_jobstart =nord if land==5
replace u_jobstart =rhein if land==7
replace u_jobstart =saar if land==10
replace u_jobstart =sachsen if land==14
replace u_jobstart =sachsena if land==15
replace u_jobstart =schles if land==1
replace u_jobstart =thr if land==16
drop schleswigholstein hamburg niedersachsen bremen nordrheinwestfalen hessen rheinlandpfalz saarland badenwrttemberg ///
 bayern mecklenburgvorpommern brandenburg berlin sachsenanhalt thringen sachsen
replace u_jobstart =ln(u_jobstart)
rename svyyear job_start_year
rename year svyyear

//dropping original variables
drop pgnation kal2a03 kal2b03 kal2c03 kal2f03 ///
kal2g03 kal2h03 h4744 h2699 p0295 p0316 p0318 p0320 p0387 h2728 h2734 h4723

xtset pid svyyear

//calculating the total benefits received, using all available data sources (preference given to awnsers about current values, rather than awnsers looking back on last year)
// 16 unemployment insurance, 18 unemployment assistance, 87 last years UI
g ALG1=cp0316 if cp0316>0
replace ALG1=F.cp0387 if ALG1==. & F.cp0387!=.
replace ALG1=F.last_ckal2f03 if ALG1==. & F.last_ckal2f03!=.

g ALG2=ch4723 if ch4723!=.
replace ALG2=F.last_ch4744 if ALG2==. & F.last_ch4744!=.

g housingb=ch2728 if ch2728!=.
replace housingb=F.last_ch2699 if housingb==.

g socialassis=ch2734

g unempassis=cp0318 if cp0318!=.
replace unempassis=F.last_ckal2g03 if unempassis==.

g maintenance_allowance=cp0320
replace maintenance_=F.last_ckal2h03 if maintenance_==.

egen benefit= rowtotal(maintenance unempassis socialassis housing ALG2 ALG1) if incomplete_info!=1, missing
//to avoid loosing all observations that don't receive benefits we add 1 before taking logs
g lbenefit= ln(benefit+1)

//age
merge m:1 pid using annual6
drop if _m==2
replace incomplete_info=1 if _m!=3
drop _m
g age=svyyear-gebj if gebj>1000
replace age=age-1 if pmonin<gebmon & age!=.
replace age=age-1 if pmonin<=6 & gebmon<0 & age!=.
g age2= age*age/10

//group specific unemp
merge m:1 svyyear female using unemp_sex
drop if _m==2
drop _m
g age_u=24 if age<25
replace age_u=64 if age<65 & age>24
merge m:1 svyyear age_u using unemp_age
drop if _m==2
drop _m
g isced=0 if pgisced<3
replace isced=3 if pgisced>2 & pgisced<5
replace isced=5 if pgisced>4 & pgisced!=.
merge m:1 svyyear isced using unemp_educ
drop if _m==2
drop _m

save annualpremerge, replace


/************************************************************************
*****																*****
***** 					INSTRUMENTS									*****
*****																*****
***** Creates the instruments for benefit received 					*****
***** by calculating monthly discontinuities in the benefit system. *****
*****																*****
*************************************************************************/




****************************************
********** Import SOEP Data ************
****************************************
use pkal
keep pid hid svyyear kal1a0* kal1b0* kal1c0* kal1d0* kal1e0* kal1f0* kal1g0* ///
kal1h0* kal1i0* kal1j0* kal1n0* kal1m0* kal1k0*

drop kal1a01 kal1b01 kal1c01 kal1d01 kal1e01 kal1f01 kal1g01 kal1h01 kal1i01 ///
kal1j01 kal1n01 kal1n02 kal1a02 kal1b02 kal1c02 kal1d02 kal1e02 kal1f02 kal1g02 ///
kal1h02 kal1i02 kal1j02 kal1m01 kal1m02 kal1k01 kal1k02

forvalue i=10/12 {
rename kal1a0`i' kal1a00`i'
rename kal1b0`i' kal1b00`i'
rename kal1c0`i' kal1c00`i'
rename kal1d0`i' kal1d00`i'
rename kal1e0`i' kal1e00`i'
rename kal1f0`i' kal1f00`i'
rename kal1g0`i' kal1g00`i'
rename kal1h0`i' kal1h00`i'
rename kal1i0`i' kal1i00`i'
rename kal1j0`i' kal1j00`i'
rename kal1k0`i' kal1k00`i'
rename kal1n0`i' kal1n00`i'
rename kal1m0`i' kal1m00`i'
}
reshape long kal1a00 kal1b00 kal1c00 kal1d00 kal1e00 kal1f00 kal1g00 kal1h00 ///
kal1i00 kal1j00 kal1n00 kal1k00 kal1m00, i(pid svyyear) j(month)
//questions about last year in this file, hence correct year variable
replace svyyear=svyyear-1
save monthly1, replace

//find out about time before SOEP was joined and put in format of dataset
use pbiospe 
keep persnr spelltyp spellnr zensor spellinf kalyear beginy endy
g duration= endy-beginy
replace duration=duration+1
expand duration
sort persnr spellnr
g start= spellnr!=spellnr[_n-1] | persnr!=persnr[_n-1]
g svyyear= beginy if start==1
bysort persnr spellnr: replace svyyear=svyyear[_n-1]+1 if svyyear==.
rename persnr pid
duplicates  tag pid svyyear, g(position_pa)
g insur= spelltyp>1 & spellt<6 
bysort pid svyyear position_pa: egen detect= sum(insur) if position_pa>0
//find out how many spells a person had in a year with spells>1
replace position_pa=position_pa+1
bysort pid svyyear: egen position_insu_pa=total(insur)
drop if insu==0 & detect!=. & spelltyp!=6
duplicates  tag pid svyyear, g(dup)
bysort pid svyyear dup: egen unemp= sum(spellt==6)
drop if dup>0 & unemp==1 & spellt!=6
drop dup
duplicates  tag pid svyyear, g(dup)
bysort pid svyyear dup: egen wehr= sum(spellt==3)
drop if dup>0 & wehr==1 & spellt!=3
drop dup 
duplicates  tag pid svyyear, g(dup)
bysort pid svyyear dup: egen training= sum(spellt==2)
drop if dup>0 & train==1 & spellt!=2
drop dup 
duplicates  tag pid svyyear, g(dup)
bysort pid svyyear dup: egen part= sum(spellt==5)
drop if dup>0 & part==1 & spellt!=5
drop dup 
duplicates  tag pid svyyear, g(dup)
bysort pid svyyear dup: egen full= sum(spellt==4)
drop if dup>0 & full==1 & spellt!=4
keep pid svyyear endy insur position_pa position_insu_pa spelltyp
replace insur=. if spelltyp==99
save monthly2, replace

use pequiv
keep pid d11104 d11107  svyyear 
g not_married = d11104>1 & d11104<5 
rename d11107 children
save monthly3, replace

use pgen
keep pid svyyear pgmonth  //month of interview
rename pgmonth pmonin
save monthly4, replace

use ppfad
keep pid gebmon gebjahr sex //variables to calculate age
save monthly5, replace



****************************************
***** Merging sheets  ******************
****************************************

use monthly1
forvalue i=2/4 {
merge m:1 pid svyyear using monthly`i'
rename _m joinin`i'
}
drop if joinin3==2
merge m:1 pid  using monthly5, keep(match master)
drop _m
g help=12
expand help if joinin2==2
g run=1
bysort pid svyyear: replace month=sum(run) if joinin2==2
drop help run
drop if insur==. & joinin2==2

save IV_dataprep.dta, replace
*****************************************
** Generating Discontinuity variables  **
*****************************************

use IV_dataprep.dta, clear
//calculating work months of unemployment insurance contribution payments
gen date = ym(svyyear, month)
drop if date<ym(1976,1)
format date %tm

//changing no-observation to -2
replace kal1d=-2 if kal1d==-3
replace kal1d=-2 if kal1d==-1

//insurance claims accumulation
g insured=1 if kal1n00!=1 & kal1d!=1 & kal1a00==1 | kal1n00!=1 & kal1d!=1 & kal1a==8 | kal1n00!=1 & kal1d!=1 & kal1b==1 | kal1c==1 | kal1h==1 | kal1f==1
replace insured=0 if kal1a00!=8 & kal1a00!=1 & kal1b!=1 & kal1c!=1 & kal1h!=1 & kal1f!=1 
//kal1a==8 is full time work in institution for handicaped people, 1 is full-time work, kal1b part-time, kal1n mini job, 
// c=voc. trainig, d=unemp, e=pensioner, f=maternity, g=university, h=military service, i=household, j=other, k=short time work, m=training, n=mini job
replace insured=0 if kal1d==1
replace insured=0 if kal1n==1
replace insured=insured+insur if joinin2==2 
// for people with several positions in a year before joining SOEP assume 
// that insured if one of the positions yields insurance

//unemployed dummy
xtset pid date
g unemp=1 if kal1d==1
replace unemp=0 if kal1d==-2
replace unemp=1 if joinin2==2 & spelltyp==6
replace unemp=0 if joinin2==2 & spelltyp!=6
g begin_unemp=1 if L.unemp==0 & unemp==1 & pid==L.pid & date-1==L.date //define start of an unemployment spell

//spell definition & survey re-entry
//define events that are problematic, always one if annual data records unemployed and monthly not available
g problem=1 if  date-1!=date[_n-1] & pid==pid[_n-1] |  unemp==1 
bysort pid: g problem_spell=sum(problem)
bysort pid problem_spell: g entit=sum(insured)  


//calculate entitelment periods
xtset pid date
foreach i of numlist 24 36 48 72 84{
g  x`i'=entit-L`i'.entit if problem_spell==L`i'.problem_spell & pid==L`i'.pid & date-`i'==L`i'.date
}
//fill in gaps at the start of a spell if there exist previous spells that allow for long enough observation of indidvidual
foreach i of numlist 24 36 48 72 84{
replace x`i'=entit if pid==pid[_n-`i'] & date-`i'==date[_n-`i'] & x`i'==. 
}


//unemployment length
g count_dummy=1 if  date-1!=date[_n-1] & pid==pid[_n-1] | begin_unemp==1
bysort pid: g survey_spell=sum(count_dummy)
bysort pid survey_spell: g length=sum(unemp)
replace length=0 if unemp==0

//non-employment length
xtset pid date
g gap=  date-1!=date[_n-1] & pid==pid[_n-1]
bysort pid: g gap_spell= sum(gap)
xtset pid date
g non_emp_start= insured==0 & L.insured==1
bysort pid: g non_emp_spell= sum(non_emp_start)
g non_emp= insured==0
bysort pid non_emp_spell gap_spell: g non_emp_length = sum(non_emp)
bysort pid non_emp_spell gap_spell: g first_spell=sum(gap)
drop non_emp non_emp_start non_emp_spell gap gap_spell
replace non_emp_length=non_emp_length/12

//age

drop if gebj<0
g age=svyyear-gebj 
replace age=age-1 if month<gebm
replace age=age-1 if month<=6 & gebm<0
g calcage=age if begin_==1 //age to base unemp-assist calcualtion on
xtset pid date
replace calcage=L.calcage if calcage==. & L.calcage!=. & pid==L.pid & survey_spell==L.survey_spell

drop if joinin2==2


// benefit dummies entitle dummies
//Dummies for discontinuities
replace x84=x72 if x72>=72 & kal1d==1 & x84==. //more than 72 months of entitelment don't yield any benefits, hence doesn't matter if there were more
replace entit=L.entit if kal1d==1
replace x84=L.x84 if kal1d==1
replace x72=L.x72 if kal1d==1
replace x48=L.x48 if kal1d==1
replace x36=L.x36 if kal1d==1
replace x24=L.x24 if kal1d==1
g entitle_UI=1 if x24>=12 & date>ym(2006,1) & x24!=.
replace entitle_UI=0 if date<ym(2006,2)
replace entitle_UI=0 if x24<12 & x24!=.
g entitle_UI2=1 if x36>=12 & date>=ym(1987,7) & date<ym(2006,2) & x36!=.
replace entitle_UI2=0 if x36<12
replace entitle_UI2=0 if date<ym(1987,7) | date>ym(2006,1)
g entitle_UI3=1 if x48>=12 & date<ym(1987,7) & x48!=.
replace entitle_UI3=0 if x48<12
replace entitle_UI3=0 if date>ym(1987,6)


// entitelment length
//rules 1.83-6.87
g lend4old83=12 if date<ym(1987,7) & x84>=36 &  x84!=.  & kal1d==1 
replace lend4old83=0 if x84>42 & calcage>48 & date>=ym(1985,1) & date<=ym(1985,12)
replace lend4old83=0 if x84>42 & calcage>=44 & date>=ym(1986,1)
g lend3old83=10 if date<ym(1987,7) & x84>=30 & x84!=.  & kal1d==1
replace lend3old83=0 if x84>=36
g lend2old83=8 if date<ym(1987,7) & x84!=. & x84>=24 & x84<30  & kal1d==1 
replace lend2old83=0 if x84>=30
g lend1old83=6  if date<ym(1987,7) & x84!=. & x84>=18  & kal1d==1 
replace lend1old83=0 if x84>=24
g lend0old83=4 if date<ym(1987,7) & x84!=. & x84>=12  & kal1d==1 
replace lend0old83=0 if x84>=18


//rules 1.86-6.87
g lend6old86=24 if x84>=72 & date>ym(1985,12) & date<ym(1987,7) & x84!=.  & kal1d==1 & calcage>=54
g lend5old86=22 if x84>=66 &  date>ym(1985,12) & date<ym(1987,7) & x84!=. & kal1d==1 & calcage>=54 
replace lend5old86=0 if x84>=72 & calcage>=54
g lend4old86=20 if x84>=60 &  date>ym(1985,12) & date<ym(1987,7) & x84!=.  & kal1d==1 & calcage>=49 
replace lend4old86=0 if x84>=66 & calcage>=54
g lend3old86=18 if x84>=54 &  date>ym(1985,12) & date<ym(1987,7) & x84!=.  & kal1d==1 & calcage>=49 
replace lend3old86=0 if x84>=60 & calcage>=49
g lend2old86=16 if x84>=48 & date>ym(1985,12) & date<ym(1987,7) & x84!=.  & kal1d==1 & calcage>=44 
replace lend2old86=0 if x84>=54 & calcage>=49
g lend1old86=14 if x84>=42 & date>ym(1985,12) & date<ym(1987,7) & x84!=. & kal1d==1 & calcage>=44 
replace lend1old86=0 if x84>=48 & calcage>=44

//rules 1.85-12.85
g lend3old85=18 if x84>=54 &  date>ym(1984,12) & date<ym(1986,1) & x84!=. &  kal1d==1 & calcage>=49
g lend2old85=16 if x84>=48 &  date>ym(1984,12) & date<ym(1986,1) & x84!=. &  kal1d==1 & calcage>=49
replace lend2old85=0 if x84>=54 & calcage>=49
g lend1old85=14 if x84>=42 & date>ym(1984,12) & date<ym(1986,1) & x84!=. &  kal1d==1 & calcage>=49 
replace lend1old85=0 if x84>=48 & calcage>=49

//rules 7.87-3.97
//age >54
g lend1old87=32 if x84>=64 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=54
g lend2old87=30 if x84>=60 & x84<64 & date>ym(1987,6) & date<ym(1997,4) & x84!=. &  kal1d==1 & calcage>=54
g lend3old87=28 if x84<60 & x84>=56 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=54
//age >49
g lend4old87=26 if  x84>=52 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=49 
replace lend4old87=0 if calcage>=54 & x84>=56
g lend5old87=24 if  x84>=48 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=49 
replace lend5old87=0 if calcage>=49 & x84>=52
//age >44
g lend6old87=22 if  x84>=44 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=44 
replace lend6old87=0 if calcage>=49 & x84>=48
g lend7old87=20 if  x84>=40 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=44
replace lend7old87=0 if calcage>=44 & x84>=44
//age >42
g lend8old87= 18 if x84>=36 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=42 
replace lend8old87=0 if calcage>=44 & x84>=40
g lend9old87= 16 if x84>=32 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=42 
replace lend9old87=0 if calcage>=42 & x84>=36
g lend10old87=14 if x84>=28 & date>ym(1987,6) & date<ym(1997,4) & x84!=. & kal1d==1 & calcage>=42
replace lend10old87=0 if calcage>=42 & x84>=32

//rules 4.97-1.06
//age >57
g lend1old97= 32 if x84>=64 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=57
g lend2old97= 30 if x84<64 & x84>=60 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=57
g lend3old97= 28 if x84<60 & x84>=56 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=57 
//age >52
g lend4old97= 26 if x84>=52 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=52 
replace lend4old97=0 if calcage>=57 & x84>=56
g lend5old97= 24 if x84>=48 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=52 
replace lend5old97=0 if calcage>=52 & x84>=52
//age >47
g lend6old97=22 if  x84>=44 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=47 
replace lend6old97=0 if calcage>=52 & x84>=48
g lend7old97=20 if x84>=40 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=47 
replace lend7old97=0 if calcage>=47 & x84>=44
//age >45
g lend8old97= 18 if  x84>=36 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=45 
replace lend8old97=0 if calcage>=47 & x84>=40
g lend9old97= 16 if  x84>=32 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=45 
replace lend9old97=0 if calcage>=45 & x84>=36
g lend10old97= 14 if  x84>=28 & date>ym(1997,3) & date<ym(2006,2) & x84!=. & kal1d==1 & calcage>=45 
replace lend10old97=0 if calcage>=45 & x84>=32

// rules 2.06-current (one change in 2008)
g lend2old08= 24 if calcage>=58 & kal1d==1 & date>=ym(2008,1) & x84!=. & x84>48
g lend1old06= 18 if calcage>=55 & kal1d==1 & date>ym(2006,2) & x84!=. & x84>36
replace lend1old06=0 if calcage>=58 & x84>=48 & date>=ym(2008,1)
g lend2old06=15 if  calcage>=55 & kal1d==1 & date>ym(2006,2) & x84!=. & x84>30 & date<ym(2009,1)
replace lend2old06=0 if calcage>=55 & x84>=36 
g lend1old08= 15 if calcage>=50 & kal1d==1 & date>=ym(2008,1) & x84!=. & x84>30
replace lend1old08=0 if calcage>=55 & x84>=36 

// rules 87.7-current
g lend11old87=12 if  x84>=24 & date>ym(1987,6)  & x84!=. & kal1d==1 
replace lend11old87=0 if calcage>41 & x84>27 & date<ym(1997,4)
replace lend11old87=0 if calcage>44 & x84>27 & date<ym(2006,2) & date>ym(1997,3)
replace lend11old87=0 if calcage>54 & x84>29 & date<ym(2008,1) & date>ym(2006,1)
replace lend11old87=0 if calcage>49 & x84>29 & date>=ym(2008,1)  
g lend12old87=10 if x84>=20 & date>ym(1987,6)  & x84!=. & kal1d==1  
replace lend12old87=0 if  x84>23
g lend13old87= 8 if x84>=16 & date>ym(1987,6)  & x84!=. & kal1d==1 
replace lend13old87=0 if  x84>19
g lend14old87=6 if  x84>=12 & date>ym(1987,6)  & x84!=. & kal1d==1  
replace lend14old87=0 if  x84>15

//summarizing dummies

foreach i of varlist entitle_U* {
replace `i'=0 if kal1d!=1 
replace `i'=. if kal1d==.
}

g getbenefit=entitle_UI + entitle_UI2 + entitle_UI3

foreach i of varlist lend* {
replace `i'=. if x84==.
replace `i'=0 if kal1d==.
replace `i'=0 if calcage==.
replace `i'=0 if getbenefit==0

}

egen length_entit=rowtotal(lend*), missing
g month2expire=length_entit-length
replace month2= 0 if month2<0


save control, replace




//preparing for merge with annual variables
xtset pid date
drop if month!=pmonin
// drops everyone whose first year in the survey (no interview in previous year)

keep pid svyyear entit length month2 getb non_emp first_spell

replace entit=entit/12

save monthvariables, replace


/******************
*
*
* Merging the instruments with the variables
*
*
****************/



use "annualpremerge", clear
merge 1:1 pid svyyear using monthvariables
rename _m annual_month_m

merge m:1 pid using ppfad
drop if _m==2
drop _m


g hours= p0283 if p0283>0 & p0283!=.
g lhours=ln(hours)
xtset pid svyyear

drop if svyyear==1983

g t=svyyear-1983
g house_=1 if housingb>0 & housingb!=.
replace house_=0 if housingb==0
g t2=t*t/1000




//variable to cluster errors around
g cluster=land*svyyear

//dummies instead of factorial variables and differenced variables
tab wave, g(wak)
 tab land, g(lak)
 tab svyye, g(svyk)
 tab part, g(ipart)
 
 
 
 // generate variables to match BHPS
 //education
 g educ_higher=1 if pgisced==6 | pgisced==5
 replace educ_higher=0 if pgisced<5
 g educ_high_sec=1 if pgisced==4 | pgisced==3
 replace educ_high_=0 if pgisced<3 | educ_higher==1
 g educ_low_sec=1 if pgisced==2
 replace educ_low=0 if educ_high_==1 | educ_higher==1 | pgisced<2
 
 //unemployment
g unemp_=pgexpue
g unemp_squared=unemp_*unemp_/10
g unemp_cubed= pgexpue*pgexpue*pgexpue
replace unemp_cu=unemp_cu/100
 
//unemployment length
replace length=non_emp_length
g length_2=length*length/10
g length_3=length*length*length/100
//alternative measure



//tenure
g tenure= svyyear-job_start_year if job_start_year>0
g tenure2=tenure*tenure/10
g tenure3= tenure*tenure*tenure/100
 

//differenced wage 
xtset pid svyyear 
g dlp0295=lp0295-L.lp0295

 //last wage
g last_wage = lp0295
replace last_wage=L.last_wage if last_wage==.
replace last_wage=L2.last_wage if last_wage==.
replace last_wage=L3.last_wage if last_wage==.


//last hours worked
g last_hours= lhours
replace last_hours=L.last_hours if last_hours==.
replace last_hours=L2.last_hours if last_hours==.
replace last_hours=L3.last_hours if last_hours==.


drop hid p0195 p0205 p0208 p0238 p0243 p0281 p0283 cpi pgoeffd ///
pgemplst german last_lkal2a03_cpi last_lkal2b03_cpi last_lkal2c03_cpi p_klas ///
last_lkal2f03_cpi last_lkal2g03_cpi last_lkal2h03_cpi last_lh4744_cpi last_lh2699_cpi ///
last_ckal2a03 last_ckal2b03 last_ckal2c03 last_ckal2f03 last_ckal2g03 last_ckal2h03 last_ch4744 ///
last_ch2699 lp0316_cpi lp0318_cpi lp0320_cpi lp0387_cpi lh2728_cpi lh2734_cpi lh4723_cpi ///
cp0316 cp0318 cp0320 cp0387 ch2728 ch2734 ch4723 ALG1 ALG2 socialassis unempassis ///
maintenance_allowance gebjahr gebmonat sex germanytoge /// 
 caseid erstbefr letztbef eintritt austritt incomplete_info annual_month_m ///
 todjahr todinfo immiyear germborn loc1989 corigin migback miginfo psample gebmoval
 
 //labeling
 label var age "age"
 label var age2 "age squared / 10"
 label var female "female"
 label var unemp_ "unemployment experience (years)"
 label var unemp_square "unemployment experience squared / 10"
 label var unemp_cu "unemployment experience cubed / 100" 
 label var ipart2 "looking for fulltime work"
 label var ipart3 "looking for parttime work"
 label var ipart4 "looking for any hours"
 label var ipart5 "undecided about hours"
 label var educ_low "lower secondary education"
 label var  educ_high_ "higher secondary education"
 label var educ_higher "higher education"
 label var house_ "housing benefit dummy"
 label var children "number of children in household"
 label var  married "married"
 label var entit "insured months of work this spell"
 label var length "unemployment length "
  label var length_2 "unemployment length squared"
 label var length_3 "unemployment length cubed"
label var tenure "tenure"
label var tenure2 "tenure squared/10"
label var tenure3  "tenure cubed/100"
label var hours	"hours worked"
label var t "trend"
label var t2 "squared trend / 1000"
label var lu_agg_job "start of spell unemployment"


	




cd $data_path
save "dataset", replace




/*****************
*
*
* Regressions
*
*
******************/


cd $data_path
use "dataset", clear

global basic_controls "female age age2  educ_l educ_high_ educ_higher length length_2 length_3 married children house_ entit  ipart*"
global search_controls ""	
global wage_controls "female age age2 educ_l educ_high_ educ_higher tenure tenure2 tenure3 married children   lhours	"
global weight "w11101" //alternative is w11105

***Define estimation sample
//reservation wage regression
reg  lres  t i.land L(0).lagg_unemp  $basic_controls if age<65 & pgisced!=. & part!=0 & age>15 & first_spell!=1
gen sample_used=1 if e(sample)
//wage regression
reg lp0295 t i.land L(0).lagg_ $wage_controls	if age<65 & pgisced!=. & age>15
gen sample2_used=1 if e(sample)

tabstat lres  t land lagg_unemp  age age2 female unemp_* part educ_* $search_controls lben month2 getb if sample_used==1 , stats(mean sd p1 p99 N) col(stats)
tabstat lres  t land lagg_unemp  age age2 female unemp_* part educ_* $search_controls lben month2 getb, stats(mean sd p1 p99 N) col(stats)

****generate IV for refrence point
//generate IV for refrence point
/*
areg 	lp0295 industry_dummy* i.land i.svyyear age age2 lhours if sample2_used==1 & pgnace>1 , absorb(pid)
forvalue i=1/63 {
	display _b[industry_dummy`i']
	replace industry_premium1= _b[industry_dummy`i'] if industry_dummy`i'==1
	
}
/*forvalue i=1/63 {
	replace industry_dummy`i'= _b[industry_dummy`i'] if industry_dummy`i'==1
	
}
*/
forvalue i=1/63 {
	replace industry_dummy`i'= L.industry_dummy`i' if industry_dummy`i'==.
	
}


//tenure premium
areg 	lp0295 i.land i.svyyear age age2 lhours tenure tenure2 if sample2_used==1 , absorb(pid) 
replace industry_premium2= _b[tenure]*tenure + _b[tenure2]*tenure2 if sample2_used==1



//infer past premium based on industry & tenure

forvalue i = 1/2{
replace industry_premium`i'=L.industry_premium`i' if industry_premium`i'==. 
}

*/
//probit - probability that a certain type of person is employed in a given year
foreach j of numlist 1984/2010 {
reg lp0295 	t i.land  t2   lagg_ $wage_controls if sample2_used==1 & job_change==0 & svyyear==`j' , vce(cluster svyyear)
gen probit=1 if e(sample)
replace probit=0 if probit==. 
probit probit t i.land  t2   L(0).lagg_ female age age2 educ_l educ_high_ educ_higher married children   lhours if sample2_used==1 & svyyear==`j'
predict fitted if sample2_used==1 & svyyear==`j'
capture noisily g weight1= fitted/(1-fitted) if svyyear==`j'
replace weight1= fitted/(1-fitted) if svyyear==`j'
drop probit fitted
}

reg lp0295 	t i.land  t2   lagg_ $wage_controls if sample2_used==1 & job_change==0  , vce(cluster svyyear)
gen probit=1 if e(sample)
replace probit=0 if probit==. 
probit probit t i.land  t2   L(0).lagg_ female age age2 educ_l educ_high_ educ_higher married children   lhours if sample2_used==1
predict fitted2 if sample2_used==1
capture noisily g weight2= fitted2/(1-fitted2)





cd $regressions_path

/**********************
*
*
*   wage - national cycle
*
***********************/


//t
reg lp0295  t i.land L(0).lagg_ $wage_controls	if sample2_used==1 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc , word title("Table 3: wage elasticity to naional cycle") cttop("Trend") label  addtext(Trend, Linear , FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace  


// t2
reg lp0295 	t t2 i.land L(0).lagg_ $wage_controls			if sample2_used==1 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc ,  word cttop("quadratic Trend") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

// t2 weighted
/*reg lp0295 	t t2 i.land L(0).lagg_ $wage_controls	[pweight=$weight]		if sample2_used==1 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc ,  word cttop("quadratic Trend weighted") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  
*/
//t regio
reg lp0295 t2 i.land c.t#land  L(0).lagg_		$wage_controls if sample2_used==1 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc , word cttop("regional Trend") label addtext(Trend, Regional, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//with lag
reg lp0295 L.lp0295  	t t2 i.land  L(0).lagg_	$wage_controls			if sample2_used==1 , vce(cluster svyyear)

outreg2 L.lp0295 lagg_unemp using wage_elasticity.doc ,  word cttop("AR(1)") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//with lag both variables 
reg lp0295 L.lp0295  	t t2 i.land  L(0/1).lagg_	  $wage_controls			if sample2_used==1 , vce(cluster svyyear)

outreg2 L.lp0295 lagg_unemp L.lagg_unemp using wage_elasticity.doc ,  word cttop("AR(1), quadratic Trend & laged cycle") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//with llocal and agg unemp
reg lp0295 L.lp0295  	t t2 i.land  L(0).lagg_	llocal			 $wage_controls		if sample2_used==1 , vce(cluster svyyear)

outreg2  L.lp0295 lagg_unemp llocal using wage_elasticity.doc ,  word cttop("AR(1) and quadratic Trend and regional cycle") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//new job-findings only
reg lp0295 t i.land t2  L(0).lagg_	$wage_controls if sample2_used==1 & job_change==1 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc ,  word cttop("new hires") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//continued job
reg lp0295 	t i.land  t2   L(0).lagg_ $wage_controls if sample2_used==1 & job_change==0 , vce(cluster svyyear)

outreg2 lagg_unemp using wage_elasticity.doc ,  word cttop("continued employees") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//job start unemp
reg lp0295 t t2 i.land  L(0).lagg_	lu_agg_job	$wage_controls	if sample2_used==1 , vce(cluster svyyear)

outreg2	lagg_unemp lu_agg_job using wage_elasticity.doc , word  cttop("unemployment at job start") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//with lag job start unemp
reg lp0295 L.lp0295  t t2 i.land  L(0).lagg_	lu_agg_job $wage_controls	if sample2_used==1 , vce(cluster svyyear)

outreg2	L.lp0295 lagg_unemp lu_agg_job using wage_elasticity.doc ,  word  cttop("AR(1) and unemployment @ job starts") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//difference job start unemp
reg dlp0295 	t t2 i.land  L(0).lagg_	lu_agg_job	$wage_controls if sample2_used==1 , vce(cluster svyyear)

outreg2	lagg_unemp lu_agg_job using wage_elasticity.doc ,  word  cttop("elasticity of wage change") label addtext( Trend, Quadratic, FE, No, FD, Yes, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//fe regression
 xtdpd L(0/1).lp0295  t t2 L(0).lagg_	 female age age2 educ_l educ_high_ educ_higher tenure tenure2 tenure3 married children   hours  if sample2_used==1 , div(female age age2 educ_l educ_high_ educ_higher tenure tenure2 tenure3 married children   hours t t2 lagg_) dgmmiv(lp0295)  vce(robust)
 
 outreg2	L.lp0295 lagg_unemp using wage_elasticity.doc ,  word  cttop("FE") label addtext( Trend, Quadratic, FE, Yes, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  



*********************************************
***** res wage - national cycle *************
*********************************************

//control Trend
ivregress 2sls lres t i.land L(0).lagg_unemp $basic_controls (lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 

outreg2  lagg_unemp using national_cycle.doc ,  word  title("Table 1: reservation wage elasticity to national cycle") cttop("Trend") label addtext(Trend, Linear , FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace  

//control Trend^2
ivregress 2sls lres	t t2 i.land L(0).lagg_unemp  $basic_controls	(lben = month2 getb ) if sample_used==1  , vce(cluster svyyear)  

outreg2 lagg_unemp using national_cycle.doc ,  word cttop("quadratic Trend") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append   

/*
//control Trend^2 weighted
ivregress 2sls lres		
t t2 i.land L(0).lagg_unemp  $basic_controls	(lben = month2 getb ) [pweight=$weight] if sample_used==1  , vce(cluster svyyear)  

outreg2 lagg_unemp using national_cycle.doc ,  word cttop("quadratic Trend weighted") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append   
*/

//control regio Trend
ivregress 2sls lres t2 c.t#land i.land L(0).lagg_unemp $basic_controls (lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 

outreg2 lagg_unemp using national_cycle.doc ,  word cttop("regional Trend") label addtext(Trend, Regional, Yes, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append   


//Lagged unemp
ivregress 2sls lres t t2  i.land L(0/1).lagg_unemp $basic_controls $search_controls	(lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 

outreg2  lagg_unemp L.lagg_unemp using national_cycle.doc ,  word cttop("elasticity to lagged cycle") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//with regio controlls and agg
ivregress 2sls lres t t2 i.land L(0/1).lagg_unemp	L(0/1).llocal $basic_controls   $search_controls(lben = month2 getb ) if sample_used==1 , vce(cluster svyyear) 

outreg2 llocal L.llocal lagg_unemp L.lagg_unem using national_cycle.doc ,  word cttop("regional and national cycle") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  



//FE
xtivreg lres 	t t2  i.land L(0/1).lagg_unemp	$basic_controls $search_controls 		(lben = month2 getb ) if sample_used==1 , fe 

outreg2 lagg_unemp L.lagg_unem using national_cycle.doc ,  word cttop("fixed effects") label addtext( Trend, Quadratic, FE, Yes, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//control group specific unemp
ivregress 2sls lres	t t2 i.land   	unempl_educ	$basic_controls	(lben = month2 getb ) if sample_used==1  , vce(cluster svyyear)  

outreg2 unempl_educ using national_cycle.doc ,  word cttop("group specific cylces") label addtext( Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append   

/**************************************************/
//CHECKS 

/********************************************************************************/

//JOB FINDING

//job finding, defined as non-self employed job (including vocational training)
//all non-employed
reg F.job_change  lres  				i.svyyear if  sample_used==1  	 	 , vce(cluster cluster) 
outreg2  using starting_wage.doc,   word cttop("1") label addtext(Year Dummiers, Yes, Trend, No, Further Controlls, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace  

//IV with controls
reg  F.job_change 			lres lagg_ female age age2  educ_l educ_high_ educ_higher length length_2 length_3 married children	ipart* t t2 if    sample_used==1 , vce(cluster cluster) 
outreg2  using starting_wage.doc,  word cttop("2") label addtext(Year Dummiers, No, Trend, Quadratic, Further Controlls, Yes, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//FE regression
reg  F.job_change			lres llocal female age age2  educ_l educ_high_ educ_higher length length_2 length_3 married children ipart*	t t2	if  sample_used==1  , vce(cluster cluster) 
outreg2  using starting_wage.doc,   word cttop("3") label addtext(Year Dummiers, No, Trend, Quadratic, Further Controlls, Yes, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//STARTING WAGE

//all non-employed
reg F.lp0295 lres  				i.svyyear if F.job_change ==1  & sample_used==1  , vce(cluster cluster)  
outreg2 using starting_wage.doc,  word title("Table 5: starting wage") cttop("1") label addtext(Year Dummiers, Yes, Trend, No, Further Controlls, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//agg unemp
reg F.lp0295 lres  			lagg_ female age age2  educ_l educ_high_ educ_higher length length_2 length_3 married children t t2 ipart*	if F.job_change ==1  & sample_used==1, vce(cluster cluster)  
outreg2 using starting_wage.doc,  word cttop("2") label addtext(Year Dummiers, No, Trend, Quadratic, Further Controlls, Yes, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//regional unemp
reg  F.lp0295 		lres llocal female age age2  educ_l educ_high_ educ_higher length length_2 length_3 married children t t2 ipart*	if F.job_change ==1  & sample_used==1 , vce(cluster cluster) 
outreg2 using starting_wage.doc, word cttop("3") label addtext(Year Dummiers, No, Trend, Quadratic, Further Controlls, Yes, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


/////////  summary table

estpost sum cres_ $basic_controls $search_controls month2 getb benefit if sample_used==1 & lres!=.
esttab using sumres.rtf, cells("mean(fmt(3)) sd(fmt(3)) ") nomtitle nonumber replace 


estpost sum cp0295 $wage_controls hours if  lp0295!=.  & sample2_used==1 
esttab using sumwage.rtf, cells("mean(fmt(3)) sd(fmt(3)) ") nomtitle nonumber replace 

/***************** detailED REGRESSION ***********************************/

ivregress 2sls lres 		i.land L(0).lagg_		$search_controls $basic_controls t t2	(lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 
outreg2  using detail.doc ,  word cttop("3") label  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace 
reg lp0295 			 i.land L(0).lagg_		$wage_controls	t t2 if sample2_used==1 , vce(cluster svyyear)
outreg2  using detail.doc ,  word cttop("3") label  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 




*********************************************
***** wage - regional cycle *************
*********************************************

//i.svyyear
reg lp0295 i.svyyear i.land L(0).llocal				 $wage_controls	if sample2_used==1 , vce(cluster cluster)
outreg2 llocal using wage_elasticity_regional.doc , word title("Table 4: wage elasticity to regional cycle") cttop("year FE") label addtext(Year Dummies, Yes, Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace  


//t
reg lp0295  			t i.land L(0).llocal				$wage_controls	 if sample2_used==1, vce(cluster cluster)
outreg2 llocal using wage_elasticity_regional.doc , word cttop("Trend") label addtext(Trend, linear, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

// t2
reg lp0295 			 t2 t i.land L(0).llocal					$wage_controls 		 if sample2_used==1, vce(cluster cluster)
outreg2 llocal using wage_elasticity_regional.doc ,  word cttop("quadratic Trend") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//t regio
reg lp0295  			t t2 i.land c.t#land  L(0).llocal				$wage_controls 		 if sample2_used==1, vce(cluster cluster)
outreg2  llocal using wage_elasticity_regional.doc , word cttop("regional Trend") label addtext(Trend, Regional Trend, FE, No, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//with lag 
reg lp0295 L.lp0295  	t t2 i.land L(0).llocal				$wage_controls	 if sample2_used==1, vce(cluster cluster)
outreg2 llocal L.lp0295 using wage_elasticity_regional.doc ,  word cttop("AR(1)") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//with lag both variables 
reg lp0295 L.lp0295  	 t t2 i.land L(0/1).llocal				$wage_controls 		 if sample2_used==1, vce(cluster cluster)
outreg2 llocal L.lp0295 L.llocal using wage_elasticity_regional.doc ,  word cttop("laged cycle") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//new job-findings only
reg lp0295 	t i.land t2  L(0).llocal				$wage_controls 		 if sample2_used==1 & job_change==1, vce(cluster cluster)
outreg2 llocal using wage_elasticity_regional.doc ,   word cttop("new hires") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//continued job
reg lp0295 	t i.land   t2 L(0).llocal				$wage_controls	 if sample2_used==1 & job_change==0, vce(cluster cluster)
outreg2 llocal using wage_elasticity_regional.doc ,  word  cttop("continued employment") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//job start unemp
reg lp0295 			 t t2 i.land  L(0).llocal	u_jobstart			$wage_controls 		 if sample2_used==1, vce(cluster cluster)
outreg2 llocal u_jobstart	using wage_elasticity_regional.doc , word  cttop("unemployment @ job start") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//with lag
reg lp0295 L.lp0295  	 t t2 i.land  L(0).llocal	u_jobstart			$wage_controls	 if sample2_used==1, vce(cluster cluster)
outreg2 llocal u_jobstart L.lp0295	using wage_elasticity_regional.doc ,   word cttop("AR(1) & employment @ job start") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//difference
reg dlp0295 	 t t2 i.land  L(0).llocal	u_jobstart			$wage_controls	 if sample2_used==1, vce(cluster cluster)
outreg2 llocal u_jobstart	using wage_elasticity_regional.doc ,   word cttop("elasticity of wage change") label addtext(Trend, Quadratic, FE, No, FD, Yes, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//fe regression
xtdpd L(0/1).lp0295  t t2 L(0).llocal	 female age age2 educ_l educ_high_ educ_higher tenure tenure2 tenure3 married children   hours   if sample2_used==1 , div(female age age2 educ_l educ_high_ educ_higher tenure tenure2 tenure3 married children   hours  t t2 llocal) dgmmiv(lp0295)  vce(robust)

outreg2 llocal L.lp0295	using wage_elasticity_regional.doc ,   word cttop("FE") label addtext(Trend, Quadratic, FE, Yes, FD, No, SE/Clustering, Year x Region)  stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  



*********************************************
***** res wage - regional cycle *************
*********************************************

//no search controls
ivregress 2sls lres 			i.svyyear i.land L(0).llocal  		   $basic_controls	(lben = month2 getb ) if sample_used==1 , vce(cluster cluster)

outreg2 llocal using regional_cycle.doc ,  word title("Table 2: reservation wage elasticity to regional cycle") cttop("year FE") label addtext(Year Dummies, Yes, Trend, No, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace  


//control Trend
ivregress 2sls lres t  i.land L(0).llocal $basic_controls	(lben = month2 getb ) if sample_used==1 , vce(cluster cluster) 

outreg2 llocal using regional_cycle.doc ,  word cttop("Trend") label addtext(Trend, Linear, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//control Trend^2
ivregress 2sls lres t t2 i.land L(0). llocal  $basic_controls (lben = month2 getb )  if sample_used==1 , vce(cluster cluster)

outreg2 llocal using regional_cycle.doc ,  word cttop("quadratic Trend") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  



//regional Trend
ivregress 2sls lres t2 c.t#land  i.land L(0). llocal  $basic_controls	(lben = month2 getb ) if sample_used==1 , vce(cluster cluster)

outreg2 llocal using regional_cycle.doc ,  word cttop("regional Trend") label addtext(Trend, Regional, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  


//lagged llocal
ivregress 2sls lres t t2  i.land L(0/1). llocal	$basic_controls		$search_controls (lben = month2 getb ) if sample_used==1 , vce(cluster cluster) 

outreg2 llocal L.llocal using regional_cycle.doc ,  word cttop("lagged cycle") label addtext(Trend, Quadratic, FE, No, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

//FE
xtivreg lres 	t t2  i.land L(0/1).llocal $basic_controls		$search_controls 		(lben = month2 getb ) if sample_used==1 , fe 

outreg2 llocal L.llocal using regional_cycle.doc ,  word cttop("FE") label addtext(Trend, Quadratic, FE, Yes, FD, No, SE/Clustering, Year x Region) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append  

/**************** refrence point reservation wage *******************/
/*
ivregress 2sls lres $basic_controls t t2 i.land lagg $search_controls (lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 
outreg2 lres lagg using stickiness.doc , word title("") cttop("standard specification") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) replace 

ivregress 2sls lres $search_controls $basic_controls t t2 i.land L(0/1).lagg (lben = month2 getb ) if sample_used==1  , vce(cluster svyyear) 
outreg2 lres lagg L.lagg using stickiness.doc  , word title("") cttop("standard specification + laged unemployment") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres last_wage last_hours $search_controls $basic_controls t t2 i.land lagg (lben = month2 getb ) if sample_used==1  & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres last_wage lagg last_hours using stickiness.doc  , word title("") cttop("last wage") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres last_wage $search_controls $basic_controls t t2 i.land L(0/1).lagg (lben = month2 getb ) if sample_used==1  & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres last_wage lagg L.lagg using stickiness.doc  , word title("") cttop("last wage + laged unemp") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 
 
ivregress 2sls lres $search_controls $basic_controls t t2 i.land lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres lagg using stickiness.doc  , word title("") cttop("reduced sample") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres $search_controls $basic_controls t t2 i.land L(0/1).lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres lagg L.lagg using stickiness.doc  , word title("") cttop("reduced sample + laged unemp") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres last_wage industry_premium1 $search_controls $basic_controls t t2 i.land lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres last_wage industry_premium1 lagg using stickiness.doc  , word title("") cttop("industry premium") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 
 
ivregress 2sls lres last_wage industry_premium1 $search_controls $basic_controls t t2 i.land L(0/1).lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres last_wage industry_premium1 lagg L.lagg using stickiness.doc  , word title("") cttop("industry premium + laged unemp") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres last_wage industry_premium2 $search_controls $basic_controls t t2 i.land lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres last_wage industry_premium2 lagg using stickiness.doc  , word title("") cttop("industry premium - tenure") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 
 
ivregress 2sls lres last_wage industry_premium2 $search_controls $basic_controls t t2 i.land L(0/1).lagg (lben = month2 getb ) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres last_wage industry_premium2 lagg L.lagg using stickiness.doc  , word title("") cttop("industry premium - tenure + laged unemp") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

//IV results
//first stage
reg last_wage $search_controls $basic_controls t t2 i.land lagg  industry_premium1 month2 getb last_hours if sample_used==1 & last_wage!=. & lres!=. & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres industry_premium1 month2 getb last_hours lagg using stickiness.doc  , word title("") cttop("first stage last_wage") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

reg lben $search_controls $basic_controls t t2 i.land lagg  industry_premium1 month2 getb last_hours if sample_used==1 & last_wage!=. & lres!=. & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres industry_premium1 month2 getb last_hours lagg using stickiness.doc  , word title("") cttop("first stage benefits") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

reg last_wage $search_controls $basic_controls t t2 i.land lagg  industry_dummy* last_hours if sample_used==1 & last_wage!=. & lres!=. & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres industry_dummy* last_hours  lagg using stickiness.doc  , word title("") cttop("reduced form") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

//reduced form
reg lres industry_premium1 last_hours  month2 getb $search_controls $basic_controls t t2 i.land lagg  if sample_used==1  & last_wage!=. & lben!=. & industry_premium1!=. , vce(cluster svyyear) 
outreg2 lres industry_premium1 month2 getb last_hours lagg using stickiness.doc  , word title("") cttop("reduced form with benefits") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres industry_dummy* $search_controls $basic_controls t t2 i.land lagg (lben = month2 getb ) if sample_used==1  & industry_premium1!=. , vce(cluster svyyear) 


// IV
ivregress 2sls lres $search_controls $basic_controls t t2 i.land lagg  last_hours lben (last_wage = industry_premium1) if sample_used==1   & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres last_wage last_hours industry_premium1 lagg using stickiness.doc  , word title("") cttop("IV industry premium - with benefits") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 


ivregress 2sls lres $search_controls $basic_controls t t2 i.land lagg (last_wage lben = month2 getb industry_premium2) if sample_used==1 & last_wage!=. , vce(cluster svyyear)
outreg2 lres last_wage industry_premium2 lagg using stickiness.doc  , word title("") cttop("IV tenure premium") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres $search_controls $basic_controls t t2 i.land lagg (last_wage lben = month2 getb industry_premium2 industry_premium1) if sample_used==1 & last_wage!=.  & industry_premium1!=. , vce(cluster svyyear)
outreg2 lres last_wage industry_premium2 lagg using stickiness.doc  , word title("") cttop("IV tenure & industry premium") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 

ivregress 2sls lres $search_controls $basic_controls t t2 i.land lagg (last_wage lben = month2 getb industry_dummy*) if sample_used==1 & last_wage!=.  , vce(cluster svyyear) 
outreg2 lres last_wage industry_premium2 lagg using stickiness.doc  , word title("") cttop("IV tenure premium & industry premium dummies") label addtext(Trend, No,  Quadratic, FE, No, FD, No, SE/Clustering, Year) stats(coef se) bracket(se) asterisk(se) bdec(3) sdec(3) append 
*/
//analyse data
// drop occupation_dummy* //four_digit_occ*
/*
bysort occupation_isco: sum occupation_premium1 occupation_premium2
xtset pid svyyear

preserve
foreach j in female age  pgisced length tenure married children house_ entit part hours lres lp0295 cres cp0295 month2 getb {
bysort svyyear: egen meanw_`j'= wtmean(`j') if sample2==1 & west==1, weight(w11105)
bysort svyyear: egen meanu_`j'= wtmean(`j') if sample_==1 & west==1, weight(w11105)
}
twoway (line meanw_lp02 meanu_lres svyyear, yaxis(1)) (line lagg svyyear, yaxis(2))
twoway line meanw_female meanu_female svyyear
twoway line meanw_age meanu_age svyyear
twoway line meanw_pgisced meanu_pgisced svyyear
twoway line meanu_length svyyear
twoway line meanw_tenure svyyear
twoway line meanu_entit svyyear
twoway line meanu_month2 svyyear
twoway line meanu_getb svyyear
twoway line meanw_hours svyyear
restore
*/


/************** unemployment persistence ******************************/

cd $preparation_data_path
use agg_unemp

tset svyyear
reg ger L.ger

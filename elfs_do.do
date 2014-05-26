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


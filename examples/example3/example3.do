/*
Supporting files to "Imputing missing values with external data"
Thiesmeier R, Bottai M, Orsini N
Example 3: Missing Predictor
*/

clear all
*****************************
// Fit imputation in Study 2
qui use study_2, clear
qui logit z y x c
mat ib = e(b)
mat iV = e(V)
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 

*****************************
// Impute in Study 1
  
quietly use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , ///
		b(b_study2) v(v_study2) ///
		colnames(y x c _cons) imodel(logit) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(logit) rseed(24092024)

*quietly mi estimate, post eform noheader: logit y x c z
*****************************
// AUC over M imputed data sets
mi query
local M = r(M)
local area = 0
local list ""
forv k = 1/`M'{
	qui logit y x c _`k'_z
	qui lroc, nog
	local area = `=`area'+r(area)'
	local list "`list' `=r(area)'"
	
}

di "AUC over imputed data (average) = " %4.3f (`area'/`M')
*****************************                                         
// Reproduce Figure 1
                                               
quietly use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , ///
		b(b_study2) v(v_study2) ///
		colnames(y x c _cons) imodel(logit) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(1000) b(ib) v(iV) imodel(logit) rseed(24092024)

mi query
local M = r(M)
local area = 0
local list ""
forv k = 1/`M'{
	qui logit y x c _`k'_z
	qui lroc, nog
	local area = `=`area'+r(area)'
	local list "`list' `=r(area)'"
	
}

cap drop area_val
gen area_val = .
local i = 1
foreach k of local list {
	qui replace area_val = `k' in `i'
    local ++i
}

su area_val
hist area_val, ///
	bin(20) xtitle("Area Under the Curve (AUC)", size(small)) ///
	ytitle("Distribution", size(small)) fcolor(black%10) lcolor(black) /// 
	xlab(`=r(min)' `=r(mean)' `=r(max)', nogrid labsize(small) format(%4.3f)) ///
	ylab(, nogrid labsize(small)) name(figure_example3, replace) aspect(1)

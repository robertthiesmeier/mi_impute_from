/*
Supporting files to the mnauscript "Imputing missing values with external data"
Thiesmeier R, Bottai M, Orsini N
Example 1: Missing Confounder

*/

clear all
***********************************
// Step 1: Fit imputation model in Study 2
use study_2, replace
forv i = 1/99 {
	qui qreg z y x c, q(`i')
	mat b = e(b)
	mat V = e(V)
	if colsof(b) == e(rank) {
		matrix coleq  b = "q`i'"
		if `i' == 1 {
			mat ib = b
			mat iV = V 
		}
		else {
			mat ib = ib , b
			mata: iV = blockdiag(st_matrix("iV"), st_matrix("V"))
			mata: st_matrix("iV", iV)
		}
	}				
}	
                    
// transfrom to matrices                   
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 
***********************************
// Step 2: Import files to Study 1
use study_1, clear
replace z = . 
save study_1, replace

quietly use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , b(b_study2) v(v_study2) colnames(y x c _cons) imodel(qreg) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(qreg) rseed(24092024)
                      
***********************************
// Step 3: Fit outcome model
mi estimate, post eform noheader : logit y x c z


********************************************************************************
// Extension to using multiple studies
***********************************                      
// Step 1: Fit imputation model in Study 2 and 3
forv k = 2/5 {
	use study_`k', replace
	forv i = 1/99 {
		qui qreg z y x c, q(`i')
		mat b = e(b)
		mat V = e(V)
		if colsof(b) == e(rank) {
			matrix coleq  b = "q`i'"
			if `i' == 1 {
				mat ib = b
				mat iV = V 
			}
			else {
				mat ib = ib , b
				mata: iV = blockdiag(st_matrix("iV"), st_matrix("V"))
				mata: st_matrix("iV", iV)
			}
		}				
	}	
	svmat ib 
	qui export delimited ib* using b_study`k'.txt in 1 , replace 
	svmat iV 
	qui export delimited iV* using v_study`k'.txt if iV1 != . , replace 
}

***********************************
// Step 2: Import files from Study 2-5 to Study 1
quietly use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , ///
	b(b_study2 b_study3 b_study4 b_study5) ///
	v(v_study2 v_study3 v_study4 v_study5) ///
	colnames(y x c _cons) imodel(qreg) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(qreg) rseed(24092024)
                        
***********************************
// Step 3: Fit outcome model
mi estimate, post eform noheader : logit y x c z

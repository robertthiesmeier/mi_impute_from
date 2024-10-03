/*
Supporting files to "Imputing missing values with external data"
Thiesmeier R, Bottai M, Orsini N
Example 2: Missing EM
*/

clear all
*************************
// Fit imputation model in Study 2
  
use study_2 , clear 
mlogit z x cumh _d x_cumh x_d , base(0)
mat ib = e(b)
mat iV = e(V)
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 

*************************
// Back to Study 1 and perform imputations
  
quietly use study_1, clear 
mi set wide
qui mi stset time, fail(death)
mi register regular cumh _d x_cumh x_d
mi register imputed z
mi register passive zi1 zi2 x_zi1 x_zi2
mi_impute_from_get , ///
	b(b_study2) v(v_study2) ///
	colnames(x cumh _d x_cumh x_d _cons) values(0 1 2) imodel(mlogit) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(mlogit) rseed(24092024)

quietly {
	mi passive: replace zi1 = (z==1)
	mi passive: replace zi2 = (z==2)
	mi passive: replace x_zi1 = x*zi1
	mi passive: replace x_zi2 = x*zi2
}

*************************
mi estimate , post eform noheader saving(miestfile, replace):  ///
	stcox x zi1 zi2 x_zi1 x_zi2 

mi predictnl est_bxz0 = _b[x] using miestfile, se(est_se_bxz0)
di %2.1f exp(est_bxz0)
di %2.1f exp(est_bxz0 + 1.96*est_se_bxz0)
di %2.1f exp(est_bxz0 - 1.96*est_se_bxz0)

mi predictnl est_bxz1 = _b[x] + _b[x_zi1] using miestfile, se(est_se_bxz1)
di %2.1f exp(est_bxz1)
di %2.1f exp(est_bxz1 + 1.96*est_se_bxz1)
di %2.1f exp(est_bxz1 - 1.96*est_se_bxz1)

mi predictnl est_bxz2 = _b[x] + _b[x_zi2] using miestfile, se(est_se_bxz2)
di %2.1f exp(est_bxz2)
di %2.1f exp(est_bxz2 + 1.96*est_se_bxz2)
di %2.1f exp(est_bxz2 - 1.96*est_se_bxz2)

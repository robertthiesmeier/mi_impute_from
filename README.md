# Imputation Missing Values using External Data

## Content 
Missing data is a common challenge across scientific disciplines. Current imputation methods require the availability of individual data to impute missing values. Often, however, missingness requires using external data for the imputation. Therefore, we introduce a new Stata command, `mi impute from`, designed to impute missing values using linear predictors and their related covariance matrix from imputation models estimated in one or multiple external studies. This allows for the imputation of any missing values without sharing individual data between studies. 

## Dowload `mi impute from` :computer:
This site contains the materials to the paper "Imputing Missing Values with External Data". The first version of the new Stata command `mi impute from` can be downloaded from the SSC Archive in Stata:

```ruby
ssc install mi_impute_from
```

In this preprint (add link), we describe the underlying method and present the syntax of `mi impute from` alongside practical examples of missing data in collaborative research projects. The examples in the paper can be reproduced with the materials on this site. To do so, please dowload the data sets for each example and exceute  the code (.do) to reproduce the statistics and figure presented.

# Examples :bulb:
We present three examples on how to use `mi impute from` wot continious, discrete, and binary missing data. Please refer to the paper for a detailed description of the examples. Download the data sets for the following examples [here](datasets/datasets.zip)

## Example 1: Missing confounder

Step 1: Fit the imputation in the study with data on the confounder
```ruby
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
```

:outbox_tray: Export the regression coefficients and covariance matrix to a txt file.

```ruby
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 
```

:inbox_tray: Step 2: Back to the study with missing data and make informtion read to use with `mi_impute_from_get`. 

```ruby
use study_1, clear
replace z = . // Z is set to missing
save study_1, replace

mi set wide
mi register imputed z
mi_impute_from_get , b(b_study2) v(v_study2) colnames(y x c _cons) imodel(qreg) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(qreg) rseed(24092024)
```
                      
We can use `mi estimate` to fit the outcome model in each imputed data set and combine the estimates with Rubin's rules.

```ruby
mi estimate, post eform noheader : logit y x c z
```

### Extension to multiple studies 
Let us use multiple studies to fit the imputation model. 

```ruby
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
```

Use `mi_impute_from_get` to import matrices from all studies :inbox_tray: and take a weighted average. 

```ruby
use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , ///
	b(b_study2 b_study3 b_study4 b_study5) ///
	v(v_study2 v_study3 v_study4 v_study5) ///
	colnames(y x c _cons) imodel(qreg) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(qreg) rseed(24092024)
```

Again, we can use `mi estimate` to fit the outcome model in each imputed data set and combine the estimates with Rubin's rules.

```ruby
mi estimate, post eform noheader : logit y x c z
```

## Example 2: Missing Effect modifier
In the first step, we fit the imputation model in the study with observed data on the missing EM. We can fit a multinomial logistic regression model.

```ruby
use study_2 , clear 
mlogit z x cumh _d x_cumh x_d , base(0)
mat ib = e(b)
mat iV = e(V)
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 
```

Back to Study 1 where we can import the files :inbox_tray: and perform the imputations and fit the imputation model in all imputed data sets.

```ruby
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


mi estimate , post eform noheader saving(miestfile, replace):  ///
	stcox x zi1 zi2 x_zi1 x_zi2 
```

To estimate the parameters of the the effect of the treatment at the low, medium, and high level of the EM: 

```ruby
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
```

## Example 3: Missing Predictor
The last example illustrates the use of `mi impute from` for the use prediction models.
Again, we fit the imputation model in an external study with some information on the missing variable of interest. 

```ruby
qui use study_2, clear
qui logit z y x c
mat ib = e(b)
mat iV = e(V)
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 
```

In the study with missing data on the predictor of interest, import files :inbox_tray: and perform imputations. 

```ruby
quietly use study_1, clear 
mi set wide
mi register imputed z
mi_impute_from_get , ///
		b(b_study2) v(v_study2) ///
		colnames(y x c _cons) imodel(logit) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(logit) rseed(24092024)
```

To estimate the Area Under the Curve (AUC) after multiple imputation: 

```ruby
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
```

### Reproduce the figure :bar_chart:
The figure in the paper can be reproduced by simply adding 1000 imputations in the previous step: 

```ruby
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
```

![figure1](https://github.com/user-attachments/assets/db204789-e365-47a4-8483-57c72b4c1253)

We hope that have shown you how to use the new `mi impute from` with some examples. :sparkles:

## Related material :bookmark:
:label: The underlying imputation method and a simulation study are described in: [Thiesmeier, R., Bottai, M., & Orsini, N. (2024). Systematically missing data in distributed data networks: multiple imputation when data cannot be pooled. Journal of Statistical Computation and Simulation, 1–19](https://doi.org/10.1080/00949655.2024.2404220)

:label: The first version of the `mi impute from` was presented at the [2024 UK Stata Conference in London](https://www.stata.com/meeting/uk24/slides/UK24_Orsini.pdf)

:warning: If you find any error please notfiy us: robert.thiesmeier@ki.se

# Imputation Missing Values using External Data

## Content
Missing data is a common challenge across scientific disciplines. Current imputation methods require the availability of individual data to impute missing values. Often, however, missingness requires using external data for the imputation. Therefore, we introduce a new Stata command, `mi impute from`, designed to impute missing values using linear predictors and their related covariance matrix from imputation models estimated in one or multiple external studies. This allows for the imputation of any missing values without sharing individual data between studies. 

## Dowload `mi impute from`
This site contains the materials to the paper "Imputing Missing Values with External Data". The first version of the new Stata command `mi impute from` can be downloaded from the SSC Archive in Stata:

`ssc install mi_impute_from`

In this preprint (add link), we describe the underlying method and present the syntax of `mi impute from` alongside practical examples of missing data in collaborative research projects. The examples in the paper can be reproduced with the materials on this site. To do so, please dowload the data sets for each example and exceute  the code (.do) to reproduce the statistics and figure presented.

### Example 1: Missing confounder
Please refer to the paper for a detailed description of the examples. 

Step 1: Fit the imputation in the study with data on the confounder
```
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

Export the regression coefficients and covariance matrix to a txt file.

```
svmat ib 
qui export delimited ib* using b_study2.txt in 1 , replace 
svmat iV 
qui export delimited iV* using v_study2.txt if iV1 != . , replace 
```

Step 2: Back to the study with missing data and make informtion read to use with `mi_impute_from_get`. 

```
use study_1, clear
replace z = . // Z is set to missing

mi set wide
mi register imputed z
mi_impute_from_get , b(b_study2) v(v_study2) colnames(y x c _cons) imodel(qreg) 
mat ib = r(get_ib)
mat iV = r(get_iV)
mi impute from z , add(10) b(ib) v(iV) imodel(qreg) rseed(24092024)
```
                      
We can use `mi estimate` to fit the outcome model in each imputed data set and combine the estimates with Rubin's rules.

```
mi estimate, post eform noheader : logit y x c z
```


## Related material
The underlying imputation method and a simulation study are described in: Thiesmeier, R., Bottai, M., & Orsini, N. (2024). Systematically missing data in distributed data networks: multiple imputation when data cannot be pooled. Journal of Statistical Computation and Simulation, 1–19. https://doi.org/10.1080/00949655.2024.2404220


If you find any error please notfiy us: robert.thiesmeier@ki.se

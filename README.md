# mi_impute_from: Imputation Missing Values using External Data

## Content
Missing data is a common challenge across scientific disciplines. Current imputation methods require the availability of individual data to impute missing values. Often, however, missingness requires using external data for the imputation. Therefore, we introduce a new Stata command, `mi impute from`, designed to impute missing values using linear predictors and their related covariance matrix from imputation models estimated in one or multiple external studies. This allows for the imputation of any missing values without sharing individual data between studies. 

## Dowload `mi impute from`
This site contains the materials to the paper "Imputing Missing Values with External Data". The first version of the new Stata command `mi impute from` can be downloaded from the SSC Archive in Stata:

`ssc install mi_impute_from`

In this preprint (add link), we describe the underlying method and present the syntax of `mi impute from` alongside practical examples of missing data in collaborative research projects. The examples in the paper can be reproduced with the materials on this site. To do so, please dowload the data sets for each example and exceute  the code (.do) to reproduce the statistics and figure presented.

## Additional material
The underlying imputation method and a simulation study are described in: Thiesmeier, R., Bottai, M., & Orsini, N. (2024). Systematically missing data in distributed data networks: multiple imputation when data cannot be pooled. Journal of Statistical Computation and Simulation, 1–19. https://doi.org/10.1080/00949655.2024.2404220


If you find any error please notfiy us: robert.thiesmeier@ki.se

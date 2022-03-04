# Morphologic parameters affect interpretation of age-related changes in diffusion tensor metrics
Code for the paper "Morphologic parameters affect interpretation of age-related changes in diffusion tensor metrics" which is currently under review.

## Repository structure:
The repository is organized as follows:
```
DTI/
│    README.md: you are here
│    requirements.txt
└─── data/
│       subjects_with_tract_stats.xlsx
│       subjects.xlsx
└─── MATLAB/     
└─── notebooks/
│       Integrate tract stats.ipynb   
│       Statistical Analysis.ipynb
└─── R/
│       correlation_and_regression_morphology.Rmd
|       regression_FA_age_RD.Rmd
└─── results/


```

In greater detail:

- **requirements.txt**: required python3 packages to conduct the reported statistical analyses. Create a virtual environment, activate it and install the required packages.
- **data/**: this folder contains the datasets used for the final analyses.
  - subjects.xlsx: mean and standard deviation of tensor metrics for each tract and subject. Since each tract was subdivided in 200 nodes along its extension, we decided to consider the average value of each metric computed at each node.
  - subjects_with_tract_stats.xlsx: same as subjects.xlsx but integrates tract statistics (i.e., average length, density and volume).
- **MATLAB/**: this folder contains the code used to extract morphologic parameters of tracts (i.e., length, density and volume) from white matter classification structures and tractograms. See the README for more information.
- **notebooks/**: python notebooks used to conduct several analyses.
  - *Integrate tract stats.ipynb*: in this notebook we integrate morphologic parameters of fibers into the subjects dataframe (i.e., we generate subjects_with_tract_stats.xlsx file).
  - *Statistical analysis.ipynb*: in this notebook we conduct a correlation analysis by means of Spearman's rank correlation. Correlations between each DTI measure and age were computed. Additionally, correlation between FA and age with and without the other DTI measures (MD, RD and AD) as covariates (partial correlation) were computed. 
- **R/**: R files used to conduct regression and correlation analyses, and to produce the illustrations in the paper.
  - *correlation_and_regression_morphology.Rmd*: this R markdown notebook contains the correlation analysis conducted via spearman correlation and the regression analysis by means of robust linear regression. In detail, for each of the 72 tracts, AD, MD and RD were regressed onto Age both with each morphologic parameter as covariate (one at a time) and without. For each combination of tract and DTI metric, a plot with four lines is created: one line for the regression of DTI metric onto age (no covariate) and the remaining three corresponding to each covariate.
  - *regression_FA_age_RD.Rmd*: this notebook contains the robust regression analysis in which FA was regressed onto age for each tract, with and without RD as covariate. This was treated as a separate analysis as no morphologic parameter was considered.
- **results/**: this folder contains the results of the statistical analyses in terms of either excel or .csv files.
## The COVID-19 Community Risk Score
## Identifying communities at risk for COVID-19-related burden across 500 U.S. Cities (and within New York City)

## Authors
- Chirag J Patel (chirag@xy.ai)
- Arjun K Manrai (raj@xy.ai)


### Introduction

Emerging from case-series and epidemiological surveillance data from the United States (refs) and around the world [cite], risk factors for COVID-19-related outcomes, such as hospitalization, ICU admission, and death include older age, impaired lung function, and cardiometabolic-related diseases (e.g., diabetes, heart disease, stroke) and risk factors (obesity). In the United States, these factors are known to “cluster” in geographies, such as the southeast states and counties, and are exacerbated by socio-demographic conditions known as the “social determinants of health”. (ref Kreiger, new paper, medarxiv).

However, prevalent chronic diseases and their risk factors for COVID-19 are geographically heterogenous and vary per unit of geography, including within and across states, counties, and even cities (ref Nilanjan Chatterjee). It is unclear how the heterogeneity of community-based risk -- or prevalence of diseases at a Census-tract level (median population sizes of ~3000-5000 individuals) is related to COVID-19 risk. Here, we demonstrate how to calculate a Census-tract-level COVID-19 Community Risk Score that summarizes the complex co-morbidity and demographic patterns of small communities at the Census tract, county, and state levels into a single number. We show how the COVID-19 risk score varies per city, pointing to how county-level estimates may obscure identification of specific regions at high risk, important for resource allocation. Second, we deploy two emerging approaches in machine learning to trace built environment and sociodemographic predictors of COVID-19 Community Risk. To map the built environment, we use deep learning to query features from satellite imagery -- common to those used in navigation -- to build a predictor of COVID-19 Community Risk. We also demonstrate how social determinants of health are strongly correlated and predict the COVID-19 Community Risk Score.  Last, we focus on a pastthe current (as of May 23, 2020) hotspot of COVID-19 epidemic, New York City, to show how the COVID-19 Community Risk Score is associated with zipcode-level COVID-19 related deaths independent of social determinants of health during the height of the epidemic..
We deploy the COVID-19 Risk Score with an application programming interface and a browsable dashboard.

### Methods

We obtained the US Centers for Disease Control and Prevention 2017 500 Cities data (updated December 2019). The 500 Cities data contains disease and health indicator prevalence for 26,968 number individual census tracts of the 500 Cities which are estimated from the Behavioral Risk Factor Surveillance System (BRFSS) [links].

From the 500 Cities data, we chose 13 health indicators that may put patients with COVID-19 at risk for hospitalization and death based on recent case reports emerging from Wuhan, Italy, and the United States (refs). Disease indicators include prevalence for adults over 18 of diabetes, coronary heart disease, chronic kidney disease,  asthma, arthritis, any cancer, chronic obstructive pulmonary disorder. We also selected behavioral risk factors including smoking and obesity. Third, we selected variables that reflected access to care, such as prevalence of individuals on blood pressure medication and high cholesterol levels.   

We obtained 5-year 2013-2017 American Community Survey (ACS) Census data, which contains sociodemographic prevalences and median values for Census tracts. First, we selected demographic variables, including the total number of individuals in the tract, proportion of males and females over the age of 65, proportion of individuals by race (e.g., African American, White, Hispanic, American Indian, Pacific Islander, Asian, or Other). These data also included information on the socioeconomic indicators including median income, the proportion of individuals under poverty, unemployed, cohabitate with more than one individual per room, and have no health insurance.
Community Covid-19 Risk Score Formulation
We merged 500 Cities' health and disease indicator prevalence for each of the 26,968 census with ACS information and calculated their Pearson pairwise correlations. We considered 15 variables in total, including 13 health indicators (e.g., diseases and risk factors), and 2 demographic factors, the proportion of males and females individuals over 65 in the risk score. The disease prevalence included diabetes, coronary heart disease, any cancer, asthma, chronic obstructive pulmonary disease, arthritis; the behavioral risk factors included prevalence of obesity, smoking, high cholesterol, and high blood pressure. The clinical risk factors included the prevalence of individuals on a blood pressure medication. 

To summarize the total variation of the disease prevalences in a single score, we devised 2 similar approaches. The first approach scaled each of the 13 health indicators plus males and females over 65 (z-score transformation) prevalence by subtracting the overall average and dividing by the standard deviation of the prevalence. Then, for each census tract, the z-scores were summed and rescaled to be between 0-100. Therefore, the tracts with the highest scores have the highest “additive” prevalences for all the health indicators. We call this the additive score.

The second and primary score utilized principal components analysis (PCA), a “unsupervised” machine learning approach that “reprojects” data (26,968 by 15 dimensioned in our case) into a new space where each new variable is a linear combination of variables from the original dataset. PCA attempts to maximize the variance explained over the dataset in successive new variables (call them Y1 through Y15) that are defined by the “components”, or linear combination of each of the original variables (e.g., health indicators). Therefore, the first variables (Y1, Y2, etc) that correspond to the first principal components in the new dataset explain the maximal amount of variation in the entire dataset.  After reprojecting the census tracts on the first two principal components, call them Y1 and Y2 (fitting each census tract to the first two principal components), we “aligned” Y1 and Y2 such that the increasing prevalence of all the disease and health indicators were monotonically increasing with increase of the disease prevalences. Next, we estimated a single score for each census tract as a weighted average between Y1 and Y2, where the weights were proportional to the variance explained by the first and second principal components respectively. Finally, the score is rescaled to be between 0-100. The higher the value, the higher the total burden of disease and proportion of individuals over 65 in that census tract. We calculated risk score for different units of administrative areas, including the 500 cities, XX counties, and 50 states. We estimated a city-wide prevalence of each of the 15 COVID-19 risk factors and diseases and then computed the additive and PCA-based scores as above. We repeated the same procedure for counties (m=XX) and states (m=50).

Next, we sought to estimate how robust the PCA-based risk score is to sampling error via simulation. To do so, we estimated the standard deviation of the prevalences as a function of the size of the population of the tract. We assumed a covariance structure between the disease prevalences to be the observed census-level correlation across the US. Next, for each census tract, we simulated 100 times the prevalence of the diseases using a multivariate normal distribution, centered around the actual prevalence and with covariance equal to the COVID-19 risk factor correlation over all 26,968 tracts. Next, for each of the 100 simulated datasets we computed the principal components and obtained a simulated distribution about the principal component. Next, we estimated the predicted new projections for plus or minus 5 standard deviations (SD) of the principal components. The “robustness” score is the range of the score across the +/- 5 SD of the principal components. 
Socioeconomic Correlates of the Community COVID-19 Risk Score
We associated each of the ACS-estimated sociodemographic indicators with the COVID-19 community risk score multivariate linear and random forests regression to test the linear and non-linear contribution of the sociodemographic indicators in the COVID-19 Score. We split the dataset into half “training” and “testing” to get a conservative estimate of variance explained and predictive capability of the sociodemographic variables in the COVID-19 Risk Score while not overfitting the data. Specifically, we tested the linear and non-linear association pr prediction between American Community Survey 5-year proportions of individuals in each census tract who were (a) below poverty, (b) unemployed, (c) non-employed, (d) have less than high school education, (e) lack health insurance, (f) have more than one person occupied per room, and (g) Hispanic, Asian, African American, or Other Ethnic group (Table 1). Furthermore, we also included the median income and median home value of a census tract. Coefficients in the linear regression denoted a X unit change in a 1 unit change in the socioeconomic variable (e.g., a 1 SD unit change in the prevalence or a 1 SD change in the median income for a census tract). Random forests were fit using 1000 trees and a tree size of 5.

#### Association of the COVID-19 Community Risk Score with zipcode-level COVID-19-attributed mortality
We downloaded case and death count data on a zipcode tabulation area (ZCTA) of New York City, a hotspot of the US COVID-19 epidemic as of 5/20/20.  We used 2010 Census cross-over files to map Census tracts to ZCTAs. We computed the average COVID-19 Community Risk Score for the ZCTA, weighting the average by population size of the Census tract. Like the above, we estimated the ZCTA-level socioeconomic values and proportions. We associated the COVID-19 with the death rate using a negative binomial model. We set the offset term as the logarithm of the total population size of a zipcode. The exponentiated coefficients are interpreted as the incidence rate ratio for a unit change in the variable (versus no change).



## COVID-19 Score Pipeline 
- risk_score.Rmd

## Supporting database scripts
- get_acs_data_edw.R

## Association analyses
- new_york.Rmd (associate the COVID-19 Score with NYC zipcode mortality)
- nursing_homes.Rmd (associate the COVID-19 Score with NYC zipcode mortality)

## Score Data and API
- Scores per census tract, city, and state are in `scores`
- see: https://github.com/xyhealth/covid_index_api_docker

## R version
      > version
               _                           
      platform       x86_64-pc-linux-gnu         
      arch           x86_64                      
      os             linux-gnu                   
      system         x86_64, linux-gnu           
      status                                     
      major          3                           
      minor          5.2                         
      year           2018                        
      month          12                          
      day            20                          
      svn rev        75870                       
      language       R                           
      version.string R version 3.5.2 (2018-12-20)
      nickname       Eggshell Igloo   

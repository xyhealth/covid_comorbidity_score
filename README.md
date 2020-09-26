

# COVID-19 Community Risk Score

### Authors
- Chirag J Patel (chirag@xy.ai)
- Arjun K Manrai (raj@xy.ai)


## Identifying communities at risk for COVID-19-related burden across 500 U.S. Cities (and within New York City)
### Introduction

Emerging from case-series and epidemiological surveillance data from the United States (refs) and around the world [cite], risk factors for COVID-19-related outcomes, such as hospitalization, ICU admission, and death include older age, impaired lung function, and cardiometabolic-related diseases (e.g., diabetes, heart disease, stroke) and risk factors (obesity). In the United States, these factors are known to “cluster” in geographies, such as the southeast states and counties, and are exacerbated by socio-demographic conditions known as the “social determinants of health”. (ref Kreiger, new paper, medarxiv).

However, prevalent chronic diseases and their risk factors for COVID-19 are geographically heterogenous and vary per unit of geography, including within and across states, counties, and even cities (ref Nilanjan Chatterjee). It is unclear how the heterogeneity of community-based risk -- or prevalence of diseases at a Census-tract level (median population sizes of ~3000-5000 individuals) is related to COVID-19 risk. Here, we demonstrate how to calculate a Census-tract-level COVID-19 Community Risk Score that summarizes the complex co-morbidity and demographic patterns of small communities at the Census tract, county, and state levels into a single number. We show how the COVID-19 risk score varies per city, pointing to how county-level estimates may obscure identification of specific regions at high risk, important for resource allocation. Second, we deploy two emerging approaches in machine learning to trace built environment and sociodemographic predictors of COVID-19 Community Risk. To map the built environment, we use deep learning to query features from satellite imagery -- common to those used in navigation -- to build a predictor of COVID-19 Community Risk. We also demonstrate how social determinants of health are strongly correlated and predict the COVID-19 Community Risk Score.  Last, we focus on a pastthe current (as of May 23, 2020) hotspot of COVID-19 epidemic, New York City, to show how the COVID-19 Community Risk Score is associated with zipcode-level COVID-19 related deaths independent of social determinants of health during the height of the epidemic..
We deploy the COVID-19 Risk Score with an application programming interface and a browsable dashboard.



## COVID-19 Score Pipeline 
- risk_score.Rmd

## Supporting database scripts
- get_acs_data_edw.R

## Association analyses
- new_york.Rmd (associate the COVID-19 Score with NYC zipcode mortality)
- nursing_homes.Rmd (associate the COVID-19 Score with NYC zipcode mortality)

## API
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

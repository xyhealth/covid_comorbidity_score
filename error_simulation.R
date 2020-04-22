# Chirag Patel
# 04/02/2020


library(tidyverse)
library(progress)
library(mvtnorm)
library(scales)

# load data
fh_acs <- read_rds('./fh_acs.rds')
fh_names <- read_rds('./fh_orig_tract.rds')
fh_acs <- fh_acs %>% left_join(fh_names, by = c('geoid'='fips_tract'))
place_vars <- names(fh_names)
fh_acs <- fh_acs %>% group_by(geoid) %>% slice(1) %>% ungroup() # grab only the unique geoid

#### calculate SEs of each variable for each tract
fh_vars <- names(fh_acs)[grep('CrudePrev', names(fh_acs))]
health_prefix <- strsplit(fh_vars, '_') %>% map(function(arr) {arr[[1]]}) %>% unlist()
health_prefix <- setdiff(health_prefix, 'COLON')
fh_vars <- c(setdiff(fh_vars, 'COLON_SCREEN_CrudePrev'), 'COLON_SCREEN_CrudePrev')
health_prefix <- c(health_prefix, 'COLON_SCREEN')
fh_95hi_vars <- sprintf('%s_Crude95CI_high', health_prefix)
fh_se_vars <- sprintf('%s_SE', health_prefix)
fh_sd_vars <- sprintf('%s_SD', health_prefix)
fh_acs <- fh_acs %>% mutate(total_population = total_males + total_females)
for(index in 1:length(fh_vars)) {
  fh_acs[,fh_se_vars[index]] <- (fh_acs[,fh_95hi_vars[index]] - fh_acs[, fh_vars[index]])/1.96
  fh_acs[,fh_sd_vars[index]] <- fh_acs[, fh_se_vars[index]] * sqrt(fh_acs[,'total_population'])
}

###
fh_behavior <- c('BINGE', 'SLEEP', 'CSMOKING')
fh_disease <- c('ARTHRITIS', 'CANCER', 'CASTHMA', 'CHD', 'COPD', 'DIABETES', 'KIDNEY', 'TEETHLOST', 'STROKE')
fh_risk <- c('OBESITY', 'BPHIGH', 'LPA', 'HIGHCHOL')
fh_access <- c('ACCESS2', 'BPMED', 'CHECKUP', 'CHOLSCREEN', 'COLON_SCREEN', 'COREM', 'COREW', 'MAMMOUSE', 'MHLTH', 'PHLTH', 'PAPTEST')

fh_behavior <- fh_vars[fh_behavior %>% map(grep, fh_vars) %>% unlist()]
fh_disease <- fh_vars[fh_disease %>% map(grep, fh_vars) %>% unlist()]
fh_risk <- fh_vars[fh_risk %>% map(grep, fh_vars) %>% unlist()]
fh_access <- fh_vars[fh_access %>% map(grep, fh_vars) %>% unlist()]


ses_vars <- c('gini_index')
ses_vars <- c(ses_vars, 'median_income')
ses_vars <- c(ses_vars, 'median_home_value')
ses_vars <- c(ses_vars, 'male_over_65_pct', 'female_over_65_pct')
ses_vars <- c(ses_vars, 'white_pct', 'african_american_pct', 'american_indian_pct', 'asian_pct', 'hawaiian_pacific_islander_pct', 'other_race_pct', 'two_or_more_race_pct')
ses_vars <- c(ses_vars, 'hispanic_pct', 'mexican_pct', 'puerto_rican_pct', 'cuban_pct', 'dominican_pct', 'central_american_pct', 'south_american_pct', 'other_hispanic_pct')
ses_vars <- c(ses_vars, 'less_than_high_school_pct', 'college_pct')
ses_vars <- c(ses_vars, 'at_below_poverty_pct', 'at_below_poverty_over_65_pct')
ses_vars <- c(ses_vars, 'unemployment_pct', 'non_employment_pct')
ses_vars <- c(ses_vars, 'more_than_one_occupant_per_room_pct', 'more_than_one_occupant_per_room_renter_pct')
ses_vars <- c(ses_vars, 'no_health_insurance_pct', 'no_health_insurance_over_65_pct')
filter_crudeprev <- function(arr) {arr[grep('CrudePrev', arr)]}

established_disease <- c('CANCER_CrudePrev', 'ARTHRITIS_CrudePrev',  'STROKE_CrudePrev', 'CASTHMA_CrudePrev','COPD_CrudePrev', 'CHD_CrudePrev', 'DIABETES_CrudePrev', 'KIDNEY_CrudePrev', 'BPMED_CrudePrev')
disease_prefix <- strsplit(established_disease, '_') %>% map(function(arr) {arr[[1]]}) %>% unlist()
established_risk <- c( 'CSMOKING_CrudePrev', 'BPHIGH_CrudePrev', 'OBESITY_CrudePrev', 'HIGHCHOL_CrudePrev')
risk_prefix <- strsplit(established_risk, '_') %>% map(function(arr) {arr[[1]]}) %>% unlist()


fh_acs <- fh_acs %>% 
  mutate(male_over_65=total_population*male_over_65_pct, 
         female_over_65=female_over_65_pct*total_population,
         female_over_65_SD=sqrt( (1-female_over_65_pct)*female_over_65_pct*total_population ),
         male_over_65_SD=sqrt((1-male_over_65_pct)*male_over_65_pct*total_population)
  )

established_demographics <- c('male_over_65', 'female_over_65')
demographics_prefix <- c('male_over_65', 'female_over_65')

established_cols <- c(established_disease, established_risk, established_demographics)
cols_to_boot <- c(established_cols)
non_na <- complete.cases(fh_acs[, cols_to_boot])
fh_acs_toboot <- fh_acs[non_na, cols_to_boot] 

fh_sd_toboot <- fh_acs[non_na, sprintf('%s_SD', c(disease_prefix, risk_prefix, demographics_prefix))]
pop_corr <- cor(fh_acs[non_na, c(established_disease, established_risk, established_demographics)])
### for every census tract, simulate B datasets from pop_corr and crude_prev using mvtnorm
### for every nth (out of B), estimate the prcomp and then the 1st PC
### the predicted distribution around each tract is the SE

set.seed(1)
ind <- sample(nrow(fh_acs_toboot), 10000) # sample only 10k rows to make it go quickly.
fh_acs_toboot_sample <- fh_acs_toboot[ind, ]
fh_sd_toboot_sample <- fh_sd_toboot[ind, ]

create_score <- function(predicted_pc) {
  score <- rescale(
    rescale(predicted_pc[, 1], to=c(0,100))*.61+rescale(-predicted_pc[, 2], to=c(0,100))*.24, to=c(0,100)
  )
  return(score)
}

sd_for_loading_number <- function(prcomp_list, loading_number=1) {
  # takes in a list of pcs from randomized data and computes the SD
  res <- prcomp_list %>% map(function(x) { abs(x$rotation[,loading_number]) } ) %>% bind_cols() %>% apply(1, sd)
  return(res)
}

error_for_pca <- function(data_set, sd_data_set, correlation, main_data_set, n=100) {
  random_database <- vector("list", length = nrow(data_set) )
  pb <- progress_bar$new(format = "  MVTNORM [:bar] :percent in :elapsed", total = nrow(data_set), clear = FALSE, width= 50)
  for(ii in 1:nrow(data_set)) {
    sds <- as.numeric(sd_data_set[ii, ])
    b <- sds %*% t(sds) 
    cov_for_tract = b * correlation 
    means <- as.matrix(data_set[ii, ])
    random_database[[ii]] <- rmvnorm(n, mean = means, sigma=cov_for_tract) 
    pb$tick()
  }
  
  ### now need to create 1000 (n) datasets for each of the census tracts
  datasets <- vector("list", n)
  m <- ncol(data_set)
  pb <- progress_bar$new(format = "  REARRANGE [:bar] :percent in :elapsed", total = n, clear = FALSE, width= 50)
  for(ii in 1:n) {
    newMatrix <- matrix(nrow=length(random_database), ncol=m)
    for(jj in 1:length(random_database)) {
      newMatrix[jj, ] <- random_database[[jj]][ii, ]
    }
    datasets[[ii]] <- newMatrix
    pb$tick()
  }
  
  prcomp_for_datasets <- datasets %>% map(prcomp, scale.=TRUE, center=TRUE)
  
  
  mDim <- ncol(data_set) 
  loadingSD <- matrix(nrow=mDim, ncol = mDim)
  for(m in 1:mDim) {
    sds <- sd_for_loading_number(prcomp_for_datasets, loading_number = m) 
    loadingSD[, m] <- sds
  }
  
  
  original_pc <- prcomp(main_data_set, scale. = TRUE, center = TRUE)
  original_pc_minus_sd <- original_pc
  original_pc_plus_sd <- original_pc
  original_pc_minus_sd$rotation <- original_pc_minus_sd$rotation-5*loadingSD # go five up and five down .05/30k tests?
  original_pc_plus_sd$rotation <- original_pc_plus_sd$rotation+5*loadingSD
  
  x_original <- predict(original_pc)
  x_minus_sd <- predict(original_pc_minus_sd, main_data_set)
  x_plus_sd <- predict(original_pc_plus_sd, main_data_set)
  
  score_original <- create_score(x_original)
  score_minus_sd <- create_score(x_minus_sd)
  score_plus_sd <- create_score(x_plus_sd)
  
  score_error <- abs(score_plus_sd - score_minus_sd)
  return(score_error)
  
}

score_error <- error_for_pca(fh_acs_toboot_sample, fh_sd_toboot_sample, pop_corr, fh_acs_toboot, 100)
errors <- list(score_error=score_error, non_na=non_na, pop_corr=pop_corr)
write_rds(errors, path = './fh_acs_covid_comm_score_error.rds')
## merge a file with the errors to send to andrew.ai

comm_score_census <- read_rds('./fh_acs_covid_comm_score.rds')
comm_score_census <- comm_score_census %>% mutate(risk_score_error=score_error)
census_error <- comm_score_census %>% group_by(geoid) %>% summarize(risk_score_error=mean(risk_score_error))
city_error <- comm_score_census %>% unite(place_state, placename, stateabbr, sep='|') %>% group_by(place_state) %>% summarize(risk_score_error=mean(risk_score_error))
city_error <- city_error %>% separate(place_state, c('placename', 'stateabbr'), sep="\\|")
state_error <- comm_score_census %>% group_by(stateabbr) %>% summarize(risk_score_error=mean(risk_score_error))
county_error <- comm_score_census %>% group_by(county_code) %>% summarize(risk_score_error=mean(risk_score_error))

write_csv(census_error, path = './fh_acs_covid_comm_score_census_error.csv')
write_csv(city_error, path = './fh_acs_covid_comm_score_city_error.csv')
write_csv(county_error, path = './fh_acs_covid_comm_score_county_error.csv')
write_csv(state_error, path = './fh_acs_covid_comm_score_state_error.csv')

# We simulated the census-tract level prevalence of the different candidate diseases and risk factors. We estimated the standard devidation of the prevalences as a function of the size of the population of the tract and 
# we futher assumed a covariance struvture between the disease prevalences to be the observed population correlation. Next, for each census tract, we simulated 100 times the prevalence of the diseases
# and computed the principal components for each simulation. We obtained a distribution about the principal component "loadings". Next, we obtained the predicted
# new projections for +/- 5 standard deviations of the loadings. The "robustness" score is the range of the score across the +/- 5SD of the loadings.




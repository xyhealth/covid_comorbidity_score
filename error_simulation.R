
library(tidyverse)
library(progress)
library(mvtnorm)

# load data
fh_acs <- read_rds('./fh_acs.rds')
fh_names <- read_rds('./fh_orig_tract.rds')
fh_acs <- fh_acs %>% left_join(fh_names, by = c('geoid'='fips_tract'))
place_vars <- names(fh_names)


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
established_demographics <- c('male_over_65_pct', 'female_over_65_pct')

established_cols <- c(established_disease, established_risk, established_demographics)
cols_to_boot <- c(established_cols, "total_population")

non_na <- complete.cases(fh_acs[, cols_to_boot])
fh_acs_toboot <- fh_acs[non_na, cols_to_boot] 
fh_sd_toboot <- fh_acs[non_na, sprintf('%s_SD', c(disease_prefix, risk_prefix))]

pop_corr <- cor(fh_acs[non_na, c(established_disease, established_risk)])
### for every census tract, simulate B datasets from pop_corr and crude_prev using mvtnorm
### for every nth (out of B), estimate the prcomp and then the 1st PC
### the predicted distribution around each tract is the SE

n <- 1000
random_database <- vector("list", length = nrow(fh_acs_toboot) )
pb <- progress_bar$new(format = "  MVTNORM [:bar] :percent in :elapsed", total = nrow(fh_acs_toboot), clear = FALSE, width= 50)
for(ii in 1:nrow(fh_acs_toboot)) {
  sds <- as.numeric(fh_sd_toboot[ii, ])
  b <- sds %*% t(sds) 
  cov_for_tract = b * pop_corr 
  means <- as.matrix(fh_acs_toboot[ii, c(established_disease, established_risk)])
  random_database[[ii]] <- rmvnorm(n, mean = means, sigma=cov_for_tract) 
  pb$tick()
}

### now need to create 1000 (n) datasets for each of the census tracts
datasets <- vector("list", n)
m <- length(c(established_disease, established_risk))
pb <- progress_bar$new(format = "  REARRANGE [:bar] :percent in :elapsed", total = n, clear = FALSE, width= 50)
for(ii in 1:n) {
  newMatrix <- matrix(nrow=length(random_database), ncol=m)
  for(jj in 1:length(random_database)) {
    newMatrix[jj, ] <- random_database[[jj]][ii, ]
  }
  datasets[[ii]] <- newMatrix
  pb$tick()
}
saveRDS(datasets, file='./error_simulation/error_simulation_data.rds')
datasets <- read_rds('./error_simulation/error_simulation_data.rds')
# now conduct 1000 PCs
prcomp_for_datasets <- datasets %>% map(prcomp)
prcomp_predicted_for_datasets <- prcomp_for_datasets %>% map(predict, fh_acs_toboot[, c(established_disease, established_risk)])
save(prcomp_for_datasets, prcomp_predicted_for_datasets, file='error_simulation_prcomp.Rdata')

load('./error_simulation/error_simulation_prcomp.Rdata')
### now get the PCs from the simulations
first_simulated_pc <-  matrix(nrow=nrow(fh_acs_toboot), ncol=length(prcomp_predicted_for_datasets))
second_simulated_pc <-  matrix(nrow=nrow(fh_acs_toboot), ncol=length(prcomp_predicted_for_datasets))
for(ii in 1:length(prcomp_predicted_for_datasets)) {
  first_simulated_pc[, ii] <- prcomp_predicted_for_datasets[[ii]][, 1]
  second_simulated_pc[, ii] <- prcomp_predicted_for_datasets[[ii]][, 2]
}

orig_pc <- prcomp(fh_acs_toboot[, c(established_disease, established_risk)])
pred <- predict(orig_pc, fh_acs_toboot[, c(established_disease, established_risk)])
orig_pc$x[1,1]
quantile(abs(first_simulated_pc[1,]), probs=c(.05, .95))
orig_pc$x[2,1]
quantile(abs(first_simulated_pc[2,]), probs=c(.05, .95))
orig_pc$x[3,1]
quantile(abs(first_simulated_pc[3,]), probs=c(.05, .95))

sd_for_tracts <- apply(first_simulated_pc, 1, function(x) { sd(abs(x))})


fh_acs_toboot <- cbind(fh_acs_toboot, sd_for_tracts)






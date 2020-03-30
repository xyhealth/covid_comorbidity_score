# Chirag Patel
# 03/29/20
# 

library(tidyverse)
library(progress)

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
cols_to_boot <- c(established_cols)

non_na <- complete.cases(fh_acs[, cols_to_boot])
fh_acs_toboot <- fh_acs[non_na, cols_to_boot] 
fh_sd_toboot <- fh_acs[non_na, sprintf('%s_SD', c(disease_prefix, risk_prefix))]
pop_sizes <- fh_acs[non_na, 'total_population'] 
###


boot_pca_for_loadings <- function(df,B) {
  set.seed(123)
  ll <- vector(mode = "list", length = B)
  pb <- progress_bar$new(format = "  boot [:bar] :percent in :elapsed", total = B, clear = FALSE, width= 50)
  for (i in seq_len(B)) {
    tempdf  <- df[sample(nrow(df), replace = TRUE), ]
    ll[[i]] <- abs(prcomp(tempdf)$rotation) 
    pb$tick()
  }
  return(ll)
}
ll <- boot_pca_for_loadings(fh_acs_toboot, 1000)
data.frame(apply(simplify2array(ll), 1:2, quantile, probs = 0.025))[,1]
data.frame(apply(simplify2array(ll), 1:2, quantile, probs = 0.975))[,1]

### do it for 15-4200
ll_1 <- boot_pca_for_loadings(fh_acs_toboot[pop_sizes <= 4200,] , 1000)
ll_2 <- boot_pca_for_loadings(fh_acs_toboot[pop_sizes > 4200,] , 1000)
data.frame(apply(simplify2array(ll_1), 1:2, quantile, probs = 0.025))[,1]
data.frame(apply(simplify2array(ll_1), 1:2, quantile, probs = 0.975))[,1]

original_large <- prcomp(fh_acs_toboot[pop_sizes >= 4200, ])
data.frame(apply(simplify2array(ll_2), 1:2, quantile, probs = 0.025))[,1]
data.frame(apply(simplify2array(ll_2), 1:2, quantile, probs = 0.975))[,1]





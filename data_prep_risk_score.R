## data renaming and preparation
library(tidyverse)
# load data
fh_acs <- read_rds('./fh_acs.rds')
fh_names <- read_rds('./fh_orig_tract.rds')
fh_acs <- fh_acs %>% left_join(fh_names, by = c('geoid'='fips_tract'))
place_vars <- names(fh_names)
fh_acs <- fh_acs %>%  mutate(county_code =str_sub(geoid, 1, 5))
fh_acs <- fh_acs %>%  mutate(state_code =str_sub(geoid, 1, 2))

fh_acs <- fh_acs %>% group_by(geoid) %>% slice(1) %>% ungroup() # grab only the unique geoid

fh_vars_all <- names(fh_acs)[grep('Crude', names(fh_acs))]
fh_acs[, fh_vars_all] <- fh_acs[, fh_vars_all]/100 # get it to fraction units

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

fh_behavior <- c('BINGE', 'SLEEP', 'CSMOKING')
fh_disease <- c('ARTHRITIS', 'CANCER', 'CASTHMA', 'CHD', 'COPD', 'DIABETES', 'KIDNEY', 'TEETHLOST', 'STROKE')
fh_risk <- c('OBESITY', 'BPHIGH', 'LPA', 'HIGHCHOL')
fh_access <- c('ACCESS2', 'BPMED', 'CHECKUP', 'CHOLSCREEN', 'COLON_SCREEN', 'COREM', 'COREW', 'MAMMOUSE', 'MHLTH', 'PHLTH', 'PAPTEST')

fh_behavior <- fh_vars[fh_behavior %>% map(grep, fh_vars) %>% unlist()]
fh_disease <- fh_vars[fh_disease %>% map(grep, fh_vars) %>% unlist()]
fh_risk <- fh_vars[fh_risk %>% map(grep, fh_vars) %>% unlist()]
fh_access <- fh_vars[fh_access %>% map(grep, fh_vars) %>% unlist()]

## fix column names
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
established_disease <- c('CANCER_CrudePrev', 'ARTHRITIS_CrudePrev',  'STROKE_CrudePrev', 'CASTHMA_CrudePrev','COPD_CrudePrev', 'CHD_CrudePrev', 'DIABETES_CrudePrev', 'KIDNEY_CrudePrev', 'BPMED_CrudePrev')
established_risk <- c( 'CSMOKING_CrudePrev', 'BPHIGH_CrudePrev', 'OBESITY_CrudePrev', 'HIGHCHOL_CrudePrev')
established_demographics <- c('male_over_65_pct', 'female_over_65_pct')
established_disease_se <- c('CANCER_SE', 'ARTHRITIS_SE',  'STROKE_SE', 'CASTHMA_SE','COPD_SE', 'CHD_SE', 'DIABETES_SE', 'KIDNEY_SE', 'BPMED_SE')
established_risk_se <- c( 'CSMOKING_SE', 'BPHIGH_SE', 'OBESITY_SE', 'HIGHCHOL_SE')
filter_crudeprev <- function(arr) {arr[grep('CrudePrev',arr)]}
established_cols <- c(established_disease, established_risk, established_demographics)
non_na <- complete.cases(fh_acs[, established_cols])
fh_acs_established <- fh_acs[non_na, established_cols]
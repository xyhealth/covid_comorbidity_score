# Chirag J Patel
# chirag@xy.ai
# prepare data for comorbidindex by querying EDW: merge ACS with 500 cities
# 03/21/20

library(RPostgreSQL)
library(postGIStools)
library(tidyverse)
library(jsonlite)
library(sf)
library(tictoc)

load('acs.Rdata')

con <- dbConnect(PostgreSQL(), dbname = "chiraglab", user = "root",
                 host ="xy-ai-server-02-06-2020.ccp7icrordwn.us-east-1.rds.amazonaws.com",
                 password = "wUF9WvjYLbgy3kFJ")


fh_cities_original <- get_postgis_query(con, 'select stateabbr, placename, fips_tract, fips_place_tract, lat, long from edw.fivehundredcities_data_2016_2017') 

fh_shape_sql <- "select a.data_id,a.fact_id,a.startdate, a.locationid, b.shape_id, b.geometrywkt as fh_geometrywkt 
from exposome_pici.facttable_general a 
inner join exposome_pici.shapefile b on (a.shape_id=b.shape_id) 
where a.datasource = \'500 Cities\' and a.startdate >= \'2016-01-01\' and b.summarylevelid = '140'"
fh_shape <- get_postgis_query(con, fh_shape_sql, geom_name = 'fh_geometrywkt')

fh_cities_sql <- "select a.fact_id, a.data_id, a.startdate, a.enddate, a.locationid, a.shape_id, (JSONB_EACH(a.data)).key, (JSONB_EACH(a.data)).value from exposome_pici.facttable_general a 
where a.datasource = \'500 Cities\' and a.startdate >= \'2016-01-01\'"
fh <- get_postgis_query(con, fh_cities_sql)
done <- dbDisconnect(con)


fh_cities <- spread(fh, key, value)


fhc_acs <- big_acs_data %>% mutate(geoid = str_sub(locationid, start=8)) %>% right_join(fh_cities, by=c('geoid'='locationid'), suffix=c('_acs', '_fh'))

## now process the data
#"median_household_income"            
#"pct_college"                         "pct_no_highschool"                   "pct_below_poverty"                   "pct_unemployed"                     
# "pct_more_than_one_occupant_per_room" "median_home_value"                   "median_age"                          "pct_white"                          
# "pct_black"                           "pct_native_american"                 "pct_asian"                           "pct_hawaiian_pacific_islander"      
#"pct_other"                           "pct_multiracial"                     "pct_public_assistance"               "gini_index"                         
# "pct_private_insurance"               "pct_medicare_insurance"              "pct_medicaid_insurance"              "pct_military_va_insurance"          
# "pct_private_and_medicare_insurance"  "pct_medicare_and_medicare_insurance" "PC1"                                 "PC2"                                
#"PC3" 

#age_and_sex <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B01001\'') - DONE
#income <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B19013\'') - DONE
#education <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B15003\'') - DONE
#race <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'C02003\'') - DONE
#insurance <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B27001\'') - DONE
#gini_index <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B19083\'') - DONE
#occupant_per_room <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B25014\'') - DONE
#employment <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B23025\'') - DONE
#poverty <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B17001\'') - DONE
#race <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B02001\'') - DONE
# median value of housing: B25077 - DONE
# hispanic B03001

## convert to numeric
prev_cols <- grep('Crude',names(fhc_acs))
for(col_num in prev_cols) {
  fhc_acs[, col_num] <- as.numeric(fhc_acs[, col_num])
}

acs_cols <- tolower(unique(big_meta_data$variable_name))
for(acs_col in acs_cols) {
  fhc_acs[, acs_col] <- as.numeric(fhc_acs[, acs_col])
}

vars <- c('gini_index')
# Gini index:
fhc_acs <- fhc_acs %>% mutate(gini_index=b19083001)
# median income
# B19013
fhc_acs <- fhc_acs %>% mutate(median_income=b19013001)
vars <- c(vars, 'median_income')
#median home value
# B25077
fhc_acs <- fhc_acs %>% mutate(median_home_value=b25077001) 
vars <- c(vars, 'median_home_value')

# proportion greater than 65, males and females
# B01001
fhc_acs <- fhc_acs %>% mutate(total_males = b01001002, total_females=b01001026)
fhc_acs <- fhc_acs %>% mutate(male_over_65_pct = (b01001020 + b01001021 + b01001022 + b01001023 + b01001024 + b01001025) / total_males)
fhc_acs <- fhc_acs %>% mutate(female_over_65_pct = (b01001044 + b01001045 + b01001046 + b01001047 + b01001048 + b01001049) / total_females)
vars <- c(vars, 'male_over_65_pct', 'female_over_65_pct')
# race
# C02003
fhc_acs <- fhc_acs %>% mutate(white_pct=c02003003 / c02003001, 
                              african_american_pct = c02003004 / c02003001, 
                              american_indian_pct = c02003005 / c02003001,
                              asian_pct = c02003006 / c02003001,
                              hawaiian_pacific_islander_pct = c02003007 / c02003001,
                              other_race_pct = c02003008 / c02003001,
                              two_or_more_race_pct = c02003009 / c02003001)
vars <- c(vars, 'white_pct', 'african_american_pct', 'american_indian_pct', 'asian_pct', 'hawaiian_pacific_islander_pct', 'other_race_pct', 'two_or_more_race_pct')
# Hispanic
fhc_acs <- fhc_acs %>% mutate(hispanic_pct=b03001003 / b03001001, 
                              mexican_pct = b03001004 / b03001001, 
                              puerto_rican_pct = b03001005 / b03001001,
                              cuban_pct = b03001006 / b03001001,
                              dominican_pct = b03001007 / b03001001,
                              central_american_pct = b03001008 / b03001001,
                              south_american_pct = b03001016 / b03001001,
                              other_hispanic_pct = b03001027 / b03001001)
vars <- c(vars, 'hispanic_pct', 'mexican_pct', 'puerto_rican_pct', 'cuban_pct', 'dominican_pct', 'central_american_pct', 'south_american_pct', 'other_hispanic_pct')

# education 
fhc_acs <- fhc_acs %>% mutate(less_than_high_school_pct= (b15003002 + b15003003 + b15003004 + b15003005 + b15003006 + b15003007 + b15003008 + b15003009 + b15003010 + b15003011 + b15003012 + b15003013 + b15003014 + b15003015 + b15003016) / b15003001)
fhc_acs <- fhc_acs %>% mutate(college_pct= (b15003021 + b15003022 + b15003023 + b15003024 + b15003025) / b15003001)
vars <- c(vars, 'less_than_high_school_pct', 'college_pct')

#poverty 
fhc_acs <- fhc_acs %>% mutate(at_below_poverty_pct= (b17001003 + b17001017 ) / b17001001)
fhc_acs <- fhc_acs %>% mutate(at_below_poverty_over_65_pct= (b17001015 + b17001016 + b17001029 + b17001030) / b17001001)
vars <- c(vars, 'at_below_poverty_pct', 'at_below_poverty_over_65_pct')

# employment
fhc_acs <- fhc_acs %>% mutate(unemployment_pct= (b23025005 ) / b23025001)
fhc_acs <- fhc_acs %>% mutate(non_employment_pct= (b23025007 ) / b23025001)
vars <- c(vars, 'unemployment_pct', 'non_employment_pct')

# occupant per room total
fhc_acs <- fhc_acs %>% mutate(more_than_one_occupant_per_room_pct= (b25014005 + b25014006 + b25014007 + b25014011 + b25014012 + b25014013) / b25014001)
fhc_acs <- fhc_acs %>% mutate(more_than_one_occupant_per_room_renter_pct= (b25014011 + b25014012 + b25014013) / b25014008) 
vars <- c(vars, 'more_than_one_occupant_per_room_pct', 'more_than_one_occupant_per_room_renter_pct')

# insurance 
fhc_acs <- fhc_acs %>% mutate(no_health_insurance_pct= (b27001005 + b27001008 + b27001011 + b27001014 + b27001017 + b27001020 + b27001023 + b27001026 + b27001029 + b27001033 + b27001036 + b27001039 + b27001042 + b27001045 + b27001048 + b27001051 + b27001054 + b27001057) / b27001001)
fhc_acs <- fhc_acs %>% mutate(no_health_insurance_over_65_pct= (b27001026 + b27001029 + b27001054 + b27001057) / b27001001 )
vars <- c(vars, 'no_health_insurance_pct', 'no_health_insurance_over_65_pct')


saveRDS(fhc_acs, file='fh_acs.rds')
saveRDS(fh_cities, file='fh_cities.rds')
saveRDS(fh_shape, file='fh_shape.rds')
saveRDS(fh_cities_original, file='fh_orig_tract.rds')

library(RPostgreSQL)
library(postGIStools)
library(tidyverse)
library(sf)
library(tictoc)

con <- dbConnect(PostgreSQL(), dbname = "chiraglab", user = "root",
                 host ="xy-ai-server-02-06-2020.ccp7icrordwn.us-east-1.rds.amazonaws.com",
                 password = "wUF9WvjYLbgy3kFJ")


age_and_sex_meta_tbl <- get_postgis_query(con, 'select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'B01001\'')
age_and_sex_json <- fromJSON(age_and_sex_meta_tbl$measurement)


#"median_household_income"            
#"pct_college"                         "pct_no_highschool"                   "pct_below_poverty"                   "pct_unemployed"                     
# "pct_more_than_one_occupant_per_room" "median_home_value"                   "median_age"                          "pct_white"                          
# "pct_black"                           "pct_native_american"                 "pct_asian"                           "pct_hawaiian_pacific_islander"      
#"pct_other"                           "pct_multiracial"                     "pct_public_assistance"               "gini_index"                         
# "pct_private_insurance"               "pct_medicare_insurance"              "pct_medicaid_insurance"              "pct_military_va_insurance"          
# "pct_private_and_medicare_insurance"  "pct_medicare_and_medicare_insurance" "PC1"                                 "PC2"                                
#"PC3"                                 "PC4"                                 "deprivation_index"                  

# total male over 60:
# B01001018 (60-61)
# B01001019 (62-64)
# B01001020 (65-66)
# B01001021 (67-69)
# B01001022 (70-74)
# B01001023 (75-79)
# B01001024 (80-84)
# B01001025 (85-over)

# total female:
# B01001026
# total female over 60:
# B01001042 (60-61)
# B01001043 (62-64)
# B01001044 (65-66)
# B01001045 (67-69)
# B01001046 (70-74)
# B0100147 (75-79)
# B01001048 (80-84)
# B01001049 (85-over)

cols <- 'B01001001' # to B---49
col_nums <- c(paste('0', 1:9, sep=""), 10:49)
age_cols <- paste('B010010', col_nums, sep='')
age_col_q <- paste(sprintf('a.data ->> \'%s\' as %s', age_cols, age_cols), collapse=",")


age_sex_temp_table_sql <- sprintf("create temp table acs_age_shape_temp as select a.fact_id,
a.data_id, a.startdate, a.enddate, a.locationid, a.shape_id, b.geometrywkt,
st_area(b.geographywkt)/1000000 as total_area_km_2,
%s
from exposome_pici.facttable_acs a
inner join exposome_pici.shapefile b on (a.shape_id=b.shape_id)
where b.summarylevelid = '140'
and a.data_id = 111033
and a.startdate = '2013-01-01 00:00:00'
and a.enddate = '2017-12-31 00:00:00'", age_col_q);

rs <- dbSendStatement(con, age_sex_temp_table_sql)
rs <- dbSendStatement(con, 'create index acs_age_temp_idx on acs_age_shape_temp using GIST(geometrywkt)')
dbHasCompleted(rs)

fh_temp_shape_sql <- "
create temp table fh_shape_temp as select a.data_id,a.fact_id, a.startdate, a.locationid, b.shape_id, b.geometrywkt as fh_geometrywkt 
from exposome_pici.facttable_general a 
inner join exposome_pici.shapefile b on (a.shape_id=b.shape_id) 
where a.datasource = \'500 Cities\' and a.startdate >= \'2016-01-01\' and b.summarylevelid = '140'"

rs <- dbSendStatement(con, fh_temp_shape_sql)
rs <- dbSendStatement(con, 'create index fh_temp_idx on fh_shape_temp using GIST(fh_geometrywkt)')
dbHasCompleted(rs)

fh_acs_shape_sql <- "select fh.*, b.*, st_area(st_intersection(ST_MakeValid(fh.fh_geometrywkt), ST_MakeValid(b.geometrywkt)))/st_area(fh.fh_geometrywkt) as pct_overlap
from fh_shape_temp as fh inner join acs_age_shape_temp b on (ST_OVERLAPS(fh.fh_geometrywkt, b.geometrywkt))
where st_area(st_intersection(ST_MakeValid(fh.fh_geometrywkt), ST_MakeValid(b.geometrywkt)))/st_area(b.geometrywkt) >= .05"

tic('acs fh shape');
acs_500cities_overlap <- get_postgis_query(con, fh_acs_shape_sql)
toc()

dbDisconnect(con)
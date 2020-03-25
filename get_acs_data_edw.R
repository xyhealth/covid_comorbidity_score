# Chirag J Patel
# chirag@xy.ai
# prepare data for comorbidindex by querying EDW: ACS data


library(RPostgreSQL)
library(postGIStools)
library(tidyverse)
library(jsonlite)
library(sf)
library(tictoc)
library(getopt)
# get options, using the spec as defined by the enclosed list. # we read the options from the default: commandArgs(TRUE). 
spec = matrix(c(
'table_name', 't', 1, "character"
), byrow=TRUE, ncol=4)
opt <- getopt(spec)
#"median_household_income"            
#"pct_college"                         "pct_no_highschool"                   "pct_below_poverty"                   "pct_unemployed"                     
# "pct_more_than_one_occupant_per_room" "median_home_value"                   "median_age"                          "pct_white"                          
# "pct_black"                           "pct_native_american"                 "pct_asian"                           "pct_hawaiian_pacific_islander"      
#"pct_other"                           "pct_multiracial"                     "pct_public_assistance"               "gini_index"                         
# "pct_private_insurance"               "pct_medicare_insurance"              "pct_medicaid_insurance"              "pct_military_va_insurance"          
# "pct_private_and_medicare_insurance"  "pct_medicare_and_medicare_insurance" "PC1"                                 "PC2"                                
#"PC3" 


con <- dbConnect(PostgreSQL(), dbname = "chiraglab", user = "root",
                 host ="xy-ai-server-02-06-2020.ccp7icrordwn.us-east-1.rds.amazonaws.com",
                 password = "wUF9WvjYLbgy3kFJ")

##### ACS
tableName <- opt$table_name 
print(tableName)
meta_tbl <- get_postgis_query(con, sprintf('select * from exposome_pici.datatable where datasource = \'ACS\' and timeframe_unit = 5 and fact_identification = \'%s\'', tableName))
#B01001
get_acs_table_from_json <- function(con, meta_tabl_data) {
  jsonMeasurement <- fromJSON(meta_tabl_data$measurement)
  data_id <- meta_tabl_data$data_id[1]
  cols <- names(jsonMeasurement$measurement)
  #print(cols)
  col_q <- paste(sprintf('a.data ->> \'%s\' as %s', cols, cols), collapse=",")
  #sql <- sprintf("select a.fact_id, a.data_id, a.startdate, a.enddate, a.locationid, a.shape_id, st_area(b.geographywkt)/1000000 as total_area_km_2,
  #        %s
  #        from exposome_pici.facttable_acs a
  #        inner join exposome_pici.shapefile b on (a.shape_id=b.shape_id)
   #       where b.summarylevelid = '140'
  #        and a.data_id = %i
   #       and a.startdate = '2013-01-01 00:00:00'
  #        and a.enddate = '2017-12-31 00:00:00'", col_q, data_id)
  
  sql <- sprintf("select a.fact_id, a.data_id, a.startdate, a.enddate, a.locationid, a.shape_id, st_area(b.geographywkt)/1000000 as total_area_km_2,
          %s
          from exposome_pici.facttable_acs a
          inner join exposome_pici.shapefile b on (a.shape_id=b.shape_id)
          where b.summarylevelid = '140'
          and a.data_id = %i
          and a.startdate = '2014-01-01 00:00:00'
          and a.enddate = '2018-12-31 00:00:00'", col_q, data_id)
  
  
  dat <- get_postgis_query(con, sql)
}


cat(format(Sys.time(), "%a %b %d %X %Y"))
cat("\n")
tic(tableName)
tabl <- get_acs_table_from_json(con, meta_tbl)
toc()
fileOut <- sprintf('%s.Rdata', tableName)
save(tabl, meta_tbl, file=fileOut)
done <- dbDisconnect(con)

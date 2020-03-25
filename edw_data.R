# create 500 cities file
# Chirag J Patel
# chirag@xy.ai

library(RPostgreSQL)
library(postGIStools)
library(tidyverse)

con <- dbConnect(PostgreSQL(), dbname = "chiraglab", user = "root",
                 host ="xy-ai-server-02-06-2020.ccp7icrordwn.us-east-1.rds.amazonaws.com",
                 password = "wUF9WvjYLbgy3kFJ")

#### older one going after the edw schema 
fh_cities <- get_postgis_query(con, 'select * from edw.fivehundredcities_data_2016_2017') 
census <- get_postgis_query(con, 'select * from edw.ses_census_tract');
census_geo <- get_postgis_query(con, 'select shape_id, geoid, st_area(geographywkt)/1000000 as total_area_km_2 from edw.ses_census_tract_2015');
census <- census %>% left_join(census_geo, by='shape_id')
fh_cities$geoid <- str_split(fh_cities$fips_place_tract, '-', simplify=T)[, 2]
fh_cities <- fh_cities %>% left_join(census, by='geoid')
write_csv(fh_cities, path='fh_cities_census.csv')


### new one

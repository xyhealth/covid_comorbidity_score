library(sf)
library(readr)
fh_orig_tract <- read_rds('fh_orig_tract.rds')
fh_shape <- read_rds('fh_shape.rds')
fh_score <- read_rds('fh_acs_covid_comm_score.rds')
fh_sf <- st_as_sf(fh_shape)

fh_sf <- fh_sf %>% left_join(fh_score, by=c("locationid"="fips_tract"))
st_write(fh_sf, "fh.shp", driver="ESRI Shapefile")
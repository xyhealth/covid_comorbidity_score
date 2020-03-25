# Chirag J Patel
# chirag@xy.ai
# prepare data for comorbidindex by querying EDW: ACS data

# collect ACS dataframes and save it to a file
# see get_acs_data_edw.R
library(tidyverse)
library(jsonlite)

convert_to_frame <- function(meta_tbl) {
  j <- fromJSON(meta_tbl$measurement)
  jj <- unlist(j$measurement)
  metaFrame <- tibble(type=names(jj), type_of_data=jj)
  variable_type <- str_split(metaFrame$type, '\\.', simplify=T)[, 2]
  variable_name <- str_split(metaFrame$type, '\\.', simplify=T)[, 1]
  metaFrame <- metaFrame %>% select(-type)
  metaFrame$variable_type <- variable_type
  metaFrame$variable_name <- variable_name
  metaFrame
}


acs_files <- list.files('.', pattern='*.Rdata')
tbls <- acs_files %>% map(function(filename) {
  print(filename)
  load(filename)
  return(tabl)
})


meta_tbls <- acs_files %>% map(function(filename) {
  load(filename)
  return(convert_to_frame(meta_tbl))
})



##
the_rest <- tbls[2:length(tbls)] %>% map(select, -c(fact_id, data_id, startdate, enddate, locationid, total_area_km_2))
tbls <- c(tbls[1], the_rest)
big_acs_data <- tbls %>% reduce(left_join,by='shape_id')
big_meta_data <- meta_tbls %>% bind_rows()
save(big_acs_data, big_meta_data, file='acs.Rdata')




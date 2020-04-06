

library(tidyverse)

built_by_tract <- read_csv('./dl/xydl_risk_score_tract_predictions_500Cities_VGG_static-images.csv')
built_by_tract <- built_by_tract %>% select(-X1)

fh_acs <- read_rds('./fh_acs.rds')

fh_acs <- fh_acs %>% left_join(built_by_tract, by=c('geoid'='tractid'))

fh_acs <- fh_acs %>% mutate(built_residual = predict-true)

p <- ggplot(fh_acs, aes(median_income, built_residual))
p <- p + geom_point(alpha=.5)
p
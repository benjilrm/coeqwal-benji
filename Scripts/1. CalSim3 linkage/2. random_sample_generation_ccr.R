#Random sample generation for manual data collection round 1 (CCR)

#Load list of surface water reliant systems filtered by counties most likely to connected to SWP or CVP
Systems <- read.csv("Data_raw/cc_sw_systems_082724_countyfiltered.csv")
Systems$county <- as.factor(Systems$county)
Systems$clearinghouse_water_type <- as.factor(Systems$clearinghouse_water_type)

#Create factor variable based on EPA size classifications
Systems <- Systems %>%
  mutate(pop_cat = as.factor(case_when(
      Systems$population == 0 | Systems$population == 1 ~ "wholesale",
      Systems$population > 1 & Systems$population <= 500 ~ "very_small",
      Systems$population > 500 & Systems$population <= 3300 ~ "small",
      Systems$population > 3300 & Systems$population <= 10000 ~ "medium",
      Systems$population > 10000 & Systems$population <= 100000 ~ "large",
      Systems$population > 100000 ~ "very_large")))

#Random sample of 105 stratified by county, water source and total population (~16% of full list)
library(dplyr)
set.seed(1990)
subsample105 <- Systems %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .25, replace = FALSE, weight = NULL)

#Random sample from the above sub sample for chatGPT prompt refinement and testing stratified by county, water and total population with over sampling from small and very small systems (they are getting cut out by sample_frac due to small group size I think)
set.seed(1990)
prompt_testing <- subsample105 %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .25, replace = FALSE, weight = NULL)

set.seed(1990)
prompt_testing_oversample <- subsample105 %>% 
  filter(pop_cat == "very_small" | pop_cat == "small") %>%
  filter(!clearinghouse_id %in% prompt_testing$clearinghouse_id) %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .17, replace = FALSE, weight = NULL)

prompt_testing <- rbind(prompt_testing, prompt_testing_oversample)

#save lists
write.csv(subsample105, "Data_processed/manualdatacollectionsample1.csv")
write.csv(prompt_testing, "Data_processed/prompttestingsample1.csv")

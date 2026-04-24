#Random sample generation for manual data collection round 2 (UWMPs)

#Load list of surface water reliant systems filtered by counties most likely to connected to SWP or CVP (not using updated list with three added systems because those don't have populations to filter by but also are certainly not Urban water providers)
Systems <- read.csv("Data_raw/cc_sw_systems_082724_countyfiltered.csv")
Systems$county <- as.factor(Systems$county)
Systems$clearinghouse_water_type <- as.factor(Systems$clearinghouse_water_type)

#Filter to only those systems big enough to be required to do urban water management plans

#Create factor variable based on EPA size classifications
Systems <- Systems %>%
  mutate(pop_cat = as.factor(case_when(
    Systems$total_population == 0 | Systems$total_population == 1 ~ "wholesale",
    Systems$total_population > 1 & Systems$total_population <= 500 ~ "very_small",
    Systems$total_population > 500 & Systems$total_population <= 3300 ~ "small",
    Systems$total_population > 3300 & Systems$total_population <= 10000 ~ "medium",
    Systems$total_population > 10000 & Systems$total_population <= 100000 ~ "large",
    Systems$total_population > 100000 ~ "very_large")))

Bigsystems <- Systems %>% filter(service_connections >= 3000 | total_population <= 1 | total_population >30000) #not perfect but good enough for now. Could try to get an actual list from the state for this. 

#Save this list 
write_csv(Bigsystems, "Data_processed/Large_potentialsurfacesystems.csv")

#ACcording to UWMP website there are 450 providers that submit these so aiming for a random sample of no less than 45 stratified by county, water source and total population. Oversample for medium and wholesale systems so at least a few of those are included
library(dplyr)
set.seed(1990)
subsample45 <- Bigsystems %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .26, replace = FALSE, weight = NULL) 

set.seed(1990)
subsample45_oversample1 <- Bigsystems %>% 
  filter(pop_cat == "wholesale") %>%
  filter(!clearinghouse_id %in% subsample45$clearinghouse_id) %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .5, replace = FALSE, weight = NULL)

set.seed(1990)
subsample45_oversample2 <- Bigsystems %>% 
  filter(pop_cat == "medium") %>%
  filter(!clearinghouse_id %in% subsample45$clearinghouse_id) %>%
  sample_frac(size = .2, replace = FALSE, weight = NULL)

subsample45 <- rbind(subsample45, subsample45_oversample1, subsample45_oversample2)

#Random sample from the above sub sample for chatGPT prompt refinement and testing stratified by county, water and total population with oversampling to get a medium system and a wholesaler for diversity
set.seed(1990)
prompt_testing <- subsample45 %>%
  group_by(county, pop_cat, clearinghouse_water_type) %>%
  sample_frac(size = .18, replace = FALSE, weight = NULL)

set.seed(1990)
prompt_testing_oversample1 <- subsample45 %>% 
  filter(pop_cat == "medium" | pop_cat == "wholesale") %>%
  sample_frac(size = .6, replace = FALSE, weight = NULL)

prompt_testing <- rbind(prompt_testing, prompt_testing_oversample1)


#save lists
write.csv(subsample45, "Data_processed/manualdatacollectionsample2.csv")
write.csv(prompt_testing, "Data_processed/prompttestingsample2.csv")

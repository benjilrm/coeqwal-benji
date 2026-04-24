#Pivot cleaned AI data in wide format to longer format for final cleaning steps before filtering out sources and combining data sources

library(tidyverse)

#Test
#Pivot longer
#Clean_data_longer <- final_data_clean %>% pivot_longer(cols = starts_with("source"), 
                                                      # names_to =  c("source_number", ".value"), 
                                                      # names_pattern = "source_(\\d+)_(.+)")
#Clean_data_longer <- na.omit(Clean_data_longer)
#Clean_data_longer$type <- as.factor(Clean_data_longer$type)

#write.csv(Clean_data_longer, "Data_processed/draftpivotsources_jan22.csv")

#2022 CCR
TwentyTwo <- read.csv("Data_processed/CCR_2022_updated_cleaned.csv")
TwentyTwo_long <- TwentyTwo %>% pivot_longer(cols = starts_with("source"), 
                                             names_to =  c("source_number", ".value"), 
                                             names_pattern = "source_(\\d+)_(.+)")

TwentyTwo_long <- na.omit(TwentyTwo_long)

TwentyTwo_long$PWSID <- as.factor(TwentyTwo_long$PWSID)
nlevels(TwentyTwo_long$PWSID) #809 systems, 1334 unique sources. Not bad!

write.csv(TwentyTwo_long, "Data_processed/TwentyTwo_long.csv") #export csv for last cleaning steps: 1) make sure none of the non potable water sources are counted as percent of water supply (so we can use percent of potable supply); 2) remove source types that are not surface water or purchased (removed purchased water only when specified it is groundwater). ALso removed banked groundwater, desalinated water and GW under the influence of surface water. Also git rid of any data that isn't 2022 or 2023

#2023 CCR
TwentyThree <- read.csv("Data_processed/CCR_2023_updated_cleaned.csv")
TwentyThree_long <- TwentyThree %>% pivot_longer(cols = starts_with("source"), 
                                             names_to =  c("source_number", ".value"), 
                                             names_pattern = "source_(\\d+)_(.+)")

TwentyThree_long <- na.omit(TwentyThree_long)

TwentyThree_long$PWSID <- as.factor(TwentyThree_long$PWSID)
nlevels(TwentyThree_long$PWSID) #783 systems, 1334 unique sources. 

write.csv(TwentyThree_long, "Data_processed/TwentyThree_long.csv") #export csv for last cleaning steps: 1) make sure none of the non potable water sources are counted as percent of water supply (so we can use percent of potable supply); 2) remove source types that are not surface water or purchased (removed purchased water only when specified it is groundwater). Also removed banked groundwater, desalinated water and GW under the influence of surface water. Also got rid of any data that isn't 2022 or 2023

#upload cleaned CSVs back in. Figure out how to calculate the number or surface water/purchased sources per system, add data source column, remove source number column? 

#2022 CCR data
TwentyTwo_long_cleaned <- read.csv("Data_processed/TwentyTwo_long_cleaned_notSWorpurchasedremoved.csv")
TwentyTwo_long_cleaned$PWSID <- as.factor(TwentyTwo_long_cleaned$PWSID)
TwentyTwo_long_cleaned <-  TwentyTwo_long_cleaned[,-1]
nlevels(TwentyTwo_long_cleaned$PWSID) #609 systems, 727 sources 

#2023 CCR data
TwentyThree_long_cleaned <- read.csv("Data_processed/TwentyThree_long_cleaned_notSWorpurchasedremoved.csv")
TwentyThree_long_cleaned$PWSID <- as.factor(TwentyThree_long_cleaned$PWSID)
TwentyThree_long_cleaned <-  TwentyThree_long_cleaned[,-1]
nlevels(TwentyThree_long_cleaned$PWSID) #568 systems, 681 sources

#UWMP data
UWMP <- read.csv("Data_processed/UWMP_2020_clean_combinedwithmanual.csv")
UWMP$source_11_usage <- as.character(UWMP$source_11_usage)

UWMP_long <- UWMP %>% pivot_longer(cols = starts_with("source"), 
                                                 names_to =  c("source_number", ".value"), 
                                                 names_pattern = "source_(\\d+)_(.+)")

UWMP_long <- UWMP_long[!with(UWMP_long, is.na(name) & is.na(type) & is.na(where_it_comes_from) & is.na(usage) & is.na(notes)),] 

UWMP_long$PWSID <- as.factor(UWMP_long$PWSID)
nlevels(UWMP_long$PWSID) #265 systems, 729 sources

write.csv(UWMP_long, "Data_processed/UWMP_long.csv") #export csv for last cleaning steps: 1) remove source types that are not surface water or purchased (removed purchased water only when specified it is groundwater). Also removed banked groundwater, desalinated water and GW under the influence of surface water. Also create a percent of supply column 

#upload cleaned CSV back in. 
UWMP_long_cleaned <- read.csv("Data_processed/UWMP_long_notsworpurchasedremoved.csv")
UWMP_long_cleaned$PWSID <- as.factor(UWMP_long_cleaned$PWSID)
UWMP_long_cleaned <-  UWMP_long_cleaned[,-1]
nlevels(UWMP_long_cleaned$PWSID) #235 systems, 425 sources 

#add data source column and combine all three data sets together
UWMP_long_cleaned$data_source <- "2020 UWMP"
TwentyThree_long_cleaned$data_source <- "2023 CCR"
TwentyTwo_long_cleaned$data_source <- "2022 CCR"

Test <- bind_rows(TwentyThree_long_cleaned, UWMP_long_cleaned)
Test2 <- bind_rows(Test, TwentyTwo_long_cleaned)
Combinednetworkdata <- Test2
nlevels(Combinednetworkdata$PWSID) #771 systems, 1833 sources

#clean up
#remove source  number column
Combinednetworkdata <- Combinednetworkdata[,-6]
#write.csv(Combinednetworkdata, "Data_processed/Tempnetworkdata.csv")

#Split lists for Margot and Alondra to work on data processing
UWMPsystems_datafornetwork <- Combinednetworkdata %>% filter(PWSID %in% UWMP_long_cleaned$PWSID)
nlevels(UWMPsystems_datafornetwork$PWSID)
UWMPsystems_datafornetwork$PWSID <- droplevels(UWMPsystems_datafornetwork$PWSID)
nlevels(UWMPsystems_datafornetwork$PWSID)

write.csv(UWMPsystems_datafornetwork, "Data_processed/UWMPsystems_networkdata.csv")

CCRonlysystems_datafornetwork <- Combinednetworkdata %>% filter(! PWSID %in% UWMPsystems_datafornetwork$PWSID)
nlevels(CCRonlysystems_datafornetwork$PWSID)
CCRonlysystems_datafornetwork$PWSID <- droplevels(CCRonlysystems_datafornetwork$PWSID)
nlevels(CCRonlysystems_datafornetwork$PWSID)

write.csv(CCRonlysystems_datafornetwork, "Data_processed/CCRonlysystems_networkdata.csv")

#Last thing is to generate list of systems cut from original large list for Jenny double checking

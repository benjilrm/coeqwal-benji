#Try to move all 2022 2023 data from text file into a csv (took more finessing here, had to generalize the regular expressions to accommodate formatting differences between systems, parce_CCR_scraps has the code I played with until I got here)

Data_2022 <- read.table("Documents/Combined_2022.txt", sep="\n", header=FALSE)

Data_2022 <- Data_2022 %>% 
  mutate(variable = rep(c("PWSID", "Data"), nrow(Data_2022) / 2), 
         key = rep(1:(nrow(Data_2022) / 2), each = 2)) %>%
  pivot_wider(id_cols = key, names_from = variable, values_from = V1) %>%
  select(-key)

#For whatever reason cutting out 8 santa barbara systems and attempts to edit textfile to prevent this aren't working so am just reading into those eight cases manually reformatted and joining
Missing_2022 <- read_csv("Documents/Missing_CCR_2022.csv")
Data_2022 <- Data_2022 %>% filter(PWSID != "$CA4200870_2022")
Data_2022 <- rbind(Data_2022, Missing_2022)


#remove NULLs (no report systems)
Data_2022 <- Data_2022 %>% filter(Data != "NULL") #Goes from 1013 to 811. Not sure why its 1013 and not 1021 like the original list. 

# Create a named list with water system IDs as names
data_list <- setNames(as.list(Data_2022$Data), Data_2022$PWSID)

data_list <- lapply(data_list, function(x) gsub("\\\\n", " ", x))

# Function to extract data
extract_water_system_data <- function(text_data) {
  # Extract system name
  system_name <- str_extract(text_data, "(.*?)(?=\\s*CCR report year:)")
  
  # Extract CCR report year
  ccr_report_year <- str_extract(text_data, "(?<=CCR report year: )\\d{4}")
  
  # Extract summary (first paragraph after the system name)
  summary <- str_extract(text_data, "(?<=CCR report year: )\\d{4}(.*?)(?=\\s*\\*?Source Type)")
  
  # Initialize list to store source data
  source_data <- list(system_name, ccr_report_year, summary) #may or may not need to add things here
  
  # Find all source information (Type, Where it comes from, Fraction, Notes)
  source_matches <- str_match_all(text_data, 
                                  "(?<=Source Type\\*\\*: )(.*?)(?<=Where It Comes From\\*\\*: )(.*?)(?<=Fraction of Total Annual Water Supply\\*\\*: )(.*?)(?<=Notes\\*\\*: )(.*?)(?=(Source Type\\*\\*:|$))")
  
  
  # Initialize an empty list to store all source data
  all_source_data <- list()
  
  # Loop through all matches to extract source information
  for (i in seq_along(source_matches[[1]][, 2])) {
    source_data <- list(
      source_type = source_matches[[1]][i, 2],
      source_where = source_matches[[1]][i, 3],
      source_fraction = source_matches[[1]][i, 4],
      source_notes = source_matches[[1]][i, 5]
    )
    
    # Append the current source data to the all_source_data list
    all_source_data[[i]] <- source_data
  }
  
  # Create a base data frame
  row <- list(
    system_name = system_name,
    ccr_report_year = ccr_report_year,
    summary = summary
  )
  
  # Add dynamic source columns, filling missing ones with NA
  max_sources <- 10 # Assume at most 10 sources, need to double check this isn't cutting any off
  for (i in 1:max_sources) {
    source_type_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_type, NA)
    source_where_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_where, NA)
    source_fraction_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_fraction, NA)
    source_notes_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_notes, NA)
    
    row[[paste("source", i, "type", sep = "_")]] <- source_type_col
    row[[paste("source", i, "where_it_comes_from", sep = "_")]] <- source_where_col
    row[[paste("source", i, "fraction_of_total_annual_water_supply", sep = "_")]] <- source_fraction_col
    row[[paste("source", i, "notes", sep = "_")]] <- source_notes_col
  }
  
  # Return the row as a data frame
  return(as.data.frame(row, stringsAsFactors = FALSE))
}

# Apply the function to each system in the data list and combine into one data frame
final_data <- do.call(rbind, lapply(data_list, extract_water_system_data))

#Next steps is to get rid of header scraps and to double check data and everything looks right

final_data_clean <- final_data

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\[1\\]", replacement  = "") #Get rid of [1] in front of system names

#Get rid of header pieces left in from regular expressions splicing
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Where It Comes From\\*\\*:" , replacement  = "") 

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Fraction of Total Annual Water Supply\\*\\*:" , replacement  = "") 

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Notes\\*\\*:" , replacement  = "")

#Get rid of extra stars
final_data_clean[,] <- lapply(final_data_clean[,], function(x) gsub("\\*\\*", "", x)) 

#Get rid of years in summary column
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "2022" , replacement  = "")
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "2021" , replacement  = "")

#Get rid of Source 1 *
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "Source 1" , replacement  = "")
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "\\*" , replacement  = "")

#Create and clean a column to preserve system ID out of rownames
final_data_clean$PWSID <- row.names(final_data_clean)
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "_2022" , replacement  = "") 
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "\\$" , replacement  = "") 

#Check why some say 2021 reports; For Indian creek trailer park (CA5303002) should say 2022 (as with all of them is for 2021 but from april 2022); For Valley mobile home park (CA1300572) less clear if it is actually 2021 report or 2022, no 2021 report filed so probably 2022? (and is uploaded on SDWIS as 2022); For summit west mutual (CA4400617)  says was revised in 2022 so assuming 2022; and finally for bridge haven park (CA4900644) says its the 2022 report (for 2021). So I'm going to write over these four 2021 dates with 2022

final_data_clean$ccr_report_year <- 2022

#Get rid of commas so data can be saved as a CSV (is there a better workaround here?)
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "," , replacement  = "")

#Convert to matrix and save as CSV
CSV <- do.call(cbind, final_data_clean)

write.csv(CSV, "Data_processed/CCR_2022_updated.csv")


######
#######
#Repeat for 2023

Data_2023 <- read.table("Documents/Combined_2023.txt", sep="\n", header=FALSE)

Data_2023 <- Data_2023 %>% 
  mutate(variable = rep(c("PWSID", "Data"), nrow(Data_2023) / 2), 
         key = rep(1:(nrow(Data_2023) / 2), each = 2)) %>%
  pivot_wider(id_cols = key, names_from = variable, values_from = V1) %>%
  select(-key)

#remove NULLs (no report systems)
Data_2023 <- Data_2023 %>% filter(Data != "NULL") #Goes from 1021 to 786

# Create a named list with water system IDs as names
data_list <- setNames(as.list(Data_2023$Data), Data_2023$PWSID)

data_list <- lapply(data_list, function(x) gsub("\\\\n", " ", x))

# Function to extract data
extract_water_system_data <- function(text_data) {
  # Extract system name
  system_name <- str_extract(text_data, "(.*?)(?=\\s*CCR report year:)")
  
  # Extract CCR report year
  ccr_report_year <- str_extract(text_data, "(?<=CCR report year: )\\d{4}")
  
  # Extract summary (first paragraph after the system name)
  summary <- str_extract(text_data, "(?<=CCR report year: )\\d{4}(.*?)(?=\\s*\\*?Source Type)")
  
  # Initialize list to store source data
  source_data <- list(system_name, ccr_report_year, summary) #may or may not need to add things here
  
  # Find all source information (Type, Where it comes from, Fraction, Notes)
  source_matches <- str_match_all(text_data, 
                                  "(?<=Source Type\\*\\*: )(.*?)(?<=Where It Comes From\\*\\*: )(.*?)(?<=Fraction of Total Annual Water Supply\\*\\*: )(.*?)(?<=Notes\\*\\*: )(.*?)(?=(Source Type\\*\\*:|$))")
  
  
  # Initialize an empty list to store all source data
  all_source_data <- list()
  
  # Loop through all matches to extract source information
  for (i in seq_along(source_matches[[1]][, 2])) {
    source_data <- list(
      source_type = source_matches[[1]][i, 2],
      source_where = source_matches[[1]][i, 3],
      source_fraction = source_matches[[1]][i, 4],
      source_notes = source_matches[[1]][i, 5]
    )
    
    # Append the current source data to the all_source_data list
    all_source_data[[i]] <- source_data
  }
  
  # Create a base data frame
  row <- list(
    system_name = system_name,
    ccr_report_year = ccr_report_year,
    summary = summary
  )
  
  # Add dynamic source columns, filling missing ones with NA
  max_sources <- 10 # Assume at most 10 sources, need to double check this isn't cutting any off
  for (i in 1:max_sources) {
    source_type_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_type, NA)
    source_where_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_where, NA)
    source_fraction_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_fraction, NA)
    source_notes_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_notes, NA)
    
    row[[paste("source", i, "type", sep = "_")]] <- source_type_col
    row[[paste("source", i, "where_it_comes_from", sep = "_")]] <- source_where_col
    row[[paste("source", i, "fraction_of_total_annual_water_supply", sep = "_")]] <- source_fraction_col
    row[[paste("source", i, "notes", sep = "_")]] <- source_notes_col
  }
  
  # Return the row as a data frame
  return(as.data.frame(row, stringsAsFactors = FALSE))
}

# Apply the function to each system in the data list and combine into one data frame
final_data <- do.call(rbind, lapply(data_list, extract_water_system_data))

#Next steps is to get rid of header scraps and to double check data and everything looks right

final_data_clean <- final_data

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\[1\\]", replacement  = "") #Get rid of [1] in front of system names

#Get rid of header pieces left in from regular expressions splicing
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Where It Comes From\\*\\*:" , replacement  = "") 

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Fraction of Total Annual Water Supply\\*\\*:" , replacement  = "") 

final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*Notes\\*\\*:" , replacement  = "")

#Get rid of extra stars
final_data_clean[,] <- lapply(final_data_clean[,], function(x) gsub("\\*\\*", "", x)) 

#Get rid of years in summary column
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "2023" , replacement  = "")
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "2022" , replacement  = "")

#Get rid of Source 1 *
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "Source 1" , replacement  = "")
final_data_clean$summary <- lapply(final_data_clean$summary, sub, pattern = "\\*" , replacement  = "")

#Create and clean a column to preserve system ID out of rownames
final_data_clean$PWSID <- row.names(final_data_clean)
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "_2023" , replacement  = "") 
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "\\$" , replacement  = "") 

#Check why some say 2022 reports; For Mckinley CSD (CA1210016) it is the 2023 report (for 2022 just headered that way but checked box and SDWIS); City of adelanto (CA3610001) is the same (noticing they have the same report uploaded for 2023 and 2022 in sdwis so we have duplicates here but it is the 2023 report) and Estero municipal improvmeent district (CA4110021) same. So overwrite the ones that say 2022 to say 2023

final_data_clean$ccr_report_year <- 2023

#Get rid of commas so data can be saved as a CSV (is there a better workaround here?)
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "," , replacement  = "")

#Convert to matrix and save as CSV
CSV <- do.call(cbind, final_data_clean)

write.csv(CSV, "Data_processed/CCR_2023_updated.csv")
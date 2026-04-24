#Parse UWMP data into csv

library(stringr)

# Read the file into a vector of lines
lines <- readLines("Documents/OpenAIdata_UWMP_all.txt")

# Initialize empty vectors to store API IDs and their corresponding details
api_ids <- c()
details <- c()

# Iterate through the lines to extract API IDs and details
for (i in seq_along(lines)) {
  if (grepl("^\\$api_", lines[i])) {
    # Add the API ID to the list
    api_ids <- c(api_ids, lines[i])
    # Extract the corresponding details on the next line
    if (i + 1 <= length(lines) && grepl("^\\[1\\]", lines[i + 1])) {
      details <- c(details, sub("^\\[1\\]\\s*", "", lines[i + 1]))
    } else {
      # If no details follow, add an empty string
      details <- c(details, "")
    }
  }
}

# Create a data frame from the collected information
Data_2020 <- data.frame(
  PWSID = api_ids,
  Data = details,
  stringsAsFactors = FALSE
)

# Create a named list with water system IDs as names
data_list <- setNames(as.list(Data_2020$Data), Data_2020$PWSID)

data_list <- lapply(data_list, function(x) gsub("\\\\n", " ", x))

# Function to extract data
extract_water_system_data <- function(text_data) {
  
  # Extract system name
  system_name <- str_extract(text_data, "^(.+?)\\)")
  
  # Extract summary (first paragraph after the system name)
  summary <- str_extract(text_data,"\\)\\s*.*?Source Name")
  
  #Extract backup sources
  backup <- str_extract(text_data,"(?<=\\*\\*Backup sources\\*\\*:).*")
  
  # Initialize list to store source data
  source_data <- list(system_name, summary, backup) #may or may not need to add things here
  
  # Find all source information (Name, Type, Where it comes from, Usage, Notes)
  source_matches <- str_match_all(text_data, 
                                  "(?<=Source Name\\*\\*: )(.*?)(?<=Source Type\\*\\*: )(.*?)(?<=Where It Comes From\\*\\*: )(.*?)(?<=Usage for 2020\\*\\*: )(.*?)(?<=Notes\\*\\*: )(.*?)(?=(Source Name\\*\\*:|$))")
  
  # Initialize an empty list to store all source data
  all_source_data <- list()
  
  # Loop through all matches to extract source information
  for (i in seq_along(source_matches[[1]][, 2])) {
    source_data <- list(
      source_name = source_matches[[1]][i, 2],
      source_type = source_matches[[1]][i, 3],
      source_where = source_matches[[1]][i, 4],
      source_usage = source_matches[[1]][i, 5],
      source_notes = source_matches[[1]][i, 6]
    )
    
    # Append the current source data to the all_source_data list
    all_source_data[[i]] <- source_data
  }
  
  # Create a base data frame
  row <- list(
    system_name = system_name,
    summary = summary,
    backup = backup
  )
  
  # Add dynamic source columns, filling missing ones with NA
  max_sources <- 15 # Assume at most 15 sources, need to double check this isn't cutting any off
  for (i in 1:max_sources) {
    source_name_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_name, NA)
    source_type_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_type, NA)
    source_where_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_where, NA)
    source_usage_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_usage, NA)
    source_notes_col <- ifelse(i <= length(all_source_data), all_source_data[[i]]$source_notes, NA)
    
    row[[paste("source", i, "name", sep = "_")]] <- source_name_col
    row[[paste("source", i, "type", sep = "_")]] <- source_type_col
    row[[paste("source", i, "where_it_comes_from", sep = "_")]] <- source_where_col
    row[[paste("source", i, "usage", sep = "_")]] <- source_usage_col
    row[[paste("source", i, "notes", sep = "_")]] <- source_notes_col
  }
  
  # Return the row as a data frame
  return(as.data.frame(row, stringsAsFactors = FALSE))
}

# Apply the function to each system in the data list and combine into one data frame
final_data <- do.call(rbind, lapply(data_list, extract_water_system_data))

#Next steps is to get rid of header scraps and to double check data and everything looks right

final_data_clean <- final_data

#Create and clean a column to preserve system ID out of rownames
final_data_clean$PWSID <- row.names(final_data_clean)
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "api_summary_" , replacement  = "") 
final_data_clean$PWSID <- lapply(final_data_clean$PWSID, sub, pattern = "\\$" , replacement  = "") 
final_data_clean <- final_data_clean %>% relocate(PWSID, .before = summary)

#Clean up
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = ')\\*\\*', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "\\*\\*", replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = '"', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Source Name', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Source Type\\*\\*:', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Where It Comes From\\*\\*:', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Usage for 2020\\*\\*:', replacement  = "") 
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Notes\\*\\*:', replacement  = "") 

#Backup supplies are repeated in notes, remove since already captured in another column
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = 'Notes\\*\\*:', replacement  = "") 

#Get rid of commas so data can be saved as a CSV (is there a better workaround here?)
final_data_clean[,] <- lapply(final_data_clean[,], sub, pattern = "Backup sources\\*\\*:.*$" , replacement  = "")

#Convert to matrix and save as CSV
CSV <- do.call(cbind, final_data_clean)

write.csv(CSV, "Data_processed/UWMP_2020.csv")


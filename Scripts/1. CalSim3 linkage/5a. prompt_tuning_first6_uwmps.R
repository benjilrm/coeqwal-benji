#Prompt tuning and refinement round 1 (first six of eleven randomly selected systems for prompt and model parameter tuning for UWMPs, pulled a list of twelve but two are the same somehow)

#TRIAL ONE

library(openai)
library(pdftools)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)

#Sys.setenv(OPENAI_API_KEY = 'your_api_key_here') done in environment with personal api key

#create path for PDFs
pdf_path1 <- "~/Box Sync/UWMPs/"
pdf_path2 <- ".pdf"

#first batch of 7 for prompt tuning and refinement list
file_list <- read_csv("Data_raw/Prompt_tuning_cases/UWMP_Batch1_prompt_tuning_cases.csv")

file_list$Report_Year <- 2020
file_list$PDF_name <- paste0(file_list$PWSID, "_", file_list$Report_Year, "_Short")

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #create prompt - starting with something very similar to CCRs but adapated
  prompt1 <- paste0("You will be presented with a section of a 2020 Urban Water Management Plan (UWMP) for an urban drinking water provider in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". UWMP are mandatory reports that must be submitted every five years. They include information on the sources of water utilized by the water system and longterm reliability. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, purchased water, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); 3) How much of the systems total annual water supply for the year 2020 that source represents as a fraction of 1; and 4) How much of the systems average total annual water supply for five year period from 2016 to 2020 that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water sources, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name and PWSID that I provided you, then format your answers for each water source as follows:

Water system name (PWSID)

Summary sentence or sentences listing the water sources identified
                   
**Source Type**: 
**Where It Comes From**:
**Fraction of Total Annual Water Supply for 2020**:
**Fraction of Average Total Annual Water Supply 2016-2020**:
**Notes**:  ")
  
  #API request
  request_body <- list(
    model = "gpt-4o-mini",
    temperature = 0,
    messages = list(list(
      role = 'user', content = str_c(prompt1, formatted_text))
    )
  )
  
  # Execute the POST request to the OpenAI API
  api_response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    body = request_body,
    encode = "json",
    add_headers(`Authorization` = paste("Bearer", Sys.getenv("OPENAI_API_KEY")), `Content-Type` = "application/json")
  )
  
  # Process the response from the API
  response_data <- content(api_response, "parsed")
  
  # Extract the summary from the API's response and save it with unique name
  assign(paste0("api_summary", "_",file_list[i,1]), response_data$choices[[1]]$message$content)
  
}

#This will be how I export later but for now do something that looks nicer
#list <- list(mget(ls(pattern = "api_summary_")))[[1]]

#sink("Documents/Test_UWMP_1.txt")
#print(list)
#sink()
Object_list <- paste0("api_summary_",file_list$PWSID, collapse = ", "); Object_list

cat(api_summary_CA1910004, api_summary_CA3410016, api_summary_CA1910048, api_summary_CA1910091, api_summary_CA3610062, api_summary_CA3610012, sep = "\n\n\n", file = "Documents/Trial1_UWMP_Batch1.txt")

#assessment of results
#GSWC ARTESIA Number of sources is maybe accurate - hard for me to tell if CBMWD is only recycled water (and they get water from them via city of cerritos) of if they are also a water provider... also the total supply number used to calculate percentages is off, is groundwater use total. 
#Orange Vale water company correct'
#Santa clarita, is giving a five year sum for five  year water supply instead of average. Need to change language to say annual average for the five year period I think. Also is assuming same use from 2020 as for the average for the five year period when report doesn't have those numbers
#Montebello accurate (although I didn't check GW use numbers since we don't really care?)
#Running springs. Mostly accurate - my math and AI's math are slight different but pretty similar. Maybe just want to focus on AF used of different sources? That would give us a more consistent pciture of whats included if we just divide that by the total water use from a state data source
#City of chino - use for 2020 differs from our number but both are in the report. Rounds a tiny bit for the five year average 

#TRIAL TWO - try amending prompt to only ask for AF totals and changing wording for average annual over five year period. Could consider also asking to list any emergency sources? 

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #create prompt - starting with something very similar to CCRs but adapated
  prompt2 <- paste0("You will be presented with a section of a 2020 Urban Water Management Plan (UWMP) for an urban drinking water provider in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". UWMPs are mandatory reports that must be submitted every five years. They include information on the sources of water utilized by the water system and their longterm reliability. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, purchased water, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); 3) How much water from that source the system utilized in 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG)) and 4) And the system's average annual consumption of water from that source for the five year period from 2016 to 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG)). Include any relevant notes about the origin or quantity of the sources you identify. For surface water sources, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name and PWSID that I provided you, then format your answers for each water source as follows:

Water system name (PWSID)

Summary sentence or sentences listing the water sources identified
                   
**Source Type**: 
**Where It Comes From**:
**Usage for 2020**:
**Average Annual usage for 2016-2020**:
**Notes**:  
                    
At the end of your summary, list an emergency water sources or interconnections the system has as backup for water supply if mentioned.")
  
  #API request
  request_body <- list(
    model = "gpt-4o-mini",
    temperature = 0,
    messages = list(list(
      role = 'user', content = str_c(prompt2, formatted_text))
    )
  )
  
  # Execute the POST request to the OpenAI API
  api_response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    body = request_body,
    encode = "json",
    add_headers(`Authorization` = paste("Bearer", Sys.getenv("OPENAI_API_KEY")), `Content-Type` = "application/json")
  )
  
  # Process the response from the API
  response_data <- content(api_response, "parsed")
  
  # Extract the summary from the API's response and save it with unique name
  assign(paste0("api_summary", "_",file_list[i,1]), response_data$choices[[1]]$message$content)
  
}

#This will be how I export later but for now do something that looks nicer
#list <- list(mget(ls(pattern = "api_summary_")))[[1]]

#sink("Documents/Test_UWMP_1.txt")
#print(list)
#sink()
Object_list <- paste0("api_summary_",file_list$PWSID, collapse = ", "); Object_list

cat(api_summary_CA1910004, api_summary_CA3410016, api_summary_CA1910048, api_summary_CA1910091, api_summary_CA3610062, api_summary_CA3610012, sep = "\n\n\n", file = "Documents/Trial2_UWMP_Batch1.txt")

###Assessment
#Generally looking good but for santa clarita valley still saying the totals for 2020 are the same for the five year average since they don't provide data on any other years. Could try amending the prompt to say only calculate this if data for all five years is provided? Not sure where five year  numbers are coming for running springs water district either.... Everything else looks good

#TRIAL THREE - try specifying to not calculate five year average unless all five years are provided

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #create prompt - starting with something very similar to CCRs but adapated
  prompt3 <- paste0("You will be presented with a section of a 2020 Urban Water Management Plan (UWMP) for an urban drinking water provider in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". UWMPs are mandatory reports that must be submitted every five years. They include information on the sources of water utilized by the water system and their longterm reliability. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, purchased water, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); 3) How much water from that source the system utilized in 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG)) and 4) And the system's average annual consumption of water from that source for the five year period from 2016 to 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG), only if data for these years is provided in the report). Include any relevant notes about the origin or quantity of the sources you identify. For purchased water and surface water sources, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.). Water purchased from different agencies should be treated as seperate sources. Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name and PWSID that I provided you, then format your answers for each water source as follows:

Water system name (PWSID)

Summary sentence or sentences listing the water sources identified
                   
**Source Type**: 
**Where It Comes From**:
**Usage for 2020**:
**Average Annual usage for 2016-2020**:
**Notes**:  
                    
At the end of your summary, list an emergency water sources or interconnections the system has as backup for water supply if mentioned.")
  
  #API request
  request_body <- list(
    model = "gpt-4o-mini",
    temperature = 0,
    messages = list(list(
      role = 'user', content = str_c(prompt3, formatted_text))
    )
  )
  
  # Execute the POST request to the OpenAI API
  api_response <- POST(
    url = "https://api.openai.com/v1/chat/completions",
    body = request_body,
    encode = "json",
    add_headers(`Authorization` = paste("Bearer", Sys.getenv("OPENAI_API_KEY")), `Content-Type` = "application/json")
  )
  
  # Process the response from the API
  response_data <- content(api_response, "parsed")
  
  # Extract the summary from the API's response and save it with unique name
  assign(paste0("api_summary", "_",file_list[i,1]), response_data$choices[[1]]$message$content)
  
}

#This will be how I export later but for now do something that looks nicer
#list <- list(mget(ls(pattern = "api_summary_")))[[1]]

#sink("Documents/Test_UWMP_1.txt")
#print(list)
#sink()
Object_list <- paste0("api_summary_",file_list$PWSID, collapse = ", "); Object_list

cat(api_summary_CA1910004, api_summary_CA3410016, api_summary_CA1910048, api_summary_CA1910091, api_summary_CA3610062, api_summary_CA3610012, sep = "\n\n\n", file = "Documents/Trial3_UWMP_Batch1.txt")

#Assessment - looks really good except the total the 5 year average usage for running springs is combined for the two sources (it is not seperated in the report so makes sense but would be inaccurate if we didn't catch it)

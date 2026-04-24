#Generate AI data for list of systems we manually collected UWMP data on (see random sample generation script) for comparison

library(openai)
library(pdftools)
library(tidyverse)
library(httr)
library(jsonlite)

#Sys.setenv(OPENAI_API_KEY = 'your_api_key_here') done in environment with person api key

#create path for PDFs
pdf_path1 <- "~/Box Sync/UWMPs/"
pdf_path2 <- ".pdf"

#first batch of 7 for prompt tuning and refinement list
file_list <- read_csv("Data_raw/Random_sample_UWMP_list.csv")

file_list$Report_Year <- 2020
file_list$PDF_name <- paste0(file_list$PWSID, "_", file_list$Report_Year, "_Short")

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- tryCatch(pdf_text(pdf_path), error = function(e) NA)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #create prompt - starting with something very similar to CCRs but adapated
  prompt <- paste0("You will be presented with a section of a 2020 Urban Water Management Plan (UWMP) for an urban drinking water provider in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". UWMPs are mandatory reports that must be submitted every five years. They include information on the sources of water utilized by the water system and their longterm reliability. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, purchased water, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); 3) How much water from that source the system utilized in 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG)) and 4) And the system's average annual consumption of water from that source for the five year period from 2016 to 2020 (in acre-feet (AF), centum cubic feet (CCF) or million gallons (MG), only if data for these years is provided in the report). Include any relevant notes about the origin or quantity of the sources you identify. For purchased water and surface water sources, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.). Water purchased from different agencies should be treated as seperate sources. Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name and PWSID that I provided you, then format your answers for each water source as follows:

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
      role = 'user', content = str_c(prompt, formatted_text))
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
list <- list(mget(ls(pattern = "api_summary_")))[[1]]

options(max.print=1000000)

sink("Documents/OpenAIdata_Randomsample_UWMP.txt")
print(list)
sink()

#Get a nicer format for manual/AI data comparison
Object_list <- paste0("api_summary_",file_list$PWSID, collapse = ", "); Object_list

cat(api_summary_CA0110011, api_summary_CA0110003, api_summary_CA0410008, api_summary_CA0710004, api_summary_CA0710003, api_summary_CA1510018, api_summary_CA1910127, api_summary_CA1910004, api_summary_CA1910173, api_summary_CA1910139, api_summary_CA1910130, api_summary_CA1910098, api_summary_CA1910212, api_summary_CA1910091, api_summary_CA1910090, api_summary_CA1910083, api_summary_CA1910011, api_summary_CA1910143, api_summary_CA1910166, api_summary_CA1910021, api_summary_CA1910028, api_summary_CA1910174, api_summary_CA1910039, api_summary_CA1910155, api_summary_CA1910017, api_summary_CA1910067, api_summary_CA1910041, api_summary_CA3310074, api_summary_CA3310025, api_summary_CA3310044, api_summary_CA3310009, api_summary_CA3310031, api_summary_CA3310083, api_summary_CA3410008, api_summary_CA3410013, api_summary_CA3410016, api_summary_CA3410004, api_summary_CA3410029, api_summary_CA3510001, api_summary_CA3610036, api_summary_CA3610057, api_summary_CA3610012, api_summary_CA3610050, api_summary_CA3610019, api_summary_CA3610041, api_summary_CA3710021, api_summary_CA3710026, api_summary_CA3710702, api_summary_CA3710015, api_summary_CA3710001, api_summary_CA3710010, api_summary_CA3910005, api_summary_CA4310001, api_summary_CA4310007, api_summary_CA4510005, api_summary_CA4810001, api_summary_CA4810003, api_summary_CA4910012, api_summary_CA5010019, api_summary_CA5710006, api_summary_CA1910048, api_summary_CA1910128, api_summary_CA3610062, api_summary_CA0910013, sep = "\n\n\n", file = "Documents/OpenAIdata_Ransomsample_UWMP_niceformat.txt")


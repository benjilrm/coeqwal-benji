#OpenAI assessment of available 2022 and 2023 CCRs for all systems that we think could be surface water reliant, in part of fully. I have to split the system list into two and run them seperately because running into the "paste maximum" for R (they all run but I can't save the output for all of them at once)

##OpenAI script sources: https://www.listendata.com/2023/05/chatgpt-in-r.html#r_function_for_chatgpt; https://tilburg.ai/2024/04/how-to-interact-with-papers-using-the-openai-api-in-r/

library(openai)
library(pdftools)
library(tidyverse)
library(httr)
library(jsonlite)

#Sys.setenv(OPENAI_API_KEY = 'your_api_key_here') done in environment with person api key

#create path for PDFs
pdf_path1 <- "~/Box Sync/CCRs/"
pdf_path2 <- ".pdf"


#List of systems
file_list <- read_csv("Data_raw/Potential_surfacewatersystems_Oct17_2024.csv") #Full list potential surface water systems updated october 17th with three systems from CA SDWIS listed as primarily surface water reliant. 
file_list <- file_list[,c(1,2)] #reduce to only needed columns
file_list <- file_list %>% rename(PWSID = clearinghouse_id) #raname ID column
file_list2022 <- file_list
file_list2022$Report_Year <- 2022
file_list2023 <- file_list
file_list2023$Report_Year <- 2023
file_list <- bind_rows(file_list2022, file_list2023) #Make a dataframe that has each system twice to capture 2022 and 2023 report years

file_list$PDF_name <- paste0(file_list$PWSID, "_", file_list$Report_Year)

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- tryCatch(pdf_text(pdf_path), error = function(e) NA)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  prompt <- paste0("You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". The report is for the year ", file_list[i,3]," the report includes information on the sources of water utilized by the water system and the quality of water provided to customers that year. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name, PWSID and report year that I provided you, then format your answers for each water source consistently following this format:

Water system name (PWSID)
CCR report year

Summary sentence listing the water sources identified
                   
**Source Type**: 
**Where It Comes From**:
**Fraction of Total Annual Water Supply**:
**Notes**:  ")
  
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
  assign(paste0(file_list[i,4]), response_data$choices[[1]]$message$content)
  
}

CCR_2022_list <- list(mget(ls(pattern = "_2022")))[[1]]
CCR_2023_list <- list(mget(ls(pattern = "_2023")))[[1]]

options(max.print=1000000)

sink("Documents/Combined_2022.txt")
print(CCR_2022_list)
sink()

sink("Documents/Combined_2023.txt")
print(CCR_2023_list)
sink()

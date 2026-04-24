#Playing around with formatting

##sources: https://www.listendata.com/2023/05/chatgpt-in-r.html#r_function_for_chatgpt; https://tilburg.ai/2024/04/how-to-interact-with-papers-using-the-openai-api-in-r/

library(openai)
library(pdftools)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)

#Sys.setenv(OPENAI_API_KEY = 'your_api_key_here') done in environment with person api key

#create path for PDFs
pdf_path1 <- "Data_raw/Prompt_tuning_cases/"
pdf_path2 <- ".pdf"

#second batch of 7 for prompt tuning and refinement list
file_list <- read_csv("Data_raw/Prompt_tuning_cases/Prompt_tuning_cases_CSV.csv")
file_list$PDF_name <- paste0(file_list$PWSID, "_", file_list$Report_Year)


###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
prompt <- paste0("You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". The report is for the year ", file_list[i,3]," and includes information on the sources of water utilized by the water system and the quality of water provided to customers that year. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Provide your answer is a comma separated columns with one column per source identified. The first three columns should be for the water system name, PWSID and report year which I provided you. Use the last column for your notes.")
  
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
  assign(paste0("api_summary", "_",file_list[i,4]), response_data$choices[[1]]$message$content)
  
}

cat(api_summary_CA1910043, file = "Documents/FormatTest1.txt")
cat(api_summary_CA1910146, file = "Documents/FormatTest2.txt")
cat(api_summary_CA1910043, api_summary_CA1910146, file = "Documents/FormatTest3.txt")

#In some ways great but additional use of commas really messes things up. Could ask it to eliminate commas? Alternatively just give it a nice structured format and we can do the parsing. Try both of those and then be done with this for now. 

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
prompt <- paste0("You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". The report is for the year ", file_list[i,3]," and includes information on the sources of water utilized by the water system and the quality of water provided to customers that year. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Provide your answer is a comma separated columns with one column per source identified. The first three columns should be for the water system name, PWSID and report year which I provided you. Use the last column for your notes. Omit all other commas from your answer so that your response can be read as a csv")
  
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

cat(api_summary_CA1910043, file = "Documents/FormatTest1.txt")
cat(api_summary_CA1910146, file = "Documents/FormatTest2.txt")
cat(api_summary_CA1910043, api_summary_CA1910146, file = "Documents/FormatTest3.txt")

#What about just nice formatting instructions?

###API loop
#get PDF
for (i in 1:length(file_list$PWSID)){
  pdf_path <- paste0(pdf_path1, file_list[i,4], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  prompt <- paste0("You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The water system's name is ", file_list[i,2], ". The water system's Public Water System ID (PWSID) is ", file_list[i,1],". The report is for the year ", file_list[i,3]," and includes information on the sources of water utilized by the water system and the quality of water provided to customers that year. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions. Start your response with a header that includes the water system name, PWSID and report year that I provided you, then format your answers for each water source consistently following this format:

Water system name (PWSID)
CCR report year

Summary sentence listing the water sources identified
                   
**Source Type**: 
**Where It Comes From**:
**Fraction of Total Annual Water Supply**:
**Notes**: ")
  
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

#combine and save as a text file ()
cat(api_summary_CA1009214, api_summary_CA1910173, api_summary_CA1910146,
    api_summary_CA1910050, api_summary_CA1910064, api_summary_CA1910239,
    api_summary_CA1910139, api_summary_CA1910043, api_summary_CA4300550, 
    api_summary_CA3610085, api_summary_CA3600087, api_summary_CA3410704, 
    api_summary_CA3610014, api_summary_CA1009222, sep = "\n\n\n", file = "Documents/FormatTest4.txt")

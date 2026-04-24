#Prompt tuning and refinement round 1 (first seven of fourteen randomly selected systems for prompt and model parameter tuning)

##sources: https://www.listendata.com/2023/05/chatgpt-in-r.html#r_function_for_chatgpt; https://tilburg.ai/2024/04/how-to-interact-with-papers-using-the-openai-api-in-r/

library(openai)
library(pdftools)
library(tidyverse)
library(httr)
library(jsonlite)
library(glue)

#Sys.setenv(OPENAI_API_KEY = 'your_api_key_here') done in environment with personal api key

#create prompt
prompt1 <- "You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The report includes information on the sources of water utilized by the water system and the quality of water provided to customers. Your job is to read the report and identify the water sources that the water system relies on. For each water source, then tell me 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. Start your answer with a header that includes the water system name, the system's public water system ID (PWSID) and the year of the report. Do not infer to make these determinations, use only the information provided in the text with one exception: If only one source is identified, you may assume that this source makes up all of the water system's annual water supply. If there is more than one source, you cannot assume they use sources equally. Sometimes reports do not have enough information to answer these questions."

#create path for PDFs
pdf_path1 <- "Data_raw/Prompt_tuning_cases/"
pdf_path2 <- ".pdf"

#first batch of 7 for prompt tuning and refinement list
file_list <- c("CA1009214_2023", "CA1910173_2023", "CA1910146_2023", "CA1910050_2023", "CA1910064_2023",
               "CA1910239_2023","CA1910139_2023")

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)

#clean text
formatted_text <- str_c(extracted_text, collapse = "\\n")

#API request
request_body <- list(
  model = "gpt-4o-mini",
  temperature = 0.5,
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
assign(paste0("api_summary", "_",file_list[i]), response_data$choices[[1]]$message$content)

}

#combine and save as a text file
cat(api_summary_CA1009214_2023, api_summary_CA1910173_2023, api_summary_CA1910146_2023,
    api_summary_CA1910050_2023, api_summary_CA1910064_2023, api_summary_CA1910239_2023,
    api_summary_CA1910139_2023, sep = "\n\n\n", file = "Documents/Prompt1_temp0.5_gpt4omini.txt")

#assessment of results
#Westside harvesting: Sources and percent of supply accurate. Missing PWSID. 
#City of Whittier: Sources and percent of supply accurate. Missing PWSID. 
#City of Santa Monica: Sources and percent of supply accurate although doesn't ID MWD water as purchased explicitly (but reasonably interpretable maybe) PWSID not provided
#City of commerce: Sources correct. Wrongly assumes each represents 50% since there are two soruces (ground and purchased). PWSID not provided. 
#Littlerock creek ID: Wrongly assumed groundwater and singular surface water source are each 100% of the total supply. Ids sources correctly however. PWSID not provided. 
#City of Lakewood: Sources correct. says groundwater represents 100% even though it also says recycled water is 6%. Has PWSID for this one and system name. 
#San Marino: Correctly Identified sources and percents. Has PWSID and system name but doesn't call out it is a cal am system.  
#notes and observations: How can I get year of report and PWSID from the name of the PDF since it isn't always finding it/doing it correctly. 

#try with an  adjusted prompt
#create a new prompt
prompt2 <- "You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The report includes information on the sources of water utilized by the water system and the quality of water provided to customers. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the follwoing information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions."

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #API request
  request_body <- list(
    model = "gpt-4o-mini",
    temperature = 0.5,
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
  assign(paste0("api_summary", "_",file_list[i]), response_data$choices[[1]]$message$content)
  
}

#combine and save as a text file
cat(api_summary_CA1009214_2023, api_summary_CA1910173_2023, api_summary_CA1910146_2023,
    api_summary_CA1910050_2023, api_summary_CA1910064_2023, api_summary_CA1910239_2023,
    api_summary_CA1910139_2023, sep = "\n\n\n", file = "Documents/Prompt2_temp0.5_gpt4omini.txt")

#assessment of results
#Westside harvesting: Correctly IDs source, doesn't say 100% but is the only source identified. 
#City of Whittier: Sources and percent of supply accurate. 
#City of Santa Monica: Sources and percent of supply accurate 
#City of commerce: Sources correct. correctly IDs that proportions of supply are not provided. 
#Littlerock creek ID: Ids sources correctly and that proportions are not provided. 
#City of Lakewood: Sources correct. says groundwater represents 100% even though it also says recycled water is 6%.  
#San Marino: Correctly Identified sources and percents.
#notes and observations: Maybe can ask for details about where water diverted and infrastructure used to move or treat it? Do I want to try and get it to distinguish surface water from groundwater and focus on surface water? But overall did much better this time. 

#try with an  adjusted prompt
#create a new prompt
prompt3 <- "You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The report includes information on the sources of water utilized by the water system and the quality of water provided to customers. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions."

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
  #API request
  request_body <- list(
    model = "gpt-4o-mini",
    temperature = 0.5,
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
  assign(paste0("api_summary", "_",file_list[i]), response_data$choices[[1]]$message$content)
  
}

#combine and save as a text file
cat(api_summary_CA1009214_2023, api_summary_CA1910173_2023, api_summary_CA1910146_2023,
    api_summary_CA1910050_2023, api_summary_CA1910064_2023, api_summary_CA1910239_2023,
    api_summary_CA1910139_2023, sep = "\n\n\n", file = "Documents/Prompt3_temp0.5_gpt4omini.txt")

#Need to assess result sand update the below
#assessment of results
#Westside harvesting: Correctly IDs source, says 100% source. 
#City of Whittier: Sources and percent of supply accurate. 
#City of Santa Monica: Sources and percent of supply accurate 
#City of commerce: Sources correct. correctly IDs that proportions of supply are not provided. 
#Littlerock creek ID: Ids sources correctly and that proportions are not provided. 
#City of Lakewood: Sources correct. says groundwater represents 100% even though it also says recycled water is 6%.  
#San Marino: Correctly Identified sources and percents. Identifies treatment plant for SWP water (although it did this previously as well)
#notes and observations: Happy with this. 

#Try now adjusting parameters. Two runs below adjust temp to 0 and 1 respectively and then I will compare to 0.5

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
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
  assign(paste0("api_summary", "_",file_list[i]), response_data$choices[[1]]$message$content)
  
}

#combine and save as a text file
cat(api_summary_CA1009214_2023, api_summary_CA1910173_2023, api_summary_CA1910146_2023,
    api_summary_CA1910050_2023, api_summary_CA1910064_2023, api_summary_CA1910239_2023,
    api_summary_CA1910139_2023, sep = "\n\n\n", file = "Documents/Prompt3_temp0_gpt4omini.txt")

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
  
  #clean text
  formatted_text <- str_c(extracted_text, collapse = "\\n")
  
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
  assign(paste0("api_summary", "_",file_list[i]), response_data$choices[[1]]$message$content)
  
}

#combine and save as a text file
cat(api_summary_CA1009214_2023, api_summary_CA1910173_2023, api_summary_CA1910146_2023,
    api_summary_CA1910050_2023, api_summary_CA1910064_2023, api_summary_CA1910239_2023,
    api_summary_CA1910139_2023, sep = "\n\n\n", file = "Documents/Prompt3_temp1_gpt4omini.txt")

#assessment of temperature changes: Honestly for both everything looks correct/similar. More details provided on treatment plants for Santa Monica surface water which is better. I don't really see a clear reason to go one way or the other. I might stick with zero to be conservative. 

#Next steps
#try again on a new set of seven in another script
#if that goes well, move to trying to assessing formatting options and then pivot this prompt for a larger batch, if it doesn't go well make additional adjustments and go back and test both sets. Not the end of the word to not have good formatting for this stage so dont' spend much time on that now but may want to think on that more later.


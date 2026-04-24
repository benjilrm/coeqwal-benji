#Prompt tuning and refinement round 2 (second batch of seven of fourteen randomply selected systems for prompt and model parameter tuning)

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
file_list <- c("CA1910043_2022", "CA4300550_2022", "CA3610085_2023", "CA3600087_2023", "CA3410704_2022", "CA3610014_2022", "CA1009222_2023")

prompt3 <- "You will be presented with a Consumer Confidence Report (CCR) for regulated drinking water system in California. The report includes information on the sources of water utilized by the water system and the quality of water provided to customers. Your job is to read the report, identify the water sources that the water system relies on and then provide me with a summary that includes the following information for each water source, 1) the source type (groundwater, surface water or recyled water); 2) where it comes from (including who it is purchased from and/or where it is diverted or sourced from (e.g. canal, reservoir, stream)); and 3) How much of the systems total annual water supply that source represents as a fraction of 1. Include any relevant notes about the origin or quantity of the sources you identify. For surface water soruces, include any provided details about the locations, name or type of infrastructure used to move or treat the surface water (e.g. name of water treatment plant, name of acqueduct, address or geographic location of diversion etc.) Do not infer to make these determinations, use only the information provided in the text. Sometimes reports do not have enough information to answer these questions."

###API loop
#get PDF
for (i in 1:length(file_list)){
  pdf_path <- paste0(pdf_path1, file_list[i], pdf_path2)
  extracted_text <- pdf_text(pdf_path)
}
  
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
cat(api_summary_CA1910043_2022, api_summary_CA4300550_2022, api_summary_CA3610085_2023,
    api_summary_CA3600087_2023, api_summary_CA3410704_2022, api_summary_CA3610014_2022,
    api_summary_CA1009222_2023, sep = "\n\n\n", file = "Documents/Batch2_prompt3_temp0_gpt4omini.txt")

#assessment. 
#Glendale correct except it said 65% surface water and we said 61% depends on if you count recycled water as part of their total supply or not...
#Vista grante correct
#san antonio correct except doesn't catch the san antonio creek note we did but even we couldn't say for sure that is the soruce. Probably okay
#Lake arrowhead mistakes the name of managing entity for source I think. Does correctly ID the two other sources of groundwate rand CLAWA as well though... and that proportions aren't provided. 
#Sac county water agency is corrected
#City of colton is correct
#Terra linda farms correct

# Overall, I think I am happy with this because I think the lake arrowhead thing is a reasonable mistake I probably can't avoid as a strange case. Need to decide what to do about recycled water and either try saying of them to ignore it as part of the total water supply or leave as is...

#Next steps - decide about recycled water. If wanting to count it maybe try a prompt revision. 
#Play with formatting. 
#Transition script to work for all 115 ish

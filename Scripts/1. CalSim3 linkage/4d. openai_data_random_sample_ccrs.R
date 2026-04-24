#Generate AI data for list of systems we manually collected CCR data on (see random sample generation script) for pilot exercise comparison

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

#Experiment with prompt tuning list for nwo will change to full list later
file_list <- read_csv("Data_raw/Random_sample_CCR_list.csv") #Full list of the random sample minus five systems with no CCRs which I removed (I think would work without removing but would need to fill in report year column?)
file_list <- na.omit(file_list)
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
  assign(paste0(file_list[i,1]), response_data$choices[[1]]$message$content)
  
}

#combine and save as a text file ()
Object_list <- paste0(file_list$PWSID, collapse = ", "); Object_list #Very ungraceful way to do this, I'm just generating a comma delineated list of the systems (which are the object names) and then copying and pasting it into cat(). 
cat(CA1910043, CA4300550, CA3610085, CA1910146, CA1910239, CA1910064, CA1009214, CA3600087, CA1910173, CA1910050, CA3410704, CA3610014, CA1910139, CA1009222, CA3710013, CA3600185, CA1510045, CA5000010, CA1910012, CA3701408, CA1000359, CA3610062, CA1910247, CA3710016, CA1910092, CA3700859, CA1910004, CA3601182, CA1900301, CA1510018, CA3900543, CA1910127, CA0710002, CA5410012, CA3410008, CA3310022, CA1910166, CA3310009, CA1503270, CA1510006, CA4900599, CA3710001, CA3100041, CA1910163, CA2910001, CA3710010, CA1000471, CA1910130, CA1910002, CA4910019, CA1910048, CA1910160, CA3310004, CA1910062, CA3410031, CA3610064, CA3301283, CA3110017, CA3610854, CA1910047, CA3310038, CA4900647, CA5000408, CA1500546, CA3610055, CA1910161, CA3610012, CA3710021, CA4900871, CA1910063, CA4910006, CA4310007, CA3610701, CA3310048, CA1510052, CA1910205, CA3110034, CA1910007, CA1510004, CA3110042, CA3610013, CA1910255, CA1910203, CA3310036, CA3301775, CA1910020, CA1000345, CA4300834, CA3600010, CA1910213, CA1910083, CA4300545, CA1910072, CA4310013, CA1910060, CA1500584, CA3610034, CA4300526, CA2000521, CA1910191, sep = "\n\n\n", file = "Documents/Round1CCR_updated.txt")

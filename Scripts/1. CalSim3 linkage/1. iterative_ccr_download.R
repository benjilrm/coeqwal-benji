#Iterative CCR download
#Code credit: Liza Wood, University of Exeter

#Load libraries
library(pdftools)
library(xlsx)
library(stringr)

# Identify storage path
storage_path <- "~/Box Sync/CCRs/"

# Read in and input all of the water system IDs 
Systems <- read.csv("Data_raw/cc_sw_systems_082724.csv")
ids <- Systems$clearinghouse_id

# Identify years to pull data for
years <- 2022:2023

# Target URL with varying queries for the ID and the Year
ccr_url_pt1 <- 'https://ear.waterboards.ca.gov/Home/ViewCCR?PwsID='
ccr_url_pt2 <- '&Year='
ccr_url_pt3 <- '&isCert=false'

# Iterate through each combo of ID and year and see if we can download the report using trycatch which will just skip over those that don't have reports instead of breaking
for(i in 1:length(ids)){
  for(j in 1:length(years)){
    ccr_url <- paste0(ccr_url_pt1, ids[i], ccr_url_pt2, years[j], ccr_url_pt3)
    dest_file <- paste0(storage_path, ids[i], "_", years[j], ".pdf")
    # the next line says don't redownload if the 'destination file' it already stored
    # (e.g. don't re-download to save you time)
    if(paste0(ids[i], "_", years[j], ".pdf") %in% list.files(storage_path)) {next} 
    else {tryCatch(download.file(ccr_url, dest_file),
                   error = function(e) NA )}
  }
}

# Now, those that are not PDFs will be saved with a .pdf extension so need to evaluate each file
pdf_error_fls <- list()
fls <- list.files(storage_path, full.names = T)
pdf_fls <- fls[str_detect(fls, '.pdf')]
for(i in 1:length(pdf_fls)){
  output <- tryCatch(pdf_info(pdf_fls[i]),
                     error = function(e) pdf_fls[i])
  pdf_error_fls[[i]] <-ifelse(output == pdf_fls[i], pdf_fls[i], NA)
}
pdf_error_fls <- unlist(pdf_error_fls)
pdf_error_fls <- pdf_error_fls[!is.na(pdf_error_fls)]

## Remove them from the database
file.remove(pdf_error_fls)

## Then try to set these right. Revisit the url and try with Excel
for(i in 1:length(pdf_error_fls)){
  id = str_extract(pdf_error_fls[i], 'CA\\d+(?=_)')
  yr = str_extract(pdf_error_fls[i], '\\d{4}(?=\\.pdf)')
  ccr_url <- paste0(ccr_url_pt1, id, ccr_url_pt2, yr, ccr_url_pt3)
  dest_file <- paste0(storage_path, id, "_", yr, ".xls")
  if(paste0(id, "_", yr, ".xls") %in% list.files(storage_path)) {next} 
  tryCatch(download.file(ccr_url, dest_file), error = function(e) NA )
}

## And just like with PDFs, do a check on whether these seem like valid Excel files
xls_error_fls <- list()
fls <- list.files(storage_path, full.names = T)
xls_fls <- fls[str_detect(fls, '.xls')]
for(i in 1:length(xls_fls)){
  output <- tryCatch(read.xlsx(xls_fls[i], 1),
                     error = function(e) xls_fls[i])
  xls_error_fls[[i]] <-ifelse(output == xls_fls[i], xls_fls[i], NA)
}
xls_error_fls <- unlist(xls_error_fls)
xls_error_fls <- xls_error_fls[!is.na(xls_error_fls)]

## Remove the errors from the database
file.remove(xls_error_fls)

## Then try to set these right. Revisit the url and try as a doc
for(i in 1:length(xls_error_fls)){
  id = str_extract(xls_error_fls[i], 'CA\\d+(?=_)')
  yr = str_extract(xls_error_fls[i], '\\d{4}(?=\\.xls)')
  ccr_url <- paste0(ccr_url_pt1, id, ccr_url_pt2, yr, ccr_url_pt3)
  dest_file <- paste0(storage_path, id, "_", yr, ".doc")
  tryCatch(download.file(ccr_url, dest_file), error = function(e) NA )
}

# check what worked and what didn't by making a dataframe of what downloaded
log <- data.frame('id' = rep(ids, each = length(years)),
                  'year' = rep(years, times = length(ids)))
log$status <- ifelse(str_detect(paste0(log$id, "_", log$year), 
                                paste0(str_remove_all(list.files(storage_path), 
                                                      '\\.pdf|\\.xls|\\.doc'), collapse = "|")),
                     'downloaded', 'missing')

log$status <- as.factor(log$status)
summary(log$status)

yearly_missing <- log %>% 
  group_by(year) %>% 
  summarize(total = n(),
            missing = sum(status == "missing")) 

#21.61% missing for 2023 and 18.47% missing for 2022
#BUT note that in some rare cases there is a PDF or doc we were able to scrape that are labeled here as not missing but they are blank or not usable. There are also a few that are the certification report instead of the actual report, I filtered the box CCR folder and reviewed those that had the phrase "consumer confidence report certification" in them for 2022 and 2023 only, remove those that only had the report certification and no appended report (maybe ~7 ish). Subsequently also added three systems to our list of surface water systems and manually downloaded CCRs for 2022 and 2023 into folder. All three had both years. 

# Overview
This repository compiles Consumer Confidence Reports and Urban Water Management Plans into a dataset of surface water sources, sales and transfers for California community water systems. Additional variables related to public water systems, surface water sources, and surface water sales/transfers were joined and/or calculated using further datasets (see 'External Data Sources' below). The final dataset was converted into both an igraph object (facilitating network analysis on the dataset--see subfolder '4. Analysis') and into shapefiles (one for each of systems, sources, and connections) for upload to an interactive dashboard in ArcGIS Online, which you can find [here](https://bit.ly/CA_watersources_network). 

# Structure and Navigation
The 'Scripts/' folder contains all relevant code. Run scripts based on numerical order of subfolders (and of scripts within folders). When unnumbered within a folder, scripts can be run in any given order.

Scripts/ 
    
    ├── 1. CalSim3 linkage                                   # Compiling data using Consumer Confidence Reports and Urban Water Management Plans
    │   ├── 1. iterative_ccr_download.R                      # Iterative download of consumer confidence reports
    │   ├── 2. random_sample_generation_ccr.R                # Random sample generation for manual data collection round 1 (CCRs)
    │   ├── 3. random_sample_generation_uwmp.R               # Random sample generation for manual data collection round 2 (UWMPs)
    │   ├── 4a. prompt_tuning_first7_ccrs.R                  # Prompt tuning for first batch of randomly-selected systems' CCRs
    │   ├── 4b. prompt_tuning_second7_ccrs.R                 # Prompt tuning for second batch of randomly-selected systems' CCRs
    │   ├── 4c. experimenting_w_ai_response_formatting.R     # Adjusting formatting for LLM prompts
    │   ├── 4d. openai_data_random_sample_ccrs.R             # Generate AI data for systems we manually collected CCR data on
    │   ├── 5a. prompt_tuning_first6_uwmps.R                 # Prompt tuning for first batch of randomly-selected systems' UWMPs
    │   ├── 5b. prompt_tuning_second5_uwmps.R                # Prompt tuning for second batch of randomly-selected systems' UWMPs
    │   ├── 5c. openai_data_random_sample_uwmps.R            # Generate AI data for systems we manually collected UWMP data on
    │   ├── 6a. openai_data_all_sw_systems_ccrs.R            # OpenAI assessment of available 2022/2023 CCRs for all possibly-SW systems
    │   ├── 6b. openai_data_all_uwmps.R                      # OpenAI assessment of available UWMPs
    │   ├── 7a. parsing_ccr.R                                # Parse CCR data from text file into csv
    │   ├── 7b. parsing_uwmp.R                               # Parse UWMP data from text file into csv
    │   └── 7c. pivot_longer_ai_data_all.R                   # Pivot cleaned AI data in wide format to longer format for final cleaning and processing
    ├── 2. Cleaning, processing, and joins/
    │   └── master_cleaning_and_join.Rmd                     # Cleaning of network dataset, joins with other datasets, and generating additional columns
    ├── 3. Additional processing for ArcGIS and igraph/
    │   ├── processing_for_arcgis_dashboard.Rmd              # Processing final master data into shapefiles for upload to ArcGIS Online
    │   └── processing_for_network_igraph.Rmd                # Processing final master data into igraph format
    └── 4. Analysis
        ├── swp_cvp_brief.Rmd                                # Summary statistics for report on systems served by SWP & CVP
        └── network_analysis.Rmd                             # Calculation of network metrics, analysis, and visualisations of network data in igraph

# External Data Sources
Please see the Supplemental Data Documentation document linked [here](https://docs.google.com/document/d/189OF5rqQSb2CFYDXUSJb0KPLgYTfg7ua34_v-jvnDzo/edit?tab=t.0) for more information on methodology and where to locate these datasets and how we utilised them.

SAFER Clearinghouse data
- This is an internal State Water Board dataset they shared with us for this project. All documentation is located in [this Google Drive folder](https://drive.google.com/drive/folders/1gxMrGeaOA_xtGb1zf97Z79EFEwKcIpCG).
- Unfortunately there is no data dictionary, but [Jenny has worked on developing one](https://docs.google.com/spreadsheets/d/1ulStajU7D1eFu2m3V0fTDtcm3PGNlneX/edit?gid=631545570#gid=631545570).
- 'SourceReporting' sheet used for geolocation data missing_source_lat_longs.Rmd, as well as to identify groundwater facilities in master_cleaning_and_join.Rmd
- 'WaterSystemInformation' sheet used to filter for only facilities in community water systems in master_cleaning_and_join.Rmd

SAFER failing and at-risk systems
- This is a public SAFER dataset obtained from [this link](https://data.ca.gov/dataset/safer-failing-and-at-risk-drinking-water-systems)
- Used to identify at-risk and failing systems in swp_cvp_brief.Rmd

EDT Data
- Drinking water quality data compiled by the State Water Resources Control Board and downloaded from [this page](https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/EDTlibrary.html).
- Data dictionary is available [here](https://www.waterboards.ca.gov/drinking_water/certlic/drinkingwater/documents/edtlibrary/data_dictionary.pdf).
- Used to identify drinking water facilities with MCL violations in master_cleaning_and_join.Rmd

CA SDWIS
- Contains data on each system's county, state classification, etc.
- Joined into main dataset by PWSID

EPA SDWIS
- Contains data on each system's population served, wholesale provider, status, etc.
- Joined into main dataset by PWSID

Data dictionary for new columns [here](https://docs.google.com/spreadsheets/d/11Wzbw_Jr1k-WxoZu8n-r0eJ0FcPlr-ldpthPKmB1gL0/edit?gid=0#gid=0)

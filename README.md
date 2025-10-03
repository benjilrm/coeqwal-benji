# Overview
This repository cleans, processes, and adds various columns to our dataset of connections between surface water sources and community drinking water systems.

# Structure and Navigation
The 'Scripts/' folder contains all relevant code. 

Scripts/
├── 1. Cleaning & processing/
│ ├── initial_cleaning_of_network_data.Rmd  # Initial cleaning and processing of network data
│ └── missing_source_lat_longs.Rmd  # Using SAFER Clearinghouse data to fill in lat/longs for sources with missing location data
├── 2. Generating new columns/
│ ├── add_gw_variables_to_network_data.Rmd  # Generating variables characterising PWS groundwater access
│ ├── source_id_creation.Rmd  # Generating a unique ID for each source
│ └── split_up_project_columns.Rmd  # Generating dummy variables indicating whether connections correspond to State Water Project, Central Valley Project, and Colorado River Aqueduct, respectively. 
├── 3. Joins/
│ └── joining_in_intermediate_data.Rmd # Joining all new columns back into network data
     
Data dictionary for new columns [here](https://docs.google.com/spreadsheets/d/11Wzbw_Jr1k-WxoZu8n-r0eJ0FcPlr-ldpthPKmB1gL0/edit?gid=0#gid=0)

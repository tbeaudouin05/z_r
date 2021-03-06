# install these packages only if the user does not have them
if('RPostgreSQL' %in% rownames(installed.packages()) == FALSE) {install.packages("RPostgreSQL",dependencies=TRUE)}
if('yaml' %in% rownames(installed.packages()) == FALSE) {install.packages("yaml")}
if('plyr' %in% rownames(installed.packages()) == FALSE) {install.packages("plyr")}
if('gmailr' %in% rownames(installed.packages()) == FALSE) {install.packages("gmailr")}
if('dplyr' %in% rownames(installed.packages()) == FALSE) {install.packages("dplyr")}
if('purrr' %in% rownames(installed.packages()) == FALSE) {install.packages("purrr")}
if('readr' %in% rownames(installed.packages()) == FALSE) {install.packages("readr")}

# calls the necessary packages for the code to run (installed above)
library(RPostgreSQL)
library(yaml)
library(plyr)
library(gmailr)

# timestamps when the code starts
print(Sys.time())

# takes into consideration the settings chosen in the yaml files
config <- yaml.load_file("./0_settings_yaml_files/1_config.yaml")
data_upload <- yaml.load_file("./0_settings_yaml_files/2_data_upload.yaml")

previous_source_id <- ''

# fetches functions created in other R modules 
# (for the sake of clarity, not the whole code is in one place, we defined functions in other modules)
source ("./1_R_code_to_source/1_create_csv/download_csv.R")
source ("./1_R_code_to_source/1_create_csv/prepare_csv.R")
source("./1_R_code_to_source/2_anaplan/anaplan_upload_new.R")
source("./1_R_code_to_source/3_send_email/send_email.R")


# fetches model ids from "config.yaml"
# and link them with model names of "tables.yaml"
# ALL THE MODELS
for (model_id in config$anaplan$model_ids) {

  # fetches table names from "tables.yaml" only for the model id fetched in first loop
  # ALL THE TABLES within one model
  for (table_names in data_upload[model_id]) {

    # fetches only one table at a time from the model fetched in first loop within the tables fetched in second loop
    #ONLY ONE TABLE of one model
    for (table_name in table_names) { split <- c(strsplit(table_name," / "))
          
          # fetches the first part and the second part of the split
          #NB: one table = one csv_query_name / one module_name
          csv_query_name <- split[[1]][1]
          module_name <- split[[1]][2]
          source_id <- split[[1]][3]

          # prints names of csv/query, module and timestamp to identify easily errors if code breaks
          print(paste('csv_query_name:',csv_query_name))
          print(paste('module_name:',module_name))
          print(Sys.time())

      # loads the PostgreSQL driver
      drv <- dbDriver("PostgreSQL")

      # creates a connection to the postgres database
      # note that "con" will be used later in each connection to the database
      con <- dbConnect(drv, dbname = config$buying_data_mart$db,
                       host = config$buying_data_mart$host , port = config$buying_data_mart$port,
                       user = config$buying_data_mart$user , password = config$buying_data_mart$pw)
      
      # uses the function defined in the R file "redcat_download.R"
      # as the name suggests, this function runs the query on redcat and writes the csv in the appropriate folder
      if (previous_source_id != source_id) {run_query_write_csv(model_id,csv_query_name,con)}
      
      previous_source_id <- source_id
      
      # create the different levels of data (ctry_cat_dep vs. ctry_cat_dep_brand) from the same source file
      #prepare_csv_f(csv_query_name,module_name)
      
      Sys.sleep(30)

      folder_name <- gsub('\\\\data','',csv_query_name)
      
      path_to_ex <- paste('C:/Users/Zalora/Google Drive/1. ZALORA/Anaplan/R_anaplan_data_load_master/4_anaplan-connect-1-3-3-3/',folder_name,'.bat',sep = '')
      
      shell.exec(path_to_ex)
      
      Sys.sleep(300)
      
      # uses the function defined in the R file "anaplan_upload.R"
      # it uses Anaplan built-in tool "anaplan connect" to upload data to Anaplan
      #create_and_run_batch_file_upload_new(config$anaplan$login,config$anaplan$workspace_id,model_id,module_name)

    dbDisconnect(con)}}}

    # timestamps when the code ends
    print(Sys.time())
    
    
    #send_email()
    
    
    
library(icesDatras)
library(RODBC)




#' refreshDatrasData
#' 
#' This function uses the icesDATRAS library to download requested DATRAS
#' data and then, optionally, update a local database.
#'
#' @param recType The DATRAS data type you want to download
#' @param survey The DATRAS survey acronoym - default value is 'IE-IGFS'
#' @param years The year or range of years you want to download data for
#' @param quarters The quarter or range of quarters you want to download data 
#' for
#' @param mode Either 'downloadOnly' to just download the data or 'update' if 
#' you want to download the data and update the database.  The default value is
#' 'downloadOnly'
#' @param connectionString A valid database connection string - used to 
#' specify which database will be updated.  Only required if you are in 
#' 'update' mode.
#'
#' @return
#' @export
#'
#' @examples
refreshDatrasData <- function(recType, survey = 'IE-IGFS', years, quarters, mode = 'downloadOnly', connectionString = ''){
  
  # For testing
  #connectionString <- "Driver=SQL Server; Server=MYSERVER; Database=DATRAS"
  #recType <- 'CA'
  #survey <- "SCOWCGFS"
  #years <- 2020
  #quarters <- 1:4
  #mode <- 'update'
  
  # Check if the mode parameter is valid
  if(!mode %in% c('downloadOnly','update')){
    stop('Invalid value for mode parameter')
  }
  
  # Check if a connection string has been supplied (if required)
  if (mode == 'update' & connectionString == ''){
    stop('If you want to update a database you must supply a connection string')
  }
  
  # Set up some values we will use later
  intermediateTableName <- ''
  finalTableName <- ''
  storedProcedureName <- 'dbo.UpdateDataFromDownload'
  
  # Choose which tables to use based on the data we are trying to update
  if (recType == 'HH'){
    intermediateTableName <- 'dbo.HH_temp'
    finalTableName <- 'dbo.HH_Download'
  } else if (recType == 'HL'){
    intermediateTableName <- 'dbo.HL_temp'
    finalTableName <- 'dbo.HL_Download'
  } else if (recType == 'CA'){
    intermediateTableName <- 'dbo.CA_temp'
    finalTableName <- 'dbo.CA_Download'
  } else {
    print(paste('I do not know how to handle this type of data',recType))
    stop('Unknown recType')
  }
  
  
  print(paste('Trying to download the requested data from ICES:',recType))
  
  # Download the required data from DATRAS
  downloadedData <- getDATRAS(record = recType, survey = survey, years = years, quarters = quarters)
  
  # Check if any data was provided by the download function - if not, stop
  if(!exists('downloadedData') || downloadedData == FALSE || nrow(downloadedData)==0){
    stop('No rows of data were downloaded from ICES')
  }

  print(paste('Downloaded',nrow(downloadedData), 'rows of data'))
  
  downloadedData$download_date <- as.character(Sys.Date())
  
  # If we want to update the database - try doing it!
  if (mode == 'update'){
  
    print('Starting process to update database')
    
    # Open a datbase connection
    channel <- odbcDriverConnect(connectionString)
    
    dbColNames <- colnames(sqlQuery(channel,paste("select * from ",intermediateTableName," where 1=0")))
    downloadColNames <- colnames(downloadedData)
    
    # Check the column names match - if they don't print out an error and stop
    #if (length(setdiff(dbColNames,downloadColNames)) >0  | length(setdiff(downloadColNames,dbColNames)) >0){
    if (!isTRUE(all.equal(dbColNames,downloadColNames)))
    {
      print('The column names (or their order) of the downloaded data and the table in the database do not match - please check to see if the DATRAS format has been changed')
      print(all.equal(dbColNames,downloadColNames))
      print('Downloaded data column names are:')
      print(downloadColNames)
      print('Database column names are:')
      print(dbColNames)
      stop('Column names do not match')
    }
    
    # Ok, if we got this far then the next step is to try and save the data to the database
    # Clear out the intermediate table first (added nocount to prevent errors for an empty table)
    sqlQuery(channel,paste("set nocount on; delete from",intermediateTableName,";"))
    # Now save the downloaded data to the table
    # (If I used fast=T I get errors messages about some of the NAs)
    sqlSave(channel,downloadedData,intermediateTableName,rownames=F,fast=F, append=T)
    
    numOfDBRows <- sqlQuery(channel,paste("select count(*) from ",intermediateTableName))
    print(paste('Saved',numOfDBRows, 'rows of data to the intermediate table', intermediateTableName))
    
    # Check we have the right number of rows in the intermediate database table
    if (numOfDBRows != nrow(downloadedData)){
      print(paste("There was a problem - the number of rows downloaded don't match the number of rows saved to the intermediate table", intermediateTableName))
      stop('Number of rows do not match')
    }

    print(paste('Trying to add the downloaded data to the final table',finalTableName))
    # Call a stored procedure to do the update - it uses a transaction
    myOutput <- sqlQuery(channel,paste("exec ",storedProcedureName, " @recType =",recType))
    # print(myOutput)
    print('Update complete')
    
    close(channel)
  }
  
  
  # just return the downloaded data
  downloadedData
  
}


# Example script showing how to to use the refreshDatrasData function 

# First, import our DATRAS functions
source('DatrasRefreshFunctions.R')

# Now we define our database connection string
# IMPORTANT - change SERVERNAME to the correct name of your server
# (The database used must have certain tables and stored procedures)
myConnectionString <- "Driver=SQL Server; Server=SERVERNAME; Database=DATRAS"

# Check Survey Code Names in DATRAS
#getSurveyList()


# Set our other desired parameter values here
mySurvey <- 'EVHOE'
#myYears <- c(2017,2018)
myYears <- 2017
myQuarters <- 1:4
# Can use 'downloadOnly' or 'update'
myMode <- 'downloadOnly'
#myMode <- 'update'
      
# Now just call our functions

## HH
downloadedDataHH <- refreshDatrasData(recType = 'HH',survey = mySurvey, years = myYears, quarters = myQuarters, mode = myMode, connectionString = myConnectionString)
## HL
downloadedDataHL <- refreshDatrasData(recType = 'HL',survey = mySurvey, years = myYears, quarters = myQuarters, mode = myMode, connectionString = myConnectionString)
## CA
downloadedDataCA <- refreshDatrasData(recType = 'CA',survey = mySurvey, years = myYears, quarters = myQuarters, mode = myMode, connectionString = myConnectionString)



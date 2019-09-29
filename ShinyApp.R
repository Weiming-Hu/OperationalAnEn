library(shiny)
library(leaflet)
library(maps)
library(raster)
library(stringr)
library(rgdal)

#Hardcoded the date here so it works. Can be changed by removing line 12 and changing 'date2' to 'Date'.
date1 <- Sys.Date()
date2 <- str_remove_all(date1,"-")
Date <- "20190920"


YM <- substr(Date, 1, nchar(Date)-2)

#Last 3 numbers decide which tile is selected from the full image. Need to determine which one to use.
destfile <- paste("nam_218_", Date, "_0000_025.grb2", sep = '')

url <- paste("https://nomads.ncdc.noaa.gov/data/meso-eta-hi/",
             YM,"/",Date, "/", destfile, sep="")

destfile <- paste0('output/', destfile)

ret <- download.file(url, destfile, method = "auto", quiet = FALSE)

# Check whether the download succeeded
if (ret != 0) {
  stop('Download failed! Make sure the URL is accessible and the destination file path is valid.')
}

#This is downloading the wrong file and I am not sure why? The file size is significantly smaller than what is described.

# File conversion from grb2 to NetCDF
command <- paste(
  'gribConverter -c grb2nc-NAM.cfg',
  '--folder ./output/',
  '--output ./output/output.nc')

ret <- system(command)

#I am not sure how to get the .grb2 file read and in R so I can overlay it on the map.
# r <- readGDAL(destfile)
library(ncdf4)

# ...

ui <- fluidPage(
	titlePanel("State College, PA"), 
	leafletOutput("mymap")
)

shinyserver <- function(input, output) {
  
  output$mymap <- renderLeaflet({
    m <- leaflet() %>%
      setView(lng = -77.8653, lat = 40.8000, zoom = 10)
    m %>% addTiles()
    
  })
}

shinyApp(ui, shinyserver)

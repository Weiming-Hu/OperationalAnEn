for (library in c('shiny', 'leaflet', 'maps','raster','stringr','rgdal')) {
	if (requireNamespace(library)) {
		install.packages(library)
	} else {
		library(library)
	}	
}

#Hardcoded the date here so it works. Can be changed by removing line 12 and changing 'date2' to 'Date'.
date1 <- Sys.Date()
date2 <- str_remove_all(date1,"-")
Date <- "20190920"


YM <- substr(Date, 1, nchar(Date)-2)

url <- paste("https://nomads.ncdc.noaa.gov/data/meso-eta-hi/",YM,"/",Date, "/", sep="")
url

#Last 3 numbers decide which tile is selected from the full image. Need to determine which one to use.
destfile <- paste("nam_218_",Date,"_0000_025.grb2")

download.file(url, destfile, method = "auto", quiet = FALSE)
#This is downloading the wrong file and I am not sure why? The file size is significantly smaller than what is described.

#I am not sure how to get the .grb2 file read and in R so I can overlay it on the map.
r <- readGDAL(destfile)

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

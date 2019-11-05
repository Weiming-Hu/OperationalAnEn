library(leaflet)
library(raster)
library(RAnEn)
library(shiny)

source('functions.R')

i.par <- 3
rast.alpha <- 0.5
forecasts <- readForecasts('output/output.nc')
rast.list <- create.raster(forecasts, i.par)

ui <- fillPage(
	titlePanel("State College, PA"), 
	leafletOutput("mymap", height = 800)
)

shinyserver <- function(input, output) {
	
	output$mymap <- renderLeaflet({
		m <- leaflet() %>%
			setView(lng = -77.8653, lat = 40.8000, zoom = 4)
		m %>% addTiles() %>%
			addRasterImage(rast.list$raster, colors = rast.list$color, opacity = rast.alpha) %>%
			addLegend(pal = rast.list$color, values = values(rast.list$raster),
								title = forecasts$ParameterNames[i.par])
	})
}

shinyApp(ui, shinyserver)
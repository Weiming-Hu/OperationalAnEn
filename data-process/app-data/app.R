library(RColorBrewer)
library(leaflet)
library(raster)
library(RAnEn)
library(shiny)
library(sp)

i.par <- 3
i.flt <- 1
zoom <- 5
rast.alpha <- 0.5

# Get current date
current.date <- Sys.Date()
current.date.str <- format(current.date, format = '%Y%m%d')

# Read data
forecasts <- readForecasts(paste0(current.date.str ,'.nc'))

# Shift X coordinates
forecasts$Xs <- forecasts$Xs - 360

# This is the layer to plot
values <- forecasts$Data[i.par, , 1, i.flt]

# Create a raster layer
crs <- crs('+proj=longlat +datum=WGS84')
sppts <- SpatialPoints(
	cbind(forecasts$Xs, forecasts$Ys),
	proj4string = crs)
ext <- extent(sppts)
rast <- raster(ext, res = 0.25, crs = crs)
rast <- rasterize(x = sppts, y = rast, field = values)

pal <- colorNumeric(
	palette = 'Spectral',
	domain = values(rast),
	na.color = NA)

ui <- fillPage(
	titlePanel("State College, PA"),
	leafletOutput("mymap", height = 800)
)

shinyserver <- function(input, output) {
	output$mymap <- renderLeaflet({
		m <- leaflet() %>%
			setView(lng = mean(forecasts$Xs),
							lat = mean(mean(forecasts$Ys)),
							zoom = zoom) %>%
			addTiles() %>%
			addRasterImage(rast, colors = pal,
										 opacity = rast.alpha,
										 project = F) %>%
			addLegend(pal = pal, values = values(rast),
								title = forecasts$ParameterNames[i.par])
	})
}

shinyApp(ui, shinyserver)
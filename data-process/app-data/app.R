# "`-''-/").___..--''"`-._
#  (`6_ 6  )   `-.  (     ).`-.__.`)   WE ARE ...
#  (_Y_.)'  ._   )  `._ `. ``-..-'    PENN STATE!
#    _ ..`--'_..-_/  /--'_.' ,'
#  (il),-''  (li),'  ((!.-'
# 
# Author: Benjamin Tate <bgt5073@psu.edu>
#         Weiming Hu <weiming@psu.edu>
#         
#         Geoinformatics and Earth Observation Laboratory (http://geolab.psu.edu)
#         Department of Geography and Institute for CyberScience
#         The Pennsylvania State University
#

library(RColorBrewer)
library(leaflet)
library(raster)
library(shiny)
library(sp)

# Define basic visualization parameters
zoom <- 5
rast.alpha <- 0.7
center.x <- -77.84483
center.y <- 38.08232

# Get current date
current.date <- Sys.Date()
current.date.str <- format(current.date, format = '%Y%m%d')

# This regex will be used to match different components in a file name
regex <- '^(\\d+)-(.*?)-(\\d+)\\.tif$'

# Get all available tiff files in the current folder
all.files <- list.files(path = '.', pattern = 'tif')

# Extract the available variables for select boxes
select.dates <- unique(gsub(regex, '\\1', all.files))
select.variables <- unique(gsub(regex, '\\2', all.files))
select.flts <- sort(as.numeric(unique(gsub(
	regex, '\\3', all.files))) / 3600)

# Whether to create an animation for the slider input
# animate <- F
animate <- animationOptions(interval = 1000, loop = T)

ui <- fixedPage(
	titlePanel("Operational Analog Ensemble"),
	
	sidebarLayout(
		sidebarPanel(
			selectInput(
				"date", label = h3("Date"), 
				choices = select.dates, selected = 1),
			selectInput(
				"variable", label = h3("Weather variable"), 
				choices = select.variables, selected = 1),
			sliderInput("flt", label = h3("Lead time (h)"),
									min = min(select.flts), 
									max = max(select.flts),
									value = min(select.flts),
									animate = animate),
			width = 3
		),
		mainPanel(
			leafletOutput("weatherMap", height = 600))
	)
)

shinyserver <- function(input, output) {
	
	# Define the image file path to read
	file.tif <- reactive({
		paste0(paste(
			input$date, input$variable,
			as.numeric(input$flt) * 3600,
			sep = '-'), '.tif')
	})
	
	observe({
		if (!file.exists(file.tif())) {
			showNotification('This combination is not available!')
		}
	})
	
	# Define the base map that won't change
	output$weatherMap <- renderLeaflet({
		leaflet() %>%
			setView(
				lng = center.x,
				lat = center.y,
				zoom = zoom) %>%
			addTiles()
	})
	
	observe({
		# Convert reactiveExpr to the actual object
		file.tif <- file.tif()

		if (file.exists(file.tif)) {
			# Read the file as a raster
			rast <- raster(file.tif)

			# This is the color function
			pal <- colorNumeric(
				palette = 'RdYlBu',
				domain = values(rast),
				na.color = NA, 
				reverse = T)

			leafletProxy('weatherMap') %>%
				removeImage(layerId = 'raster') %>%
				removeControl(layerId = 'legend') %>%
				addRasterImage(
					rast, colors = pal,
					opacity = rast.alpha,
					project = F, layerId = 'raster') %>%
				addLegend(
					pal = pal, layerId = 'legend',
					values = values(rast),
					title = gsub(regex, '\\2', file.tif))
		}
	})
}

shinyApp(ui, shinyserver)

# Display a fixed legend.
# Wind
# 


# 
# Speed up the display.
# Smooth transition.
# 



library(RColorBrewer)
library(leaflet)
library(raster)
library(shiny)
library(sp)

# Define basic visualization parameters
zoom <- 5
rast.alpha <- 0.7

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
			sliderInput("flt", label = h3("Horizon (h)"),
									min = min(select.flts), 
									max = max(select.flts),
									value = min(select.flts)),
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
	
	output$weatherMap <- renderLeaflet({
		
		# Convert reactiveExpr to the actual object
		file.tif <- file.tif()
		
		if (file.exists(file.tif)) {
			# Read the file as a raster
			rast <- raster(file.tif)
			
			# This is the color function
			pal <- colorNumeric(
				palette = 'Spectral',
				domain = values(rast),
				na.color = NA)
			
			if (input$variable == 'TotalPrecipitation') {
				values(rast)[which(values(rast) == 0)] <- NA
			}
			
			m <- leaflet() %>%
				setView(
					lng = xFromCol(rast, ncol(rast) / 2),
					lat = yFromRow(rast, nrow(rast) / 2),
					zoom = zoom) %>%
				addTiles() %>%
				addRasterImage(
					rast, colors = pal,
					opacity = rast.alpha,
					project = F) %>%
				addLegend(
					pal = pal, values = values(rast),
					title = gsub(regex, '\\2', file.tif))
		}
	})
}

shinyApp(ui, shinyserver)

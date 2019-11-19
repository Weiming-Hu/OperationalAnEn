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

# Define the function to draw arrows
# Referenced from shape::Arrowhead
# 
arrow.shapes <- function (
	x0, y0, angle = 0, arr.length = 0.4, arr.width = arr.length/2, 
	arr.adj = 0.5, arr.type = "curved", lcol = "black", lty = 1, 
	arr.col = lcol, arr.lwd = 2, npoint = 5, ...) {
	
	require(sp)
	require(raster)
	
	if (arr.type == "curved") {
		rad <- 0.7
		len <- 0.25 * pi
		mid <- c(0, rad)
		x <- seq(1.5 * pi + len, 1.5 * pi, length.out = npoint)
		rr <- cbind(mid[1] - rad * cos(x), mid[2] + rad * sin(x))
		mid <- c(0, -rad)
		x <- rev(x)
		rr <- rbind(rr, cbind(mid[1] - rad * cos(x), mid[2] - 
														rad * sin(x)))
		mid <- c(rr[nrow(rr), 1], 0)
		rd <- rr[1, 2]
		x <- seq(pi/2, 3 * pi/2, length.out = 3 * npoint)
		rr <- rbind(rr, cbind(mid[1] - rd * 0.25 * cos(x), mid[2] - 
														rd * sin(x)))
		rr[, 1] <- rr[, 1] * 2.6
		rr[, 2] <- rr[, 2] * 3.45
	}
	else if (arr.type == "triangle") {
		x <- c(-0.2, 0, -0.2)
		y <- c(-0.1, 0, 0.1)
		rr <- 6.22 * cbind(x, y)
	}
	else if (arr.type %in% c("circle", "ellipse")) {
		if (arr.type == "circle") 
			arr.width = arr.length
		rad <- 0.1
		mid <- c(-rad, 0)
		x <- seq(0, 2 * pi, length.out = 15 * npoint)
		rr <- 6.22 * cbind(mid[1] + rad * sin(x), mid[2] + rad * 
											 	cos(x))
	}
	if (arr.adj == 0.5) 
		rr[, 1] <- rr[, 1] - min(rr[, 1])/2
	if (arr.adj == 0) 
		rr[, 1] <- rr[, 1] - min(rr[, 1])
	user <- par("usr")
	pcm <- par("pin") * 2.54
	sy <- (user[4] - user[3])/pcm[2]
	sx <- (user[2] - user[1])/pcm[1]
	nr <- max(length(x0), length(y0), length(angle), length(arr.length), 
						length(arr.width), length(lcol), length(lty), length(arr.col))
	if (nr > 1) {
		x0 <- rep(x0, length.out = nr)
		y0 <- rep(y0, length.out = nr)
		angle <- rep(angle, length.out = nr)
		arr.length <- rep(arr.length, length.out = nr)
		arr.width <- rep(arr.width, length.out = nr)
		lcol <- rep(lcol, length.out = nr)
		lty <- rep(lty, length.out = nr)
		arr.col <- rep(arr.col, length.out = nr)
	}
	RR <- rr
	mat.l <- list()
	for (i in 1:nr) {
		dx <- rr[, 1] * arr.length[i]
		dy <- rr[, 2] * arr.width[i]
		angpi <- angle[i]/180 * pi
		cosa <- cos(angpi)
		sina <- sin(angpi)
		RR[, 1] <- cosa * dx - sina * dy
		RR[, 2] <- sina * dx + cosa * dy
		RR[, 1] <- x0[i] + RR[, 1] * sx
		RR[, 2] <- y0[i] + RR[, 2] * sy
		
		mat.l <- c(mat.l, list(RR))
	}
	
	spplys <- spPolygons(mat.l)
	
	return(spplys)
}


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

			if (grepl('Direction', file.tif)) {
				cell.centers <- coordinates(rast)
				spplys <- arrow.shapes(
					cell.centers[, 1], cell.centers[, 2],
					values(rast), arr.length = 2)
				
				leafletProxy('weatherMap') %>%
					clearImages() %>%
					clearShapes() %>%
					removeControl(layerId = 'legend') %>%
					addPolygons(data = spplys,
											fillColor = 'transparent',
											weight = 1, color = 'black')
				
			} else {
				leafletProxy('weatherMap') %>%
					clearImages() %>%
					clearShapes() %>%
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




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

get.url <- function(current.date = Sys.Date(), lead.times = '00', server = 'NCEP') {
	
	stopifnot(class(current.date) == 'Date')
	
	current.date <- str_remove_all(current.date, "-")
	
	urls <- c()
	
	for (lead.time in lead.times) {
		if (server == 'NCEP') {
			
			# Use the server from NCEP (near-real time)
			server.url <- 'https://nomads.ncep.noaa.gov/pub/data/nccf/com/nam/prod'
			
			# Create the url
			urls <- c(urls, paste(server.url, "/nam.", current.date, "/",
														"nam.t00z.awphys", lead.time, ".tm00.grib2", sep = ""))
								
		} else if (server == 'NOAA') {
			
			stop('Wrong server!')
			
			YM <- substr(current.date, 1, nchar(current.date) -2)
			#Last 3 numbers decide which tile is selected from the full image. Need to determine which one to use.
			url <- paste(server.url, YM, "/", current.date, "/", destfile, sep = "")
			# Use the server from NOAA (3 day delay)
			# server.url <- 'https://nomads.ncdc.noaa.gov/data/meso-eta-hi/'
			
		} else {
			stop('Wrong server!')
		}
	}
	
	return(urls)
}

create.raster <- function(forecasts, par.index, nrow = 428, ncol = 614,
													crs.latlon = NA, fun = mean, palette = 'magma',
													shift.x = T) {
	require(raster)
	require(leaflet)
	
	if (identical(crs.latlon, NA)) {
		require(sp)
		crs.latlon = CRS("+proj=longlat +datum=WGS84")
	}
	
	xyz <- data.frame(
		x = forecasts$Xs,
		y = forecasts$Ys,
		z = forecasts$Data[i.par, , 1, 1])
	
	if (shift.x) {
		xyz$x <- xyz$x - 360
	}
	
	rast <- raster(
		extent(xyz[, c('x', 'y')]), nrow = nrow, ncol = ncol,
		crs = crs.latlon)
	
	# rasterize the data values
	rast <- rasterize(
		xyz[, c('x', 'y')], rast,
		xyz[, 'z'], fun = fun)
	
	# Create color for this raster
	pal <- colorNumeric(
		palette, values(rast),
		na.color = "transparent")
	
	return(list(raster = rast, color = pal))
}

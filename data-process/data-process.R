# This script downloads and processes data

library(pbmcapply)
library(leaflet)
library(stringr)
library(raster)
library(rgdal)
library(ncdf4)
library(RAnEn)
library(shiny)
library(maps)

# Define the FLTs to download and process
flts <- c(str_pad(0:36, width = 2, pad = 0),
					seq(39, 84, by = 3))

flts <- flts[1:10]

# Define the parameters to generate raster layers
variable.names <- c('2MetreTemperature', 'TotalPrecipitation')

# Define the project root folder
project.root <- '~/github/OperationalAnEn'
source(paste0(project.root, '/data-process/functions.R'))

current.date <- Sys.Date()
current.date.str <- format(
	current.date, format = '%Y%m%d')

# Define configuration file path for gribConverter
file.cfg <- paste0(project.root, '/data-process/grb2nc-basic.cfg')
stopifnot(file.exists(file.cfg))

# Define configuration file path for subset stations
file.cfg.subset <- paste0(project.root, '/data-process/grb2nc-east.cfg')

# Define the output data folder
folder.output <- paste0(project.root, '/data-process/app-data')
stopifnot(dir.exists(folder.output))

# Define the output NetCDF file
file.nc <- paste0(folder.output, '/', current.date.str, '.nc')
unlink(file.nc)

# Define the urls to download
urls <- get.url(current.date = current.date, lead.time = flts)
destfiles <- paste0(
	folder.output, '/', current.date.str, '_', flts, '.grb2')

ret <- pbmclapply(1:length(urls), function(i, urls, destfiles) {
	if (file.exists(destfiles[i])) {
		return(0)
	} else {
		return(download.file(
			urls[i], destfiles[i],
			method = "auto", quiet = FALSE))}},
	urls = urls, destfiles = destfiles,
	mc.cores = 4, mc.cleanup = T)

# Check whether the download succeeded
if (any(unlist(ret) != 0)) {
	cat('Try to download the following files:\n',
			paste(urls, collapse = '\n '))
	stop('Download failed!')
}

# Flat GRIB messages
ret <- pbmclapply(destfiles, function(file) {
	file.flat <- gsub('\\.grb2$', '_flat.grb2', file)
	
	if (file.exists(file.flat)) {
		return(0)
	} else {
		return(system(paste(
			'/usr/bin/grib_copy', file, file.flat)))
	}
}, mc.cores = 4, mc.cleanup = T)

# Check whether the process succeeded
if (any(unlist(ret) != 0)) {
	stop('Flattening GRIB2 failed!')
}

# File conversion from grb2 to NetCDF
command <- paste(
	'/home/graduate/wuh20/github/AnalogsEnsemble/output/bin/gribConverter -c',
	file.cfg, file.cfg.subset, '--folder', folder.output, '--output', file.nc)

ret <- system(command)

# Convert NetCDF to raster stack
forecasts <- readForecasts(file.nc)

# Shift X coordinates
forecasts$Xs <- forecasts$Xs - 360

# Create an extent for the forecast grid points
crs <- crs('+proj=longlat +datum=WGS84')
sppts <- SpatialPoints(
	cbind(forecasts$Xs, forecasts$Ys),
	proj4string = crs)
ext <- extent(sppts)

# Write each layer into a tiff image
for (i.flt in 1:length(forecasts$FLTs)) {
	for (i.par in 1:length(forecasts$ParameterNames)) {
		if (forecasts$ParameterNames[i.par] %in% variable.names) {
			rast <- raster(ext, res = 0.25, crs = crs)
			rast <- rasterize(
				x = sppts, y = rast,
				field = forecasts$Data[i.par, , 1, i.flt])
			writeRaster(rast, filename = paste0(
				folder.output, '/', current.date.str, '-',
				forecasts$ParameterNames[i.par], '-',
				forecasts$FLTs[i.flt], '.tif'),
				format = 'GTiff', overwrite = T)
		}
	}
}

if (ret == 0) {
	files.to.remove <- list.files(
		path = folder.output, pattern = "grb2", full.names = T)
	file.remove(files.to.remove, file.nc)
}

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

project.root <- '~/github/OperationalAnEn'
current.date <- Sys.Date()

# Define configuration file path for gribConverter
file.cfg <- paste0(project.root, '/data-process/grb2nc-basic.cfg')
stopifnot(file.exists(file.cfg))

# Define configuration file path for subset stations
file.cfg.subset <- paste0(project.root, '/data-process/grb2nc-east.cfg')

# Define the output data folder
folder.output <- paste0(project.root, '/data-process/app-data')
stopifnot(dir.exists(folder.output))

# Define the output NetCDF file
file.output <- paste0(folder.output, '/', format(
	current.date, format = '%Y%m%d'), '.nc')

if (file.exists(file.output)) {
	cat('Output file exists. Skip processing!\n')
} else {
	source(paste0(project.root, '/data-process/functions.R'))
	
	flts <- c('00', '03', '06')
	
	urls <- get.url(current.date = current.date, lead.time = flts)
	destfiles <- paste0(
		folder.output, '/', format(
			current.date, format = "%Y%m%d"), '_', flts, '.grb2')
	
	ret <- pbmclapply(1:length(urls), function(i, urls, destfiles) {
		if (file.exists(destfiles[i])) {return(0)}
		else {return(download.file(urls[i], destfiles[i],
															 method = "auto", quiet = FALSE))}
	}, urls = urls, destfiles = destfiles, mc.cores = 3)
	
	# Check whether the download succeeded
	if (any(unlist(ret) != 0)) {
		cat('Try to download the following files:\n',
				paste(urls, collapse = '\n '))
		stop('Download failed!')
	}
	
	# Flat GRIB messages
	for (file in destfiles) {
		file.flat <- gsub('\\.grb2$', '_flat.grb2', file)
		
		if (file.exists(file.flat)) {
			cat("File exists. Skip file", file.flat, '\n')
		} else {
			
			command <- paste('/usr/bin/grib_copy', file, file.flat)
			cat('Processing', command, '\n')
			ret <- system(command)
			stopifnot(ret == 0)
		}
	}
	
	# File conversion from grb2 to NetCDF
	command <- paste(
		'/home/graduate/wuh20/github/AnalogsEnsemble/output/bin/gribConverter -c',
		file.cfg, file.cfg.subset, '--folder', folder.output, '--output', file.output)
	
	ret <- system(command)
	
	if (ret == 0) {
		files.to.remove <- list.files(
			path = folder.output, pattern = "grb2", full.names = T)
		file.remove(files.to.remove)
	}
}

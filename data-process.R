library(pbmcapply)
library(leaflet)
library(stringr)
library(raster)
library(rgdal)
library(ncdf4)
library(RAnEn)
library(shiny)
library(maps)

source('functions.R')

if (file.exists('output/output.nc')) {
	cat('Output file exists. Skip processing!\n')
} else {
	
	current.date <- Sys.Date()
	flts <- c('00', '03', '06')
	
	urls <- get.url(current.date = current.date, lead.time = flts)
	destfiles <- paste0(
		'output/', format(current.date, format = "%Y%m%d"),
		'_', flts, '.grb2')
	
	ret <- pbmclapply(1:length(urls), function(i, urls, destfiles) {
		return(download.file(urls[i], destfiles[i], method = "auto", quiet = FALSE))
	}, urls = urls, destfiles = destfiles, mc.cores = 3)
	
	
	# Check whether the download succeeded
	if (any(unlist(ret) != 0)) {
		stop('Download failed! Make sure the URL is accessible and the destination file path is valid.')
	}
	
	# Flat GRIB messages
	for (file in destfiles) {
		
		command <- paste('/usr/bin/grib_copy', file, gsub('\\.grb2$', '_flat.grb2', file))
		cat('Processing', command, '\n')
		
		ret <- system(command)
		
		stopifnot(ret == 0)
	}
	
	
	#This is downloading the wrong file and I am not sure why? The file size is significantly smaller than what is described.
	
	# File conversion from grb2 to NetCDF
	command <- paste(
		'/home/graduate/wuh20/github/AnalogsEnsemble/output/bin/gribConverter -c grb2nc-NAM.cfg',
		'--folder ./output/',
		'--output ./output/output.nc')
	
	ret <- system(command)
}



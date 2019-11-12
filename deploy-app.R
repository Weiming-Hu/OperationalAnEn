#!/usr/bin/Rscript

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

# This script deploys the Shinyapp for current date

# Define the project root folder
project.root <- '~/github/OperationalAnEn'

# Get current date
current.date <- Sys.Date()
current.date.str <- format(current.date, format = '%Y%m%d')

# Define some folders
folder.server <- '/home/graduate/wuh20/ShinyApps/operationalanen'
folder.app <- paste0(project.root, '/data-process/app-data')
file.app <- paste0(folder.app, '/app.R')

# Sanity checks
stopifnot(dir.exists(c(folder.app, folder.server)))
stopifnot(file.exists(file.app))

# Check whether files have been already generated for today
files <- list.files(
	folder.app, paste0('^', current.date.str, '.*\\.tif'),
	full.names = T)

if (length(files) == 0) {
	source(paste0(project.root, '/data-process/data-process.R'))
}

# Match files for all days
files <- list.files(
	folder.app, paste0('.tif'),
	full.names = T)

files.copy <- c(files, file.app)
ret <- file.copy(from = files.copy, to = folder.server, overwrite = T)
stopifnot(ret)

cat('ShinyApp has been deployed to', folder.server, '!\n')

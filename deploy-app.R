# This script deploys the Shinyapp for current date

current.date <- Sys.Date()
project.root <- '~/github/OperationalAnEn'

# Define some folders
project.process <- paste0(project.root, '/data-process')
file.app <- paste0(project.process, '/app-data/app.R')
folder.server <- '/home/graduate/wuh20/ShinyApps/operationalanen'

# Sanity checks
stopifnot(dir.exists(c(project.process, folder.server)))
stopifnot(file.exists(file.app))

# Check whether the data has been preprocessed
file.data <- paste0(project.process, '/app-data/', format(
	current.date, format = '%Y%m%d'), '.nc')

if (file.exists(file.data)) {
	cat('The data file has been found. Deploy the app ...\n')
} else {
	cat('The data file has not been found. Preprocess data ...\n')
	source(paste0(project.process, '/data-process.R'))
}

files.copy <- c(file.data, file.app)
ret <- file.copy(from = files.copy, to = folder.server, overwrite = T)
stopifnot(ret)
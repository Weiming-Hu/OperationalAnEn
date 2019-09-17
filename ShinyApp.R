for (library in c('shiny', 'leaflet', 'maps')) {
	if (requireNamespace(library)) {
		install.packages(library)
	} else {
		library(library)
	}	
}

ui <- fluidPage(
  titlePanel("State College, PA"),
    leafletOutput("mymap")
)

server <- function(input, output) {
  
  output$mymap <- renderLeaflet({
    m <- leaflet() %>%
      setView(lng = -77.8653, lat = 40.8000, zoom = 10)
    m %>% addTiles()
    
  })
}

shinyApp(ui, server)

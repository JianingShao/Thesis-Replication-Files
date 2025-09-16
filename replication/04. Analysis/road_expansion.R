## This file plots the evolution of the road network in Brazil between 1960-2010
library(sf)
library(sp)
library(raster)
library(tidyverse)
library(ggrepel)
gisdata <- "C:/Users/JianingShao/OneDrive - London School of Economics/Thesis/GIS_raw"
outpath <- "C:/Users/JianingShao/OneDrive - London School of Economics/Thesis/analysis/appendix"
## Read in the state file
states <- st_read(file.path(gisdata,"/uf27/uf27_prj.shp"))
## Simplify so easier to plot
states_simple  <- rmapshaper::ms_simplify(states,keep=0.01,keep_shapes=TRUE)
object.size(states)
object.size(states_simple)
st_geometry_type(states)
st_crs(states)

capital_cities <- st_read(file.path(gisdata,"/cities/brazil_capital_cities_prj.shp"))

loop = 1

cities_xy <- cbind(capital_cities,st_coordinates(capital_cities))

## Make the figures
for (year in c(1960, 1970, 1980, 1990, 2000, 2010)) {
  
  file_name = paste0("/",year,"/highways_",year,"_prj.shp")
  all_highways <- st_read(file.path(gisdata, "roads", file_name))
  all_highways_simple  <- rmapshaper::ms_simplify(all_highways,keep=0.01,keep_shapes=TRUE)
  all_highways_simple[is.na(all_highways_simple)]  <- 0
  
  
  ## Make figure
  temp_plot  <- ggplot() +
    geom_sf(data=states_simple, fill="grey90", color="grey30") +
    geom_sf(data=all_highways_simple, fill="blue", size=.4, aes(color = "All highways"), show.legend = "line") +
    ggtitle(year) +
    coord_sf() +
    theme_minimal() +
    geom_sf(data=capital_cities, aes(fill=CITY_NAME, geometry=geometry), show.legend=FALSE) +guides(fill=FALSE) +
    geom_text_repel(data=cities_xy,aes(x=X,y=Y,label=CITY_NAME), show.legend=FALSE) 
  
  ## Save the file to PDF
  save_name <- paste0("roads",year,".png")
  ggsave(file.path(outpath,"roads", save_name), width = 8, height = 8)
  
  loop = loop+1
  
}


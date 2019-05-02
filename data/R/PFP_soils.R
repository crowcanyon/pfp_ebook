library(FedData)
library(magrittr)
library(sf)

source("./data/R/summarise_mapunits.R")

ccac <- sf::st_read("https://raw.githubusercontent.com/bocinsky/Bocinsky_Varien_2017/master/DATA/ccac.geojson")# %>%
  # sf::st_union()

# Download the NRCS SSURGO soils data for the study area
# This downloads the soils data for the CO671 soil survey
FedData::get_ssurgo(template = ccac %>% 
                      as("Spatial"),
                    label = "ccac",
                    raw.dir = "./data/ssurgo/",
                    extraction.dir = "./data/ssurgo/",
                    force.redo =  F) %>%
  summarise_mapunits() %>%
  dplyr::mutate(popup = stringr::str_c("<b>",`Soil Name`,"</b><br/>",
                                       "<p>Soil area: ",round(Area, digits=2)," ha<br/>",
                                       "Net Primary Productivity (kg/ha): ",round(`Net Primary Productivity (kg/ha)`),"<br/>",
                                       "% Sand: ",round(`% Sand`,digits=2),"<br/>",
                                       "% Silt: ",round(`% Silt`, digits=2),"<br/>",
                                       "% Clay: ",round(`% Clay`, digits=2),"<br/>",
                                       "Available Water Content (in/in): ",round(`Available Water Content (in/in)`, digits=2),"<br/>",
                                       "Albedo (dry%): ",round(Albedo * 100, digits=2),"<br/>",
                                       "</p>")) %>%
  sf::st_write("./data/soils.geojson",
               driver = "GeoJSON",
               delete_dsn = TRUE)

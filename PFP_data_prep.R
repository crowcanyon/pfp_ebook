# Script
install.packages("pak", repos = "http://cran.us.r-project.org")

pak::pak(c(
  "tidyverse",
  "Hmisc",
  "sf",
  "terra",
  "FedData",
  "plotly",
  "bookdown",
  "zoo",
  "svglite",
  "leaflet",
  "mapview",
  "widgetframe",
  "dygraphs"
))

# Seasons for plotting
seasons <- 2009:2023

source("data/R/calc_gdd.R")
source("data/R/PFP_weather_stations.R")
source("data/R/summarise_mapunits.R")
source("data/R/PFP_soils.R")
source("data/R/PFP_gardens.R")

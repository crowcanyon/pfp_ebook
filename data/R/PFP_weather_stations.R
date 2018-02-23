library(magrittr)

source("./data/R/calc_gdd.R")

## (Down)load the weather station data for Cortez
cortez_weather <- c(FedData::get_ghcn_daily_station(ID="USC00051886",
                                                    elements = c("TMIN","TMAX"), 
                                                    standardize = T, 
                                                    raw.dir = "./data/ghcn/"),
                    FedData::get_ghcn_daily_station(ID="USC00051886", elements = c("PRCP"), 
                                                    raw.dir = "./data/ghcn/")) %>%
  FedData::station_to_data_frame() %>%
  dplyr::as_data_frame() %>%
  dplyr::filter(lubridate::year(DATE) %in% seasons) %>%
  dplyr::mutate(DATE = lubridate::ymd(DATE),
                TMIN = zoo::na.approx(TMIN/10, na.rm = F),
                TMAX = zoo::na.approx(TMAX/10, na.rm = F),
                FGDD = calc_gdd(tmin = TMIN, tmax = TMAX, t.base=8, t.cap=30, to_fahrenheit=T),
                TMAX = ((TMAX)*1.8 + 32),
                TMIN = ((TMIN)*1.8 + 32),
                PRCP = PRCP*0.00393701) %>%
  dplyr::rename(TMAX_F = TMAX, TMIN_F = TMIN, PRCP_IN = PRCP)

readr::write_csv(cortez_weather,"./data/cortez_weather.csv")

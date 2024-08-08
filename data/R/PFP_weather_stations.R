library(magrittr)

## (Down)load the weather station data for Cortez
cortez_weather <- 
  readr::read_csv("https://www.ncei.noaa.gov/data/global-historical-climatology-network-daily/access/USC00051886.csv")%>%
  dplyr::select(DATE, TMIN, TMAX,  PRCP) %>%
    dplyr::filter(lubridate::year(DATE) %in% seasons) %>%
    dplyr::mutate(DATE = lubridate::ymd(DATE),
                  TMIN = zoo::na.approx(TMIN/10, na.rm = F),
                  TMAX = zoo::na.approx(TMAX/10, na.rm = F),
                  FGDD = calc_gdd(tmin = TMIN, tmax = TMAX, t.base=10, t.cap=30, to_fahrenheit=T),
                  TMAX = ((TMAX)*1.8 + 32),
                  TMIN = ((TMIN)*1.8 + 32),
                  PRCP = PRCP*0.00393701) %>%
    dplyr::rename(TMAX_F = TMAX, 
                  TMIN_F = TMIN, 
                  PRCP_IN = PRCP)

readr::write_csv(cortez_weather,"data/cortez_weather.csv")

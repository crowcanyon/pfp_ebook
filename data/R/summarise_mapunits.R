summarise_mapunits <- function(SSURGO,
                                           bottom_depth = 60){
  
  library(units)
  # Horizon data

  chorizon <- tibble::as_tibble(SSURGO$tabular$chorizon) %>%
    dplyr::mutate(hzdept.r = hzdept.r * 0.393701, hzdepb.r = hzdepb.r * 0.393701) %>%  # Convert depth measurements to inches.
    dplyr::filter(hzdept.r < bottom_depth) %>% # Only include soil horizons that begin less than 60 inches below the surface
    dplyr::mutate(hzdepb.r = ifelse(hzdepb.r > bottom_depth,bottom_depth,hzdepb.r),
                  horizon_thickness = hzdepb.r - hzdept.r) %>% # Truncate horizons that end below 60 inches
    dplyr::select(cokey,
                  horizon_thickness,
                  sandtotal.r,
                  silttotal.r,
                  claytotal.r,
                  awc.r) %>%
    # dplyr::filter(!is.na(awc.r)) %>% # Remove horizons with no AWC
    dplyr::group_by(cokey) %>%
    dplyr::summarise(sandtotal.r = weighted.mean(sandtotal.r,horizon_thickness, na.rm = T),
                     silttotal.r = weighted.mean(silttotal.r,horizon_thickness, na.rm = T),
                     claytotal.r = weighted.mean(claytotal.r,horizon_thickness, na.rm = T),
                     awc.r = weighted.mean(awc.r,horizon_thickness, na.rm = T))
  
  # Join component AWCs to component table
  components <- tibble::as_tibble(SSURGO$tabular$component) %>%
    dplyr::select(mukey,
                  cokey,
                  comppct.r,
                  albedodry.r,
                  rsprod.r) %>%
    dplyr::left_join(chorizon) %>%
    dplyr::group_by(mukey) %>%
    dplyr::summarise(sandtotal.r = weighted.mean(sandtotal.r,comppct.r, na.rm = T),
                     silttotal.r = weighted.mean(silttotal.r,comppct.r, na.rm = T),
                     claytotal.r = weighted.mean(claytotal.r,comppct.r, na.rm = T),
                     awc.r = weighted.mean(awc.r,comppct.r, na.rm = T),
                     albedodry.r = weighted.mean(albedodry.r,comppct.r, na.rm = T),
                     rsprod.r = weighted.mean(rsprod.r,comppct.r, na.rm = T))
  
  
dplyr::left_join(SSURGO$spatial %>% 
                          sf::st_as_sf() %>%
                                            dplyr::mutate(MUKEY = MUKEY %>%
                                                            as.character() %>%
                                                            as.integer()),
                                          components,
                                          by = c("MUKEY" = "mukey")
  ) %>%
  dplyr::select(-AREASYMBOL:-MUSYM) %>%
  dplyr::left_join(SSURGO$tabular$mapunit %>%
                     dplyr::select(mukey,
                                   muname),
                   by = c("MUKEY" = "mukey")) %>%
  dplyr::select(-MUKEY) %>%
  dplyr::mutate(rsprod.r = rsprod.r * 1.12085) %>%
  dplyr::select(`Soil Name` = muname,
                `% Sand` = sandtotal.r,
                `% Silt` = silttotal.r,
                `% Clay` = claytotal.r,
                `Available Water Content (in/in)` = awc.r,
                `Albedo` = albedodry.r,
                `Net Primary Productivity (kg/ha)` = rsprod.r) %>%
  dplyr::mutate(Area = sf::st_area(geom) %>% set_units(ha))
  
}

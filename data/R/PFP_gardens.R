# # Read in the PFP data directly from the PFP results database
# unlink("./data/Pueblo Farmers Project database.mdb", recursive = TRUE, force = TRUE)
# file.copy(from = "/Volumes/USERS/Pueblo Farming Project/DATA/Pueblo Farmers Project database.mdb",
#           to="./data/PFP_database.mdb",
#           overwrite = TRUE)
PFP_data <- 
  Hmisc::mdb.get("./data/PFP_database.mdb") %>%
  purrr::map(.f = dplyr::as_tibble)

# Read in the garden table, and export a csv
gardens <- PFP_data$`tbl Summary garden annual info` %>%
  dplyr::select(Season,
                Garden,
                Variety,
                Clumps,
                PlantingDate,
                HarvestDate,
                Spacing,
                Comments) %>%
  dplyr::mutate(PlantingDate = lubridate::mdy(PlantingDate)) %>%
  dplyr::arrange(Garden, Season) %>%
  dplyr::filter(Season %in% seasons) %>% # Only keep the right seasons
  dplyr::arrange(Season,Garden) %>%
  dplyr::filter(!is.na(PlantingDate))

readr::write_csv(gardens,"./data/gardens.csv")

# Read in the garden data
gardens <- readr::read_csv("./data/gardens.csv")

# Read in the growth table
growth <- PFP_data$`tbl growth` %>%
  tibble::as_tibble() %>%
  dplyr::mutate(Date = Date %>%
                  lubridate::mdy_hms() %>%
                  lubridate::as_date(),
                Season = lubridate::year(Date)) %>%
  dplyr::filter(Season %in% seasons)

# Fill in the missing clump observations with NAs

harvest_dates <- growth %>%
  dplyr::select(Season,Date) %>%
  dplyr::group_by(Season) %>%
  dplyr::summarise(Date = max(Date))

growth <- growth %$%
  Garden %>%
  unique() %>%
  purrr::map_dfr(function(g){
    PFP_data_growth <- growth %>%
      dplyr::select(Season,
                    Date,
                    Garden,
                    Clump) %>%
      dplyr::arrange(Date) %>%
      dplyr::filter(Garden == g)
    
    PFP_data_growth$Season %>%
      unique() %>%
      sort() %>%
      purrr::map_dfr(
        function(y){
          
          if(!(y %in% seasons)) return(NULL)
          
          sub <- PFP_data_growth %>%
            dplyr::filter(Season == y) %>%
            dplyr::select(-Season)
          
          this.gardens <- gardens %>%
            dplyr::filter(Garden == g, Season == y)
          
          
          expand.grid(Date = sort(c((this.gardens %>%
                                       dplyr::select(PlantingDate))[[1]] %>% lubridate::as_date(),
                                    sub$Date,
                                    this.gardens$PlantingDate,
                                    harvest_dates %>% 
                                      dplyr::filter(Season == y) %$% 
                                      Date)) %>%
                        unique(),
                      Garden = g,
                      Clump = 1:(this.gardens %>%
                                   dplyr::select(Clumps) %>%
                                   unlist() %>%
                                   as.numeric())) %>%
            tibble::as_tibble() %>%
            dplyr::mutate(Season = y)
          
        })
  }) %>%
  dplyr::left_join(growth,
                   by = c("Date",
                          "Garden",
                          "Clump",
                          "Season"))

# A function to make a logical column monotonic
make_mono <- function(x){
  x %>%
    stats::filter(filter=1,
                  method="recursive") %>%
    as.logical()
}

# Recode variables and make them monotonic within groups
growth %<>%
  dplyr::group_by(Season, Garden, Clump) %>%
  dplyr::mutate(Removed = ifelse(is.na(Removed),0,Removed),
                Removed = max(Removed, na.rm = T)) %>%
  dplyr::ungroup() %>%
  dplyr::filter(Removed != 1) %>%
  dplyr::rename(`Early Tassel Development` = ETD,
                `Tassel Development` = TD,
                `Tasseling` = `T`,
                `Silk Development` = SD,
                `Silking` = S,
                `Ear Development` = ED) %>%
  # dplyr::select(Date,Garden,Clump,`Early Tassel Development`,`Tassel Development`,`Tasseling`,`Silk Development`,`Silking`,`Ear Development`) %>%
  dplyr::arrange(Date) %>%
  dplyr::mutate(`Early Tassel Development` = as.logical(`Early Tassel Development`),
                `Tassel Development` = as.logical(`Tassel Development`),
                `Tasseling` = as.logical(`Tasseling`),
                `Silk Development` = as.logical(`Silk Development`),
                `Silking` = as.logical(`Silking`),
                `Ear Development` = as.logical(`Ear Development`)) %>%
  dplyr::mutate(`Early Tassel Development` = ifelse(is.na(`Early Tassel Development`),FALSE,`Early Tassel Development`),
                `Tassel Development` = ifelse(is.na(`Tassel Development`),FALSE,`Tassel Development`),
                `Tasseling` = ifelse(is.na(`Tasseling`),FALSE,`Tasseling`),
                `Silk Development` = ifelse(is.na(`Silk Development`),FALSE,`Silk Development`),
                `Silking` = ifelse(is.na(`Silking`),FALSE,`Silking`),
                `Ear Development` = ifelse(is.na(`Ear Development`),FALSE,`Ear Development`)) %>%
  dplyr::mutate(`Silking` = ifelse(`Ear Development`,TRUE,`Silking`),
                `Silk Development` = ifelse(`Silking`,TRUE,`Silk Development`),
                `Tasseling`=ifelse(`Silk Development`,TRUE,`Tasseling`),
                `Tassel Development` = ifelse(`Tasseling`,TRUE,`Tassel Development`),
                `Early Tassel Development` = ifelse(`Tassel Development`,TRUE,`Early Tassel Development`)) %>%
  # dplyr::mutate(Season = year(Date)) %>%
  # dplyr::filter(Season %in% seasons) %>% # Only keep years 2009:2015
  dplyr::group_by(Season, Garden, Clump) %>% 
  dplyr::mutate(`Early Tassel Development` = make_mono(`Early Tassel Development`),
                `Tassel Development` = make_mono(`Tassel Development`),
                `Tasseling` = make_mono(`Tasseling`),
                `Silk Development` = make_mono(`Silk Development`),
                `Silking` = make_mono(`Silking`),
                `Ear Development` = make_mono(`Ear Development`)) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(gardens %>% 
                     dplyr::select(Season,
                                   Garden,
                                   Variety),
                   by = c("Season",
                          "Garden")) %>%
  dplyr::select(Season,
                Date,
                Garden,
                Variety,
                Clump, 
                dplyr::everything())

# Write a csv of the growth table
readr::write_csv(growth,"./data/growth.csv")



cortez_weather <- readr::read_csv("./data/cortez_weather.csv")

# Summarize growth data into proportions of clumps to reach developmental stages
growth_summaries <- growth %>%
  dplyr::group_by(Date,
                  Garden) %>%
  dplyr::summarise(`Early Tassel Development` = mean(`Early Tassel Development`, na.rm = T),
                   `Tassel Development` = mean(`Tassel Development`, na.rm = T),
                   `Tasseling` = mean(`Tasseling`, na.rm = T),
                   `Silk Development` = mean(`Silk Development`, na.rm = T),
                   `Silking` = mean(`Silking`, na.rm = T),
                   `Ear Development` = mean(`Ear Development`, na.rm = T)) %>%
  dplyr::mutate(Season = lubridate::year(Date)) %>%
  dplyr::filter(Season %in% seasons) %>% # Only keep years 2009:2015
  dplyr::left_join(gardens %>% 
                      dplyr::select(Season,
                                    Garden,
                                    Variety), 
                   by = c("Season","Garden")) %>%
  dplyr::mutate(Variety = as.factor(Variety)) %>%
  dplyr::select(Season,
                Date,
                Garden,
                dplyr::everything()) %>%
  dplyr::arrange(Date,
                 Garden)

growth_summaries <- growth_summaries %$%
  Garden %>%
  unique() %>%
  purrr::map_dfr(function(g){

    PFP_data_growth <- growth_summaries %>%
      dplyr::select(Season,Date,Garden) %>%
      dplyr::arrange(Date) %>%
      dplyr::filter(Garden == g)
    
    PFP_data_growth %$%
      Season %>%
      unique() %>%
      sort() %>%
      purrr::map_dfr(function(y){
        
        gardens_year <- gardens %>%
          dplyr::filter(Garden == g, Season == y)
        
        PFP_data_growth_year <- PFP_data_growth %>%
          dplyr::filter(lubridate::year(Date) == y)
        
        cortez_weather %>%
          dplyr::filter(lubridate::year(DATE) == y, 
                        DATE > gardens_year$PlantingDate) %>%
          #       dplyr::filter(Location == (weather_station_IDs %>% dplyr::filter(Abbreviation == g))$ID, 
          #                     year(Date_Time) == y, 
          #                     Date_Time >= gardens_year$PlantingDate) %>%
          dplyr::mutate(Acc_FGDD = cumsum(FGDD)) %>%
          dplyr::filter(DATE %in% lubridate::as_date(PFP_data_growth_year$Date)) %>%
          dplyr::select(DATE,
                        Acc_FGDD) %>%
          dplyr::rename(Date = DATE) %>%
          dplyr::mutate(Garden = g)
      })
  }) %>%
  dplyr::right_join(growth_summaries,
                    by = c("Date",
                           "Garden")) %>%
  dplyr::select(Season,
                Date,
                Garden,
                Acc_FGDD,
                Variety,
                dplyr::everything()) %>%
  dplyr::mutate(Acc_FGDD = ifelse(is.na(Acc_FGDD),0,Acc_FGDD))

readr::write_csv(growth_summaries,"./data/growth_summaries.csv")


## Process the ears data
ears <- PFP_data$`tbl ears` %>%
  dplyr::filter(Ear > 0, !is.na(EarWt)) %>%
  dplyr::select(Season, Garden, EarWt, CobWt, KernelWt, Rows, Condition, Clump, Ear) %>%
  dplyr::rename(`Ear weight` = EarWt, 
                `Cob weight` = CobWt, 
                `Kernel weight` = KernelWt) %>%
  dplyr::mutate(`Kernel weight` = `Ear weight`-`Cob weight`) %>%
  dplyr::filter(Season %in% seasons) %>%
  dplyr::left_join(y = (gardens %>% dplyr::select(Season,Garden,Variety)), by = c("Season","Garden")) %>%
  dplyr::mutate(Variety = as.factor(Variety))

# Estimate Kernel and Cob weight for ears withheld whole from analysis (e.g., POG, 2009, Clump 24)
ears %<>%
  dplyr::group_by(Season,Garden,Condition) %>%
  dplyr::summarise(Kernel_r = mean(`Kernel weight`/`Ear weight`, na.rm = T)) %>%
  dplyr::mutate(Cob_r = 1 - Kernel_r) %>%
  dplyr::full_join(ears, by = c("Season","Garden","Condition")) %>%
  dplyr::mutate(`Kernel weight` = ifelse(is.na(`Kernel weight`),`Ear weight` * Kernel_r,`Kernel weight`), 
                `Cob weight` = ifelse(is.na(`Cob weight`),`Ear weight` * Cob_r,`Cob weight`)) %>%
  dplyr::select(-Kernel_r, -Cob_r) %>%
  dplyr::ungroup() %>%
  dplyr::select(Season,
                Garden,
                Variety,
                Clump,
                Ear,
                Condition,
                Rows,
                dplyr::everything()) %>%
  dplyr::arrange(Season, 
                 Garden, 
                 Clump, 
                 Ear)

readr::write_csv(ears,"./data/ears.csv")

# Read in data recorded about each ear harvested
ears <- readr::read_csv("./data/ears.csv")

# Estimate Kernel and Cob weight for ears withheld whole from analysis (e.g., POG, 2009, Clump 24)
# This is done by calculating the average ratio of kernel to ear weight, and then extrapolating to
# cob and kernel weight for samples for which we only have ear weight.
ears %<>%
  dplyr::group_by(Season,Garden,Condition) %>% # Group by season, garden, and condition
  dplyr::summarise(Kernel_r = mean(`Kernel weight`/`Ear weight`, na.rm = T)) %>% # Calculate kernel to ear ratio
  dplyr::mutate(Cob_r = 1 - Kernel_r) %>% # define cob to ear ratio as 1 minus the kernel to ear ratio
  dplyr::full_join(ears, by = c("Season","Garden","Condition")) %>% # join results back to ears tibble
  dplyr::mutate(`Kernel weight` = ifelse(is.na(`Kernel weight`),
                                         `Ear weight` * Kernel_r,
                                         `Kernel weight`), # Fill missing values
                `Cob weight` = ifelse(is.na(`Cob weight`),
                                      `Ear weight` * Cob_r,
                                      `Cob weight`)) %>%
  dplyr::select(-Kernel_r, -Cob_r) %>% # drop the ratio columns
  dplyr::ungroup() %>%
  dplyr::left_join(y = (gardens %>% dplyr::select(Season,Garden,Variety)), by = c("Season","Garden","Variety")) %>% # join with the gardens data
  dplyr::mutate(Variety = as.factor(Variety)) %>% # turn "variety" into a categorical variable
  dplyr::arrange(Season, Garden, Clump) %>% # sort by these variables
  dplyr::select(Season, Garden, Variety, Clump, Condition, Rows, `Ear weight`, `Cob weight`, `Kernel weight`) # reorder columns

# Create a grid of expected clumps, if all clumps were weighed (they weren't)
expected.clumps <- gardens %>%
  dplyr::select(Season, Garden, Clumps) %>%
  split(.,1:nrow(.)) %>%
  lapply(function(x){
    expand.grid(Season = x$Season, Garden = x$Garden, Clump = 1:(x$Clumps))
  }) %>%
  dplyr::bind_rows()

# Estimate kernel yields by simulating distributions across clump yields
# Here, we calculate three yields:
# the first is just the "raw" yield of kernel weight per garden area;
# in the second, we only calculate over planted area as defined by an estimate of "spacing" between clumps
# in the third, we standardize the density of planting to 2m plant spacing (4 sq m per clump; Beaglehole 1937:40; Bellorado 2007:96; Bradfield 1971:5; Dominguez and Kolm 2003, 2005)
yields <- ears %>%
  dplyr::select(Season, Garden, Clump, `Kernel weight`) %>% #select these columns
  dplyr::group_by(Season, Garden, Clump) %>%# calculations are by season and garden
  dplyr::summarise(`Net kernel weight` = sum(`Kernel weight`)) %>%
  dplyr::full_join(expected.clumps, by = c("Season","Garden","Clump")) %>%
  dplyr::left_join(y = gardens, by = c("Season","Garden")) %>% # join back to gardens
  dplyr::ungroup() %>%
  dplyr::mutate(`Net kernel weight` = ifelse(is.na(`Net kernel weight`),0,`Net kernel weight`)) %>% #recode missing values to zeros; those clumps didn't produce
  dplyr::select(Season:Clumps, Clumps, Spacing) %>% #select these columns
  dplyr::mutate(#`Yield by clump area` = (Clumps * `Net kernel weight`/1000)/((Spacing ^ 2) * Clumps * 0.0001), # yield by actual clump area
    `PFP experimental yield` = (Clumps * `Net kernel weight`/1000)/((2 ^ 2) * Clumps * 0.0001) # yield by clump area with 2m spacing
  ) %>% 
  dplyr::mutate(Variety = as.factor(Variety),
                Garden = as.factor(Garden),
                Season = as.factor(Season)) %>%
  dplyr::arrange(Season, Garden, Clump) %>% # sort by these variables
  dplyr::select(Season,
                Garden,
                Variety,
                Clumps,
                Spacing,
                Clump,
                `Net kernel weight`,
                # `Yield by clump area`,
                `PFP experimental yield`) %>% # reorder columns
  dplyr::group_by(Season, Garden) %>% # calculations are by season and garden 
  dplyr::rename(`Spacing (m)` = Spacing,
                `Net kernel weight (g)` = `Net kernel weight`,
                `PFP experimental yield (kg/ha)` = `PFP experimental yield`)

readr::write_csv(yields,"./data/yields.csv")


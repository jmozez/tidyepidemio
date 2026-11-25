# Weekly confirmed COVID-19 cases in the 62 counties of New York State,
# 2 March to 31 May 2020 (13 weeks), with 2019 county population and centroid
# coordinates. Centroids are also given in kilometres on a local
# equirectangular projection centred on the state (adequate at this scale)
# for use with the planar scan statistics.
# Source: COVID-19 Data Repository by the Center for Systems Science and
# Engineering (CSSE) at Johns Hopkins University,
# https://github.com/CSSEGISandData/COVID-19 (CC BY 4.0).
# Dong E, Du H, Gardner L (2020). Lancet Infect Dis 20(5):533-534.
base <- paste0(
  "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/",
  "csse_covid_19_data/csse_covid_19_time_series/"
)
conf <- utils::read.csv(paste0(base, "time_series_covid19_confirmed_US.csv"), check.names = FALSE)
dead <- utils::read.csv(paste0(base, "time_series_covid19_deaths_US.csv"), check.names = FALSE)
ny <- conf[conf$Province_State == "New York" & conf$Lat != 0 & !is.na(conf$FIPS) & conf$FIPS < 80000, ]
pop <- dead$Population[match(ny$UID, dead$UID)]
date_cols <- grep("^[0-9]+/[0-9]+/[0-9]+$", names(ny), value = TRUE)
dates <- as.Date(date_cols, format = "%m/%d/%y")
cum <- as.matrix(ny[date_cols])
days <- which(dates >= as.Date("2020-03-01") & dates <= as.Date("2020-05-31"))
weekly_end <- days[seq(8, length(days), by = 7)]
weekly <- cum[, weekly_end] - cum[, weekly_end - 7]
weekly[weekly < 0] <- 0
lat0 <- mean(ny$Lat); lon0 <- mean(ny$Long_)
ny_covid_counties_2020 <- tibble::tibble(
  county = ny$Admin2, fips = as.integer(ny$FIPS), population = as.integer(pop),
  lon = ny$Long_, lat = ny$Lat,
  x_km = 111.32 * cos(lat0 * pi / 180) * (ny$Long_ - lon0),
  y_km = 110.57 * (ny$Lat - lat0)
)
week_names <- paste0("week_", format(dates[weekly_end], "%m%d"))
for (j in seq_along(week_names)) ny_covid_counties_2020[[week_names[j]]] <- as.integer(weekly[, j])
usethis::use_data(ny_covid_counties_2020, overwrite = TRUE)

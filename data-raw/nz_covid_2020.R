# Daily confirmed COVID-19 cases, New Zealand, first wave (Feb to Jun 2020).
# Source: COVID-19 Data Repository by the Center for Systems Science and
# Engineering (CSSE) at Johns Hopkins University,
# https://github.com/CSSEGISandData/COVID-19 (CC BY 4.0).
# Dong E, Du H, Gardner L (2020). An interactive web-based dashboard to track
# COVID-19 in real time. Lancet Infect Dis 20(5):533-534.
# Run from the package root to rebuild data/nz_covid_2020.rda.
url <- paste0(
  "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/",
  "csse_covid_19_data/csse_covid_19_time_series/",
  "time_series_covid19_confirmed_global.csv"
)
raw <- utils::read.csv(url, check.names = FALSE)
nz <- raw[raw[["Country/Region"]] == "New Zealand" & raw[["Province/State"]] == "", ]
cumulative <- as.numeric(nz[1, -(1:4)])
dates <- as.Date(names(nz)[-(1:4)], format = "%m/%d/%y")
daily <- pmax(c(cumulative[1], diff(cumulative)), 0)
keep <- dates >= as.Date("2020-02-26") & dates <= as.Date("2020-06-30")
nz_covid_2020 <- tibble::tibble(date = dates[keep], cases = as.integer(daily[keep]))
usethis::use_data(nz_covid_2020, overwrite = TRUE)
